extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const FieldJournalScript = preload("res://journal/field_journal.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_world := load(WORLD_SCENE) as PackedScene
	if packed_world == null:
		_fail("Could not load %s" % WORLD_SCENE)
		return
	var world := packed_world.instantiate()
	root.add_child(world)
	var provider := world.get_node_or_null("HomeWater")
	var player := world.get_node_or_null("PlayerRig") as Node3D
	var spatial := world.get_node_or_null("SpatialCasting")
	var lake := world.get_node_or_null("LakeSurface")
	if provider == null or player == null or spatial == null or lake == null:
		_fail("Field-journal validation requires home water, player, spatial casting, and lake surface")
		return
	if not spatial.has_signal("fishing_evidence_observed") or not spatial.has_method("get_fish_presence_response"):
		_fail("Fishing evidence must cross the spatial provider seam")
		return
	var casting_ui := world.get_node_or_null("CastingUILayer/CastingUI")
	if casting_ui == null or not casting_ui.has_method("get_latest_observation_inspection"):
		_fail("The player needs an inspection affordance for the latest field-journal observation")
		return

	player.global_position = Vector3(0.0, 0.1, -2.0)
	var dock_response := spatial.call("get_fish_presence_response") as Dictionary
	player.global_position = Vector3(7.0, 0.1, -2.0)
	var inlet_response := spatial.call("get_fish_presence_response") as Dictionary
	if float(inlet_response["ambient_interval"]) >= float(dock_response["ambient_interval"]) or float(inlet_response["lure_interval"]) >= float(dock_response["lure_interval"]):
		_fail("Vegetated inlet conditions should produce more frequent visible fish evidence than dock shallows")
		return
	if not String(inlet_response["lure_detail"]).contains("reeds"):
		_fail("Condition-aware lure evidence should name a visible micro-habitat cue")
		return

	var reactions: Array[int] = []
	lake.reaction_requested.connect(func(reaction: LakeSurface.Reaction, _position: Vector3, _strength: float, _radius: float) -> void: reactions.append(reaction))
	var evidence: Array[String] = []
	spatial.fishing_evidence_observed.connect(func(kind: String, detail: String) -> void: evidence.append("%s:%s" % [kind, detail]))
	spatial.call("begin_cast")
	for frame in 24:
		spatial.call("refresh_casting_visuals", 0.08)
		await process_frame
	if not reactions.has(LakeSurface.Reaction.AMBIENT_FISH_SIGN) or not reactions.has(LakeSurface.Reaction.LURE_FISH_SIGN):
		_fail("Condition-aware evidence must request both fish-sign reactions through WaterSurface")
		return
	if not evidence.any(func(entry: String) -> bool: return entry.begins_with("fish sign:")) or not evidence.any(func(entry: String) -> bool: return entry.begins_with("lure-focused sign:")):
		_fail("Visible fish signs must produce field-journal evidence")
		return
	if not (spatial.call("trigger_bite_feedback") as bool) or not reactions.has(LakeSurface.Reaction.BITE_SIGNAL):
		_fail("A bite opportunity must use the distinct WaterSurface bite reaction")
		return
	if not evidence.any(func(entry: String) -> bool: return entry.begins_with("bite:")):
		_fail("A bite must produce field-journal evidence")
		return
	spatial.fishing_evidence_observed.emit("fish sign", "A test shadow passes the reeds.")
	if not String(casting_ui.call("get_latest_observation_inspection")).contains("Hypothesis:"):
		_fail("The casting UI must let the player inspect an observation and form a hypothesis")
		return

	var journal := FieldJournalScript.new()
	var conditions := spatial.call("get_fishing_conditions") as Dictionary
	journal.record("catch", conditions, "Caught Dock Bluegill (0.7 lb).", "This presentation can produce a Dock Bluegill here.")
	journal.record("missed bite", conditions, "The bite signal passed before you set the hook.", "Set the hook promptly when the bite signal appears.")
	journal.record("line break", conditions, "Lost the hooked Dock Bluegill after reeling through a surge.", "Yield sooner during a surge to protect line tension.")
	journal.record("thrown hook", conditions, "Lost the hooked Dock Bluegill after allowing line slack during recovery.", "Reel during recovery to prevent line slack.")
	var rendered := journal.render()
	if not rendered.contains("vegetated inlet") or not rendered.contains("early morning") or not rendered.contains("lure rig"):
		_fail("Observations must retain micro-habitat, time of day, and presentation")
		return
	if not rendered.contains("reeling through a surge") or not rendered.contains("line slack") or not rendered.contains("Set the hook promptly"):
		_fail("Loss observations must retain cause-specific corrective lessons")
		return
	print("Field journal validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

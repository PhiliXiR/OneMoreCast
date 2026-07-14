extends SceneTree

const WORLD_SCENE := preload("res://scenes/world_prototype.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	var hud := world.get_node_or_null("CastingUILayer/CastingUI")
	var spatial := world.get_node_or_null("SpatialCasting")
	var player := world.get_node_or_null("PlayerRig") as Node3D
	if hud == null or spatial == null or player == null:
		_fail("Tackle-range validation requires the fishing HUD, spatial casting, and player rig")
		return
	spatial.set("active_line_range", 14.0)

	var cast_button := hud.get_node("ActionPanel/Layout/CastButton") as Button
	var starting_position := player.global_position
	cast_button.pressed.emit()
	if not await _wait_for_state(hud, "waiting"):
		return
	var observations_before_retrieve := (hud.get("field_journal") as FieldJournal).observations.size()
	player.global_position = starting_position + Vector3(30.0, 0.0, 0.0)
	if not await _wait_for_state(hud, "ready"):
		return
	if spatial.call("is_line_endpoint_visible") as bool or not (spatial.call("is_world_line_disabled") as bool):
		_fail("Leaving range with a landed cast must clear the visible tackle")
		return
	if (hud.get("field_journal") as FieldJournal).observations.size() != observations_before_retrieve:
		_fail("Auto-retrieval must not record a fishing-loss observation")
		return
	if not String(hud.call("get_player_message")).contains("retrieve the tackle"):
		_fail("Auto-retrieval must explain why the tackle was retrieved")
		return

	world.queue_free()
	await process_frame
	world = WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	hud = world.get_node_or_null("CastingUILayer/CastingUI")
	spatial = world.get_node_or_null("SpatialCasting")
	player = world.get_node_or_null("PlayerRig") as Node3D
	if hud == null or spatial == null or player == null:
		_fail("A fresh fishing scene must provide a valid cast for fight-loss validation")
		return
	spatial.set("active_line_range", 14.0)
	cast_button = hud.get_node("ActionPanel/Layout/CastButton") as Button
	starting_position = player.global_position
	if not (spatial.call("can_start_cast") as bool):
		_fail("A fresh fishing scene must provide a valid cast for fight-loss validation")
		return
	hud.call("configure_next_fight", {"recovery_only": true, "recovery_durations": [4.0], "danger_window": 10.0})
	cast_button.pressed.emit()
	if not await _wait_for_state(hud, "bite"):
		return
	var hook_input := InputEventAction.new()
	hook_input.action = &"set_hook"
	hook_input.pressed = true
	root.push_input(hook_input)
	if not await _wait_for_state(hud, "reeling"):
		return
	player.global_position = starting_position + Vector3(30.0, 0.0, 0.0)
	if not await _wait_for_state(hud, "result"):
		return
	var observation := hud.call("get_latest_observation") as Dictionary
	if String(observation.get("kind", "")) != "thrown hook" or not String(observation.get("detail", "")).contains("moving beyond"):
		_fail("Leaving range while fighting must record a movement-caused thrown hook")
		return
	if not String(hud.call("get_player_message")).contains("move too far"):
		_fail("Movement-caused thrown hooks must explain that movement caused the loss")
		return
	print("Tackle-range validation passed")
	quit(0)


func _wait_for_state(hud: Node, expected: String) -> bool:
	for frame in 100:
		await create_timer(0.05).timeout
		var state_label := hud.get_node("ActionPanel/Layout/StateLabel") as Label
		if state_label.text == "State: %s" % expected:
			return true
	var state_label := hud.get_node("ActionPanel/Layout/StateLabel") as Label
	_fail("Fishing loop did not reach %s while validating tackle range (last state: %s)" % [expected, state_label.text])
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

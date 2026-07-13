extends Control

enum CastState { READY, CASTING, WAITING, BITE, REELING, LANDED_FISH, RESULT }
const STATE_NAMES := ["ready", "casting", "waiting", "bite", "reeling", "landed fish", "result"]
const BLUEGILL := {"name": "Dock Bluegill", "weight": 0.7}
const FieldJournalScript = preload("res://journal/field_journal.gd")
const HomeCommunityScript = preload("res://community/home_community.gd")

@export var spatial_casting_provider_path: NodePath
@onready var state_label: Label = $ActionPanel/Layout/StateLabel
@onready var spatial_label: Label = $ActionPanel/Layout/SpatialLabel
@onready var message_label: Label = $ActionPanel/Layout/MessageLabel
@onready var cast_button: Button = $ActionPanel/Layout/CastButton
@onready var result_label: Label = $ActionPanel/Layout/ResultLabel
@onready var quality_label: Label = $ActionPanel/Layout/QualityLabel
@onready var tension_gauge: ProgressBar = $ActionPanel/Layout/TensionGauge
@onready var tension_regions: HBoxContainer = $ActionPanel/Layout/TensionRegions
@onready var tutorial_label: Label = $ActionPanel/Layout/TutorialLabel
@onready var inventory_label: Label = $LogPanel/Layout/InventoryLabel
@onready var journal_label: Label = $LogPanel/Layout/JournalLabel
@onready var inspect_observation_button: Button = $LogPanel/Layout/InspectObservationButton
@onready var presentation_button: Button = $LogPanel/Layout/PresentationButton
@onready var far_bank_button: Button = $LogPanel/Layout/FarBankButton
@onready var community_label: Label = $HomePanel/Layout/CommunityLabel
@onready var return_home_button: Button = $HomePanel/Layout/ReturnHomeButton
@onready var retain_observation_button: Button = $HomePanel/Layout/RetainObservationButton
@onready var help_mara_button: Button = $HomePanel/Layout/HelpMaraButton
@onready var surge_cue: AudioStreamPlayer = $SurgeCue

var state := CastState.READY
var cast_count := 0
var inventory := {}
var field_journal := FieldJournalScript.new()
var home_community := HomeCommunityScript.new()
var spatial_casting_provider: Node
var hook_set := false
var bite_window_open := false
var reel_held := false
var fight_model: FishFightModel
var fight_snapshot := {}
var next_fight_configuration := {}
var _tutorial_hold_shown := false
var _tutorial_release_shown := false
var _tutorial_slack_danger_shown := false
var _tutorial_high_tension_danger_shown := false
var _last_fight_phase := -1
var _observed_evidence_kinds := {}


func _ready() -> void:
	spatial_casting_provider = get_node_or_null(spatial_casting_provider_path)
	if spatial_casting_provider != null and spatial_casting_provider.has_signal("fishing_evidence_observed"):
		spatial_casting_provider.fishing_evidence_observed.connect(_on_fishing_evidence_observed)
	cast_button.pressed.connect(_on_action_pressed)
	inspect_observation_button.pressed.connect(_on_inspect_observation_pressed)
	presentation_button.pressed.connect(_on_presentation_pressed)
	far_bank_button.pressed.connect(_on_far_bank_pressed)
	return_home_button.pressed.connect(_on_return_home_pressed)
	retain_observation_button.pressed.connect(_on_retain_observation_pressed)
	help_mara_button.pressed.connect(_on_help_mara_pressed)
	cast_button.button_down.connect(func() -> void: set_reel_held(true))
	cast_button.button_up.connect(func() -> void: set_reel_held(false))
	var cue_stream := AudioStreamGenerator.new()
	cue_stream.mix_rate = 22050.0
	cue_stream.buffer_length = 0.12
	surge_cue.stream = cue_stream
	_update_view(home_community.begin_first_outing())
	_update_home_community_view()


func _process(delta: float) -> void:
	if state == CastState.REELING and fight_model != null:
		fight_snapshot = fight_model.advance(delta, reel_held)
		_present_fight()
	_update_spatial_view()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"set_hook"):
		if state == CastState.REELING: set_reel_held(true)
		else: _on_action_pressed()
	elif event.is_action_released(&"set_hook") and state == CastState.REELING:
		set_reel_held(false)


func configure_next_fight(configuration: Dictionary) -> void:
	next_fight_configuration = configuration.duplicate(true)


func get_fight_snapshot() -> Dictionary:
	return fight_snapshot.duplicate(true)


func is_surge_cue_playing() -> bool:
	return surge_cue.playing


func set_reel_held(held: bool) -> void:
	if state != CastState.REELING: return
	reel_held = held
	cast_button.modulate = Color(0.65, 0.9, 1.0) if held else Color.WHITE


func _on_action_pressed() -> void:
	if state == CastState.BITE: _try_set_hook()
	elif state == CastState.READY: _start_cast()


func _start_cast() -> void:
	if not _provider_bool("can_start_cast", true):
		_update_view(_provider_string("get_cast_block_reason", "Cannot cast from here."))
		return
	cast_count += 1
	_observed_evidence_kinds.clear()
	cast_button.disabled = true
	await _run_cast_sequence()


func _run_cast_sequence() -> void:
	_provider_call("begin_cast")
	state = CastState.CASTING
	_update_view("You send the lure arcing over the water.")
	await _wait_for_landing()
	if not _provider_bool("did_last_cast_land_in_water", true):
		await _finish_simple_result("missed water", "The lure skips back without fishing.")
		return
	state = CastState.WAITING
	_update_view("The line settles. Watch the water and keep the rod ready.")
	await get_tree().create_timer(_provider_float("get_waiting_for_bite_duration", 0.85)).timeout
	_provider_call("trigger_bite_feedback")
	hook_set = false
	bite_window_open = true
	state = CastState.BITE
	cast_button.disabled = false
	cast_button.text = "Set Hook"
	_update_view("A sharp twitch snaps through the line. Set the hook!")
	await get_tree().create_timer(0.75).timeout
	bite_window_open = false
	if not hook_set:
		await _finish_simple_result("missed bite", "The twitch slips away before you set the hook.")
		return
	_begin_fight()
	while state == CastState.REELING and int(fight_snapshot.get("outcome", 0)) == FishFightModel.Outcome.ONGOING:
		await get_tree().process_frame
	reel_held = false
	if int(fight_snapshot.get("outcome", 0)) == FishFightModel.Outcome.LANDED:
		await _finish_landed_fish()
	else:
		await _finish_fight_loss(int(fight_snapshot.get("outcome", 0)))


func _begin_fight() -> void:
	fight_model = FishFightModel.new()
	var config := next_fight_configuration
	next_fight_configuration = {}
	if config.is_empty():
		config = {
			"recovery_durations": _vary_durations([3.2, 3.0, 3.1, 3.0], 0.2),
			"windup_durations": _vary_durations([1.25, 0.8, 0.75], 0.08),
			"surge_durations": _vary_durations([1.35, 1.45, 1.35], 0.1),
			"surge_count": randi_range(2, 3),
		}
	fight_model.start(config)
	fight_snapshot = fight_model.snapshot()
	_last_fight_phase = -1
	state = CastState.REELING
	cast_button.disabled = false
	cast_button.text = "Hold to Reel"
	tension_gauge.visible = true
	tension_regions.visible = true
	if not _tutorial_hold_shown:
		_tutorial_hold_shown = true
		tutorial_label.text = "Hold to reel while the fish recovers."
	_provider_call("begin_reel_feedback", [999.0])
	_update_view("%s is hooked. Reel during recovery; yield when it surges." % String(_provider_fish()["name"]))


func _vary_durations(base_durations: Array, variation: float) -> Array[float]:
	var durations: Array[float] = []
	for base in base_durations:
		durations.append(float(base) + randf_range(-variation, variation))
	return durations


func _present_fight() -> void:
	tension_gauge.value = float(fight_snapshot.get("tension", 0.0)) * 100.0
	var phase := int(fight_snapshot.get("phase", FishFightModel.Phase.RECOVERY))
	var phase_name := String(fight_snapshot.get("phase_name", "recovery"))
	if phase == FishFightModel.Phase.SURGE_WINDUP and _last_fight_phase != phase:
		_play_surge_cue()
	_last_fight_phase = phase
	message_label.text = "%s — %s" % [phase_name.capitalize(), "reeling" if reel_held else "yielding"]
	if phase == FishFightModel.Phase.SURGE_WINDUP and not _tutorial_release_shown:
		_tutorial_release_shown = true
		tutorial_label.text = "Surge coming — release to yield!"
	var high := float(fight_snapshot.get("high_tension_danger", 0.0))
	var slack := float(fight_snapshot.get("slack_danger", 0.0))
	var high_failure_enabled := bool(fight_snapshot.get("high_tension_failure_enabled", false))
	var slack_failure_enabled := bool(fight_snapshot.get("slack_failure_enabled", false))
	if high_failure_enabled and high > 0.0 and not _tutorial_high_tension_danger_shown:
		_tutorial_high_tension_danger_shown = true
		tutorial_label.text = "Yield now — the line may break!"
	elif slack_failure_enabled and slack > 0.0 and not _tutorial_slack_danger_shown:
		_tutorial_slack_danger_shown = true
		tutorial_label.text = "Reel now — the fish may throw the hook!"
	var pulse := 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.012))
	tension_regions.get_node("Slack").modulate = Color(pulse, pulse, 1.0) if slack_failure_enabled and slack > 0.0 else Color.WHITE
	tension_regions.get_node("Excessive").modulate = Color(1.0, pulse, pulse) if high_failure_enabled and high > 0.0 else Color.WHITE
	_provider_call("apply_fight_snapshot", [fight_snapshot, reel_held])


func _finish_landed_fish() -> void:
	state = CastState.LANDED_FISH
	cast_button.disabled = true
	_hide_fight_hud()
	_provider_call("present_landed_fish")
	var fish := _provider_fish()
	var name: String = fish["name"]
	var weight: float = fish["weight"]
	_update_view("%s breaks the surface — landed!" % name)
	await get_tree().create_timer(0.8).timeout
	inventory[name] = inventory.get(name, 0) + 1
	record_observation("catch", "Caught %s (%.1f lb)." % [name, weight], "This presentation can produce %s here." % name)
	result_label.text = "Latest result: %s, %.1f lb" % [name, weight]
	quality_label.text = _context()
	state = CastState.RESULT
	_update_view("You record %s as a catch." % name)
	await _return_ready()


func _finish_fight_loss(outcome: int) -> void:
	state = CastState.RESULT
	_hide_fight_hud()
	var broke := outcome == FishFightModel.Outcome.LINE_BREAK
	var cause := "line break" if broke else "thrown hook"
	record_observation(cause, "Lost the hooked Dock Bluegill after %s." % ("reeling through a surge" if broke else "allowing line slack during recovery"), "Yield sooner during a surge to protect line tension." if broke else "Reel during recovery to prevent line slack.")
	result_label.text = "Latest result: %s" % cause
	quality_label.text = _context()
	_update_view(("The line breaks. Yield sooner during a surge." if broke else "The fish throws the hook. Reel during recovery."))
	_provider_call("end_fight_presentation")
	await _return_ready(0.7)


func _finish_simple_result(label: String, message: String) -> void:
	state = CastState.RESULT
	var detail := "The bite signal passed before you set the hook." if label == "missed bite" else message
	var lesson := "Set the hook promptly when the bite signal appears." if label == "missed bite" else "Aim the lure into fishable water."
	record_observation(label, detail, lesson)
	result_label.text = "Latest result: %s" % label
	quality_label.text = _context()
	_update_view(message)
	await _return_ready()


func _return_ready(delay := 0.9) -> void:
	await get_tree().create_timer(delay).timeout
	state = CastState.READY
	cast_button.disabled = false
	cast_button.text = "Cast"
	cast_button.modulate = Color.WHITE
	tutorial_label.text = ""
	_update_view("Ready for another cast.")


func _try_set_hook() -> void:
	if state == CastState.BITE and bite_window_open:
		hook_set = true
		bite_window_open = false
		cast_button.disabled = true
		_update_view("You snap the rod back and set the hook.")
	elif state == CastState.WAITING: _update_view("Too early. Wait for a bite before setting the hook.")


func _hide_fight_hud() -> void:
	tension_gauge.visible = false
	tension_regions.visible = false


func _play_surge_cue() -> void:
	surge_cue.play()
	var playback := surge_cue.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null: return
	var frames := PackedVector2Array()
	for index in 1764:
		var envelope := 1.0 - float(index) / 1764.0
		var sample := sin(float(index) * TAU * 660.0 / 22050.0) * envelope * 0.22
		frames.append(Vector2(sample, sample))
	playback.push_buffer(frames)


func _on_fishing_evidence_observed(kind: String, detail: String) -> void:
	if _observed_evidence_kinds.has(kind):
		return
	_observed_evidence_kinds[kind] = true
	record_observation(kind, detail)
	_update_view(message_label.text)


func _on_inspect_observation_pressed() -> void:
	var inspection := field_journal.inspect_latest()
	var note := _provider_string_with_args("inspect_lure_evidence", [field_journal.latest()], "")
	_update_view("%s\n%s" % [inspection, note] if not note.is_empty() else inspection)


func _on_presentation_pressed() -> void:
	_update_view(_provider_string("cycle_presentation", "Only the lure rig is available."))


func _on_far_bank_pressed() -> void:
	_update_view(_provider_string("travel_to_far_bank", "The far bank is not reachable here."))


func _on_return_home_pressed() -> void:
	_update_view(return_home_with_latest_observation(HomeCommunityScript.Disposition.SHARE))


func _on_retain_observation_pressed() -> void:
	_update_view(return_home_with_latest_observation(HomeCommunityScript.Disposition.RETAIN))


func _on_help_mara_pressed() -> void:
	_update_view(return_home_with_latest_observation(HomeCommunityScript.Disposition.HELP))


func return_home_with_latest_observation(disposition := HomeCommunityScript.Disposition.SHARE) -> String:
	var observation := field_journal.latest()
	if observation.is_empty():
		return "Return home after recording an observation; the community needs something specific to respond to."
	var return_beat := home_community.return_from_outing(observation, String(_provider_conditions()["time_of_day"]), disposition)
	var next_time := String(return_beat["next_time_of_day"])
	_provider_call("advance_home_context", [next_time])
	var clues := return_beat["watershed_mystery_clues"] as Array
	var message := "Home — %s\n%s\n%s\n%s\n%s" % [
		String(return_beat["local_need_response"]),
		String(return_beat["fieldcraft_response"]),
		String(return_beat["local_story_response"]),
		String(clues[0]),
		String(clues[1]),
	]
	_update_home_community_view()
	return message


func _update_home_community_view() -> void:
	var interaction_lines: Array[String] = ["Home community:"]
	for interaction in home_community.get_recurring_interactions():
		interaction_lines.append("- %s (%s): %s" % [
			String(interaction["name"]),
			String(interaction["role"]),
			String(interaction["summary"]),
		])
	interaction_lines.append(home_community.get_relationship_summary())
	community_label.text = "\n".join(interaction_lines)
	var latest_observation := field_journal.latest()
	var can_help_mara := home_community.get_available_dispositions(latest_observation).has(HomeCommunityScript.Disposition.HELP)
	help_mara_button.disabled = not can_help_mara


func record_observation(kind: String, detail: String, lesson := "") -> void:
	field_journal.record(kind, _provider_conditions(), detail, lesson)
	_update_home_community_view()


func _update_view(message: String) -> void:
	state_label.text = "State: %s" % STATE_NAMES[state]
	message_label.text = message
	inventory_label.text = _inventory_text()
	journal_label.text = _journal_text()
	_update_spatial_view()


func _inventory_text() -> String:
	if inventory.is_empty(): return "Inventory: empty"
	var lines: Array[String] = []
	for fish_name in inventory: lines.append("%s x%d" % [fish_name, inventory[fish_name]])
	return "Inventory: %s" % ", ".join(lines)


func _journal_text() -> String:
	return field_journal.render()


func get_latest_observation_inspection() -> String:
	return field_journal.inspect_latest()


func get_latest_observation() -> Dictionary:
	return field_journal.latest()


func get_available_return_dispositions() -> Array[int]:
	return home_community.get_available_dispositions(field_journal.latest())


func get_player_message() -> String:
	return message_label.text


func _context() -> String: return _provider_string("get_result_context", "Landing quality: baseline")
func _provider_fish() -> Dictionary: return spatial_casting_provider.call("get_hooked_fish") as Dictionary if spatial_casting_provider != null and spatial_casting_provider.has_method("get_hooked_fish") else BLUEGILL.duplicate(true)
func _provider_conditions() -> Dictionary: return spatial_casting_provider.call("get_fishing_conditions") as Dictionary if spatial_casting_provider != null and spatial_casting_provider.has_method("get_fishing_conditions") else {"micro_habitat": "prototype water", "time_of_day": "day", "presentation": "lure rig"}
func _update_spatial_view() -> void: spatial_label.text = _provider_string("get_spatial_feedback", "Spatial: standalone cast mode")
func _provider_bool(method: String, fallback: bool) -> bool: return spatial_casting_provider.call(method) as bool if spatial_casting_provider != null and spatial_casting_provider.has_method(method) else fallback
func _provider_float(method: String, fallback: float) -> float: return spatial_casting_provider.call(method) as float if spatial_casting_provider != null and spatial_casting_provider.has_method(method) else fallback
func _provider_string(method: String, fallback: String) -> String: return spatial_casting_provider.call(method) as String if spatial_casting_provider != null and spatial_casting_provider.has_method(method) else fallback
func _provider_string_with_args(method: String, args: Array, fallback: String) -> String: return spatial_casting_provider.callv(method, args) as String if spatial_casting_provider != null and spatial_casting_provider.has_method(method) else fallback
func _provider_call(method: String, args := []) -> void:
	if spatial_casting_provider != null and spatial_casting_provider.has_method(method): spatial_casting_provider.callv(method, args)
func _wait_for_landing() -> void:
	if spatial_casting_provider == null:
		await get_tree().create_timer(0.45).timeout
		return
	var elapsed := 0.0
	while elapsed < 1.8:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
		if _provider_bool("is_cast_landed", true) and not _provider_bool("is_landing_feedback_visible", false): return

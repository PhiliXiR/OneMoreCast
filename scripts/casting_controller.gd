extends Control

enum CastState {
	READY,
	CASTING,
	WAITING,
	BITE,
	REELING,
	RESULT,
}

const STATE_NAMES := {
	CastState.READY: "ready",
	CastState.CASTING: "casting",
	CastState.WAITING: "waiting",
	CastState.BITE: "bite",
	CastState.REELING: "reeling",
	CastState.RESULT: "result",
}

const FISH_TABLE := [
	{"name": "Dock Bluegill", "weight": 0.7},
	{"name": "Copper Minnow", "weight": 0.5},
	{"name": "Old Boot Bass", "weight": 1.9},
]

@export var spatial_casting_provider_path: NodePath

@onready var state_label: Label = $ActionPanel/Layout/StateLabel
@onready var spatial_label: Label = $ActionPanel/Layout/SpatialLabel
@onready var message_label: Label = $ActionPanel/Layout/MessageLabel
@onready var cast_button: Button = $ActionPanel/Layout/CastButton
@onready var result_label: Label = $ActionPanel/Layout/ResultLabel
@onready var quality_label: Label = $ActionPanel/Layout/QualityLabel
@onready var inventory_label: Label = $LogPanel/Layout/InventoryLabel
@onready var journal_label: Label = $LogPanel/Layout/JournalLabel

var state := CastState.READY
var cast_count := 0
var inventory := {}
var journal: Array[String] = []
var rng := RandomNumberGenerator.new()
var spatial_casting_provider: Node
var hook_set := false
var bite_window_open := false


func _ready() -> void:
	rng.randomize()
	spatial_casting_provider = get_node_or_null(spatial_casting_provider_path)
	cast_button.pressed.connect(_on_action_pressed)
	_update_view("The water is quiet. Make the first cast.")


func _process(_delta: float) -> void:
	_update_spatial_view()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if cast_button.get_global_rect().has_point(mouse_event.position):
				get_viewport().set_input_as_handled()
				_on_action_pressed()
	if event.is_action_pressed(&"set_hook"):
		_try_set_hook()


func _on_action_pressed() -> void:
	if state == CastState.BITE:
		_try_set_hook()
		return

	if state != CastState.READY:
		return
	await _start_cast()


func _start_cast() -> void:
	if not _can_start_spatial_cast():
		_update_view(_get_spatial_block_reason())
		return

	cast_count += 1
	cast_button.disabled = true
	cast_button.text = "Cast"
	await _run_cast_sequence()
	cast_button.disabled = false
	cast_button.text = "Cast"


func _run_cast_sequence() -> void:
	_begin_spatial_cast()
	state = CastState.CASTING
	_update_view("You send the lure arcing over the water.")
	await _wait_for_spatial_landing_feedback()

	if not _did_last_cast_land_in_water():
		state = CastState.RESULT
		var failed_message := "Cast %d: missed the water (%s)." % [cast_count, _get_result_context()]
		_record_journal(failed_message)
		result_label.text = "Latest result: missed water"
		quality_label.text = _get_result_context()
		_update_view("The lure skips back without fishing. %s." % _get_result_context())
		await get_tree().create_timer(0.9).timeout
		state = CastState.READY
		_update_view("Ready for another cast.")
		return

	var wait_duration := _get_waiting_for_bite_duration()
	await _advance(
		CastState.WAITING,
		"The line settles. Watch the water and keep the rod ready.",
		wait_duration
	)
	_trigger_bite_feedback()
	hook_set = false
	bite_window_open = true
	state = CastState.BITE
	cast_button.disabled = false
	cast_button.text = "Set Hook"
	_update_view("A sharp twitch snaps through the line. Set the hook!")
	await get_tree().create_timer(0.75).timeout
	bite_window_open = false
	cast_button.disabled = true
	cast_button.text = "Cast"

	state = CastState.RESULT
	var result_message := _resolve_hook_outcome()
	_update_view(result_message)

	await get_tree().create_timer(0.9).timeout
	state = CastState.READY
	_update_view("Ready for another cast.")


func _advance(next_state: CastState, message: String, duration: float) -> void:
	state = next_state
	_update_view(message)
	await get_tree().create_timer(duration).timeout


func _resolve_cast() -> String:
	var landing_quality := _get_landing_quality()
	var catch_chance := lerpf(0.25, 0.85, landing_quality)
	var caught_fish := rng.randf() < catch_chance
	if not caught_fish:
		var empty_message := "Cast %d: empty water (%s)." % [cast_count, _get_result_context()]
		_record_journal(empty_message)
		result_label.text = "Latest result: nothing hooked"
		quality_label.text = _get_result_context()
		return "The lure comes back clean. %s." % _get_result_context()

	var fish: Dictionary = FISH_TABLE[rng.randi_range(0, FISH_TABLE.size() - 1)]
	var fish_name: String = fish["name"]
	var fish_weight: float = fish["weight"]

	inventory[fish_name] = inventory.get(fish_name, 0) + 1
	var journal_entry := "Cast %d: caught %s (%.1f lb, %s)." % [
		cast_count,
		fish_name,
		fish_weight,
		_get_result_context(),
	]
	_record_journal(journal_entry)
	result_label.text = "Latest result: %s, %.1f lb" % [fish_name, fish_weight]
	quality_label.text = _get_result_context()
	return "You land a %s. %s." % [fish_name, _get_result_context()]


func _resolve_waiting_cast() -> String:
	var entry := "Cast %d: waited for a bite (%s)." % [cast_count, _get_result_context()]
	_record_journal(entry)
	result_label.text = "Latest result: waiting water"
	quality_label.text = _get_result_context()
	return "The lure rests in the water. No bite yet, but this is fishable water. %s." % _get_result_context()


func _resolve_bite_signal_cast() -> String:
	var entry := "Cast %d: bite signaled (%s)." % [cast_count, _get_result_context()]
	_record_journal(entry)
	result_label.text = "Latest result: bite signaled"
	quality_label.text = _get_result_context()
	return "Something tapped the lure. Next step: set the hook. %s." % _get_result_context()


func _resolve_hook_outcome() -> String:
	if hook_set:
		var fish: Dictionary = FISH_TABLE[0]
		var fish_name: String = fish["name"]
		var fish_weight: float = fish["weight"]
		inventory[fish_name] = inventory.get(fish_name, 0) + 1
		var entry := "Cast %d: caught %s (%.1f lb, %s)." % [
			cast_count,
			fish_name,
			fish_weight,
			_get_result_context(),
		]
		_record_journal(entry)
		result_label.text = "Latest result: %s, %.1f lb" % [fish_name, fish_weight]
		quality_label.text = _get_result_context()
		return "Hook set. You bring in a %s. %s." % [fish_name, _get_result_context()]

	var miss_entry := "Cast %d: missed the hook set (%s)." % [cast_count, _get_result_context()]
	_record_journal(miss_entry)
	result_label.text = "Latest result: missed bite"
	quality_label.text = _get_result_context()
	return "The twitch slips away before you set the hook. %s." % _get_result_context()


func _try_set_hook() -> void:
	if state == CastState.BITE and bite_window_open:
		hook_set = true
		bite_window_open = false
		cast_button.disabled = true
		cast_button.text = "Cast"
		_update_view("You snap the rod back and set the hook.")
		return

	if state == CastState.WAITING:
		_update_view("Too early. Wait for a bite before setting the hook.")


func _record_journal(entry: String) -> void:
	journal.push_front(entry)
	if journal.size() > 5:
		journal.resize(5)


func _update_view(message: String) -> void:
	state_label.text = "State: %s" % STATE_NAMES[state]
	message_label.text = message
	_update_spatial_view()
	inventory_label.text = _format_inventory()
	journal_label.text = _format_journal()


func _can_start_spatial_cast() -> bool:
	if spatial_casting_provider == null:
		return true
	if not spatial_casting_provider.has_method("can_start_cast"):
		return true
	return spatial_casting_provider.call("can_start_cast") as bool


func _get_spatial_block_reason() -> String:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("get_cast_block_reason"):
		return spatial_casting_provider.call("get_cast_block_reason") as String
	return "Cannot cast from here."


func _begin_spatial_cast() -> void:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("begin_cast"):
		spatial_casting_provider.call("begin_cast")


func _wait_for_spatial_landing_feedback() -> void:
	if spatial_casting_provider == null:
		await get_tree().create_timer(0.45).timeout
		return

	var timeout := 1.8
	var elapsed := 0.0
	var tick := 0.05
	while elapsed < timeout:
		await get_tree().create_timer(tick).timeout
		elapsed += tick
		if _is_spatial_cast_landed() and not _is_landing_feedback_visible():
			return


func _get_landing_quality() -> float:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("get_landing_quality"):
		return spatial_casting_provider.call("get_landing_quality") as float
	return 0.65


func _did_last_cast_land_in_water() -> bool:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("did_last_cast_land_in_water"):
		return spatial_casting_provider.call("did_last_cast_land_in_water") as bool
	return _get_landing_quality() > 0.0


func _is_spatial_cast_landed() -> bool:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("is_cast_landed"):
		return spatial_casting_provider.call("is_cast_landed") as bool
	return true


func _is_landing_feedback_visible() -> bool:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("is_landing_feedback_visible"):
		return spatial_casting_provider.call("is_landing_feedback_visible") as bool
	return false


func _get_waiting_for_bite_duration() -> float:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("get_waiting_for_bite_duration"):
		return spatial_casting_provider.call("get_waiting_for_bite_duration") as float
	return 0.85


func _trigger_bite_feedback() -> void:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("trigger_bite_feedback"):
		spatial_casting_provider.call("trigger_bite_feedback")


func _get_result_context() -> String:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("get_result_context"):
		return spatial_casting_provider.call("get_result_context") as String
	return "Landing quality: baseline"


func _update_spatial_view() -> void:
	if spatial_casting_provider != null and spatial_casting_provider.has_method("get_spatial_feedback"):
		spatial_label.text = spatial_casting_provider.call("get_spatial_feedback") as String
	else:
		spatial_label.text = "Spatial: standalone cast mode"


func _format_inventory() -> String:
	if inventory.is_empty():
		return "Inventory: empty"

	var fish_lines: Array[String] = []
	for fish_name in inventory.keys():
		fish_lines.append("%s x%d" % [fish_name, inventory[fish_name]])

	return "Inventory: %s" % ", ".join(fish_lines)


func _format_journal() -> String:
	if journal.is_empty():
		return "Journal:\n- No casts yet."

	var lines: Array[String] = ["Journal:"]
	for entry in journal:
		lines.append("- %s" % entry)

	return "\n".join(lines)

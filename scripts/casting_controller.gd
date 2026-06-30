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

@onready var state_label: Label = $ActionPanel/Layout/StateLabel
@onready var message_label: Label = $ActionPanel/Layout/MessageLabel
@onready var cast_button: Button = $ActionPanel/Layout/CastButton
@onready var result_label: Label = $ActionPanel/Layout/ResultLabel
@onready var inventory_label: Label = $LogPanel/Layout/InventoryLabel
@onready var journal_label: Label = $LogPanel/Layout/JournalLabel

var state := CastState.READY
var cast_count := 0
var inventory := {}
var journal: Array[String] = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	cast_button.pressed.connect(_on_cast_pressed)
	_update_view("The water is quiet. Make the first cast.")


func _on_cast_pressed() -> void:
	if state != CastState.READY:
		return

	cast_count += 1
	cast_button.disabled = true
	await _run_cast_sequence()
	cast_button.disabled = false


func _run_cast_sequence() -> void:
	await _advance(CastState.CASTING, "You send the lure arcing over the water.", 0.45)
	await _advance(CastState.WAITING, "The line settles. Something might be watching.", 0.75)
	await _advance(CastState.BITE, "A sharp tug snaps through the rod.", 0.45)
	await _advance(CastState.REELING, "You reel against the pull.", 0.65)

	state = CastState.RESULT
	var result_message := _resolve_cast()
	_update_view(result_message)

	await get_tree().create_timer(0.9).timeout
	state = CastState.READY
	_update_view("Ready for another cast.")


func _advance(next_state: CastState, message: String, duration: float) -> void:
	state = next_state
	_update_view(message)
	await get_tree().create_timer(duration).timeout


func _resolve_cast() -> String:
	var caught_fish := rng.randf() < 0.65
	if not caught_fish:
		var empty_message := "Cast %d: empty water." % cast_count
		_record_journal(empty_message)
		result_label.text = "Latest result: nothing hooked"
		return "The lure comes back clean. Nothing this time."

	var fish: Dictionary = FISH_TABLE[rng.randi_range(0, FISH_TABLE.size() - 1)]
	var fish_name: String = fish["name"]
	var fish_weight: float = fish["weight"]

	inventory[fish_name] = inventory.get(fish_name, 0) + 1
	var journal_entry := "Cast %d: caught %s (%.1f lb)." % [cast_count, fish_name, fish_weight]
	_record_journal(journal_entry)
	result_label.text = "Latest result: %s, %.1f lb" % [fish_name, fish_weight]
	return "You land a %s. The bucket gets a little livelier." % fish_name


func _record_journal(entry: String) -> void:
	journal.push_front(entry)
	if journal.size() > 5:
		journal.resize(5)


func _update_view(message: String) -> void:
	state_label.text = "State: %s" % STATE_NAMES[state]
	message_label.text = message
	inventory_label.text = _format_inventory()
	journal_label.text = _format_journal()


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

class_name HomeCottageFlow
extends Node3D

## Owns the Home Cottage boundary: whether the player can leave fishing, the
## short transition, and the two placement points. Fishing and the reusable
## movement/camera systems remain external seams.

@export var player_path: NodePath
@export var camera_path: NodePath
@export var casting_ui_path: NodePath
@export var interaction_radius := 2.15
@export var reduced_motion := false

const REDUCED_MOTION_SETTING := "accessibility/reduce_motion"
const PORCH_POSITION := Vector3(3.25, 0.12, -5.15)
const INTERIOR_ORIGIN := Vector3(28.0, 0.0, -200.0)
const INTERIOR_ENTRY := INTERIOR_ORIGIN + Vector3(0.0, 0.12, 1.9)
const INTERIOR_EXIT := INTERIOR_ORIGIN + Vector3(0.0, 0.12, -2.45)

var player: CharacterBody3D
var camera: Node
var casting_ui: Node
var _inside := false
var _transitioning := false
var _outside_camera_distance := 6.0
var _prompt: Label
var _feedback: Label


func _ready() -> void:
	add_to_group(&"home_cottage_flow")
	reduced_motion = reduced_motion or bool(ProjectSettings.get_setting(REDUCED_MOTION_SETTING, false))
	player = get_node_or_null(player_path) as CharacterBody3D
	camera = get_node_or_null(camera_path)
	casting_ui = get_node_or_null(casting_ui_path)
	_load_interior()
	_build_hud()


func _process(_delta: float) -> void:
	if _inside and player != null and player.global_position.y < INTERIOR_ORIGIN.y + 0.12:
		# The temporary room lives beyond the sloped exterior collision. Keep its
		# floor level explicit until the interior receives its authored terrain.
		player.global_position.y = INTERIOR_ORIGIN.y + 0.12
		player.velocity.y = 0.0
	_update_prompt()


func try_handle_interact() -> bool:
	if _transitioning:
		return true
	if _inside:
		if _is_near(INTERIOR_EXIT):
			_return_to_porch()
			return true
		return false
	if not is_near_home_cottage():
		return false
	if not _is_fishing_settled():
		return false
	_enter_interior()
	return true


func is_inside_home_cottage() -> bool:
	return _inside


func get_porch_position() -> Vector3:
	return PORCH_POSITION


func is_near_home_cottage() -> bool:
	return not _inside and _is_near(PORCH_POSITION)


func show_entry_blocked_feedback() -> void:
	_show_feedback("Settle the line before entering the Home Cottage.")


func _is_fishing_settled() -> bool:
	return casting_ui != null and casting_ui.has_method("is_settled_for_home_cottage") and casting_ui.call("is_settled_for_home_cottage")


func _is_near(position: Vector3) -> bool:
	return player != null and player.global_position.distance_to(position) <= interaction_radius


func _enter_interior() -> void:
	_transitioning = true
	_show_feedback("Stepping inside…")
	await _brief_transition()
	_place_player(INTERIOR_ENTRY)
	_inside = true
	_set_camera_distance(3.4)
	_transitioning = false
	_show_feedback("Home Cottage interior. Walk to the door and press E to return to the porch.")


func _return_to_porch() -> void:
	_transitioning = true
	_show_feedback("Returning to the porch…")
	await _brief_transition()
	_place_player(PORCH_POSITION)
	_inside = false
	_set_camera_distance(_outside_camera_distance)
	_transitioning = false
	_show_feedback("Back on the porch. Your outing remains recorded.")


func _brief_transition() -> void:
	if not reduced_motion:
		await get_tree().create_timer(0.22).timeout


func _place_player(position: Vector3) -> void:
	if player == null:
		return
	player.global_position = position
	player.velocity = Vector3.ZERO


func _set_camera_distance(distance: float) -> void:
	if camera == null or not camera.has_method("set_preferred_distance"):
		return
	if not _inside:
		_outside_camera_distance = float(camera.call("get_preferred_distance"))
	camera.call("set_preferred_distance", distance)
	camera.call("force_update")


func _update_prompt() -> void:
	if _prompt == null:
		return
	if _transitioning:
		_prompt.visible = false
	elif _inside and _is_near(INTERIOR_EXIT):
		_prompt.text = "E  Return to porch"
		_prompt.visible = true
	elif not _inside and _is_near(PORCH_POSITION):
		_prompt.text = "E  Enter Home Cottage" if _is_fishing_settled() else "E  Home Cottage — settle the line first"
		_prompt.visible = true
	else:
		_prompt.visible = false


func _show_feedback(text: String) -> void:
	if _feedback == null:
		return
	_feedback.text = text
	_feedback.visible = true
	if not _transitioning:
		await get_tree().create_timer(2.5).timeout
		if not _transitioning:
			_feedback.visible = false


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HomeCottageUILayer"
	add_child(layer)
	_prompt = Label.new()
	_prompt.name = "HomeCottagePrompt"
	_prompt.position = Vector2(24, 180)
	_prompt.add_theme_font_size_override("font_size", 19)
	_prompt.add_theme_color_override("font_color", Color("#f4e7c8"))
	layer.add_child(_prompt)
	_feedback = Label.new()
	_feedback.name = "HomeCottageFeedback"
	_feedback.position = Vector2(24, 210)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.size = Vector2(390, 52)
	_feedback.add_theme_font_size_override("font_size", 16)
	_feedback.add_theme_color_override("font_color", Color("#e3c27c"))
	layer.add_child(_feedback)


func _load_interior() -> void:
	var packed_interior := load("res://scenes/home_cottage_interior.tscn") as PackedScene
	if packed_interior == null:
		push_error("Home Cottage interior scene could not load")
		return
	var room := packed_interior.instantiate() as Node3D
	room.position = INTERIOR_ORIGIN
	add_child(room)

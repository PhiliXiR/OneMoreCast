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
const PORCH_FALLBACK_POSITION := Vector3(5.9, 0.12, -1.95)
const INTERIOR_ORIGIN := Vector3(28.0, 0.0, -200.0)
const INTERIOR_ENTRY := INTERIOR_ORIGIN + Vector3(0.0, 0.12, 1.65)
const INTERIOR_EXIT := INTERIOR_ORIGIN + Vector3(0.0, 0.12, 2.75)
const HOME_COTTAGE_INTERIOR := preload("res://assets/props/home_cottage/home_cottage_interior_roofless.glb")

var player: CharacterBody3D
var camera: Node
var casting_ui: Node
var _inside := false
var _transitioning := false
var _outside_camera_distance := 6.0
var _outside_camera_yaw := 180.0
var _prompt: Label
var _feedback: Label
var _interior: Node3D


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
	_update_interior_lighting()
	_update_prompt()


func try_handle_interact() -> bool:
	if _transitioning:
		return true
	if _inside:
		if _is_near(INTERIOR_EXIT):
			_return_to_porch()
			return true
		if _is_near_interior_node("WritingDesk"):
			_open_field_journal()
			return true
		if _is_near_interior_node("MaraVale"):
			_open_mara_return_presentation()
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
	var exterior := get_tree().get_first_node_in_group(&"home_cottage_exterior") as Node3D
	var marker := exterior.get_node_or_null("EntryMarker") as Marker3D if exterior != null else null
	return marker.global_position if marker != null else PORCH_FALLBACK_POSITION


func is_near_home_cottage() -> bool:
	return not _inside and _is_near(get_porch_position())


func show_entry_blocked_feedback() -> void:
	_show_feedback("Settle the line before entering the Home Cottage.")


func _is_fishing_settled() -> bool:
	return casting_ui != null and casting_ui.has_method("is_settled_for_home_cottage") and casting_ui.call("is_settled_for_home_cottage")


func _is_near(position: Vector3) -> bool:
	return player != null and player.global_position.distance_to(position) <= interaction_radius


func _is_near_interior_node(node_name: String) -> bool:
	var target := _interior.get_node_or_null(NodePath(node_name)) as Node3D if _interior != null else null
	return target != null and _is_near(target.global_position)


func get_interior_interaction_position(node_name: String) -> Vector3:
	var target := _interior.get_node_or_null(NodePath(node_name)) as Node3D if _interior != null else null
	return target.global_position if target != null else Vector3.INF


func _enter_interior() -> void:
	_transitioning = true
	_show_feedback("Stepping inside…")
	await _brief_transition()
	_place_player(INTERIOR_ENTRY)
	_inside = true
	_set_camera_distance(3.4)
	_set_camera_yaw(0.0)
	_transitioning = false
	_show_feedback("Home Cottage interior. Walk to the door and press E to return to the porch.")


func _return_to_porch() -> void:
	_transitioning = true
	_show_feedback("Returning to the porch…")
	await _brief_transition()
	_place_player(get_porch_position())
	_inside = false
	_set_camera_distance(_outside_camera_distance)
	_set_camera_yaw(_outside_camera_yaw)
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


func _set_camera_yaw(yaw_degrees: float) -> void:
	if camera == null or not camera.has_method("get_yaw_degrees") or not camera.has_method("orbit"):
		return
	if not _inside:
		_outside_camera_yaw = float(camera.call("get_yaw_degrees"))
	var current_yaw := float(camera.call("get_yaw_degrees"))
	camera.call("orbit", wrapf(yaw_degrees - current_yaw, -180.0, 180.0), 0.0)
	camera.call("force_update")


func _update_prompt() -> void:
	if _prompt == null:
		return
	if _transitioning:
		_prompt.visible = false
	elif _inside and _is_near(INTERIOR_EXIT):
		_prompt.text = "E  Return to porch"
		_prompt.visible = true
	elif _inside and _is_near_interior_node("WritingDesk"):
		_prompt.text = "E  Read Field journal at writing desk"
		_prompt.visible = true
	elif _inside and _is_near_interior_node("MaraVale"):
		_prompt.text = "E  Speak with Mara Vale"
		_prompt.visible = true
	elif not _inside and _is_near(get_porch_position()):
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


func _open_field_journal() -> void:
	if casting_ui != null and casting_ui.has_method("open_field_journal_at_home_cottage"):
		casting_ui.call("open_field_journal_at_home_cottage")
		_show_feedback("The writing desk opens your Field journal.")


func _open_mara_return_presentation() -> void:
	if casting_ui != null and casting_ui.has_method("open_home_community_return_presentation"):
		casting_ui.call("open_home_community_return_presentation")
		_show_feedback("Mara listens. Choose how to share the latest observation.")


func _update_interior_lighting() -> void:
	if _interior == null or casting_ui == null or not casting_ui.has_method("get_current_fishing_conditions"):
		return
	var conditions := casting_ui.call("get_current_fishing_conditions") as Dictionary
	var late_afternoon := String(conditions.get("time_of_day", "early morning")) == "late afternoon"
	var practical_light := _interior.get_node_or_null("WarmPracticalLight") as OmniLight3D
	if practical_light != null:
		practical_light.light_energy = 1.45 if late_afternoon else 2.05
	var window := _interior.get_node_or_null("WarmWindow") as MeshInstance3D
	if window != null and window.material_override is StandardMaterial3D:
		var material := window.material_override as StandardMaterial3D
		material.albedo_color = Color("#d99a62") if late_afternoon else Color("#9fc6da")
		material.emission = material.albedo_color


func _load_interior() -> void:
	if HOME_COTTAGE_INTERIOR == null:
		push_error("Home Cottage interior scene could not load")
		return
	_interior = HOME_COTTAGE_INTERIOR.instantiate() as Node3D
	if _interior == null:
		push_error("Approved Home Cottage interior could not instantiate")
		return
	_interior.name = "HomeCottageInterior"
	_interior.set_meta("approved_asset", true)
	_interior.position = INTERIOR_ORIGIN
	add_child(_interior)
	_add_interior_marker("WritingDesk", Vector3(-1.55, 0.12, 0.45))
	_add_interior_marker("MaraVale", Vector3(0.95, 0.12, -0.55))
	_add_mara_figure()
	_add_interior_collision()
	_add_interior_practical_light()


func _add_interior_marker(node_name: String, position: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = node_name
	marker.position = position
	_interior.add_child(marker)


func _add_mara_figure() -> void:
	var mara := _interior.get_node_or_null("MaraVale") as Node3D
	if mara == null:
		return
	var coat := StandardMaterial3D.new()
	coat.albedo_color = Color("#334b35")
	coat.roughness = 0.85
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.3
	body_mesh.bottom_radius = 0.38
	body_mesh.height = 1.18
	var body := MeshInstance3D.new()
	body.name = "MaraCoat"
	body.position = Vector3(0.0, 0.84, 0.0)
	body.mesh = body_mesh
	body.material_override = coat
	mara.add_child(body)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#6d3d28")
	skin.roughness = 0.78
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	var head := MeshInstance3D.new()
	head.name = "MaraHead"
	head.position = Vector3(0.0, 1.7, 0.0)
	head.mesh = head_mesh
	head.material_override = skin
	mara.add_child(head)


func _add_interior_collision() -> void:
	_add_box_collision("FloorCollision", Vector3(0.0, -0.08, 0.0), Vector3(6.0, 0.16, 5.0))
	_add_box_collision("WestWallCollision", Vector3(-3.0, 1.45, 0.0), Vector3(0.16, 2.9, 5.0))
	_add_box_collision("EastWallCollision", Vector3(3.0, 1.45, 0.0), Vector3(0.16, 2.9, 5.0))
	_add_box_collision("BackWallCollision", Vector3(0.0, 1.45, -2.5), Vector3(6.0, 2.9, 0.16))
	_add_box_collision("DoorWallWestCollision", Vector3(-2.0, 1.45, 2.5), Vector3(2.0, 2.9, 0.16))
	_add_box_collision("DoorWallEastCollision", Vector3(2.0, 1.45, 2.5), Vector3(2.0, 2.9, 0.16))


func _add_box_collision(node_name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = position
	body.add_child(shape)
	_interior.add_child(body)


func _add_interior_practical_light() -> void:
	var light := OmniLight3D.new()
	light.name = "WarmPracticalLight"
	light.position = Vector3(-0.25, 2.45, 0.2)
	light.light_color = Color(1, 0.68, 0.38, 1)
	light.light_energy = 2.05
	light.omni_range = 7.5
	light.shadow_enabled = true
	_interior.add_child(light)

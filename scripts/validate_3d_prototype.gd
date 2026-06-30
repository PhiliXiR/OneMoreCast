extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const INPUT_ACTIONS := [
	&"move_forward",
	&"move_backward",
	&"move_left",
	&"move_right",
]


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load(WORLD_SCENE) as PackedScene
	if packed_scene == null:
		_fail("Could not load %s" % WORLD_SCENE)
		return

	var world := packed_scene.instantiate()
	root.add_child(world)

	if not _require_node(world, "PlayerRig"):
		return
	if not _require_node(world, "MMOCameraRig"):
		return
	if not _require_node(world, "SpatialCasting"):
		return
	if not _require_node(world, "WaterZone"):
		return
	if not _require_node(world, "CastTargetMarker"):
		return
	if not _require_node(world, "CastTargetMarker/TargetDisc"):
		return
	if not _require_node(world, "CastTargetMarker/TargetPin"):
		return
	if not _require_node(world, "CastTargetMarker/TargetTop"):
		return
	if not _require_node(world, "LureMarker"):
		return
	if not _require_node(world, "CastingUILayer/CastingUI"):
		return
	if not _validate_casting_hud(world.get_node("CastingUILayer/CastingUI")):
		return

	for action in INPUT_ACTIONS:
		if not InputMap.has_action(action):
			_fail("Missing input action: %s" % action)
			return

	var player := world.get_node("PlayerRig")
	var camera := world.get_node("MMOCameraRig")
	if not player.has_method("get_desired_movement_direction"):
		_fail("PlayerRig is not using the pipeline movement controller")
		return

	if not camera.has_method("get_mode_output"):
		_fail("MMOCameraRig is not using the pipeline camera controller")
		return
	if not _validate_camera_input(camera):
		return
	if not _validate_spatial_casting(world.get_node("SpatialCasting")):
		return

	print("3D prototype validation passed")
	quit(0)


func _require_node(parent: Node, path: NodePath) -> bool:
	if parent.get_node_or_null(path) == null:
		_fail("Missing node: %s" % path)
		return false
	return true


func _validate_casting_hud(casting_ui: Node) -> bool:
	if casting_ui.get("mouse_filter") != Control.MOUSE_FILTER_IGNORE:
		_fail("Casting HUD root must ignore mouse input outside HUD controls")
		return false

	var cast_button := casting_ui.get_node_or_null("ActionPanel/Layout/CastButton") as Button
	if cast_button == null:
		_fail("Casting HUD is missing the cast button")
		return false

	if cast_button.mouse_filter != Control.MOUSE_FILTER_STOP:
		_fail("Cast button must still receive mouse clicks")
		return false
	if cast_button.pressed.get_connections().is_empty():
		_fail("Cast button is not connected to the casting loop")
		return false

	for path in [
		"ActionPanel",
		"ActionPanel/Layout",
		"ActionPanel/Layout/SpatialLabel",
		"ActionPanel/Layout/QualityLabel",
		"LogPanel",
		"LogPanel/Layout",
	]:
		var control := casting_ui.get_node_or_null(path) as Control
		if control == null:
			_fail("Casting HUD is missing %s" % path)
			return false
		if control.mouse_filter == Control.MOUSE_FILTER_STOP:
			_fail("%s should not stop camera mouse input" % path)
			return false

	return true


func _validate_spatial_casting(spatial_casting: Node) -> bool:
	for method in [
		"can_start_cast",
		"get_cast_block_reason",
		"begin_cast",
		"get_landing_quality",
		"get_spatial_feedback",
		"get_result_context",
		"get_target_point",
	]:
		if not spatial_casting.has_method(method):
			_fail("Spatial casting provider is missing %s" % method)
			return false

	var feedback: String = spatial_casting.call("get_spatial_feedback") as String
	if not feedback.contains("Spatial:"):
		_fail("Spatial casting feedback is not HUD-ready")
		return false

	if not (spatial_casting.call("can_start_cast") as bool):
		_fail("Initial prototype spawn should have a valid spatial cast")
		return false

	var target_point: Vector3 = spatial_casting.call("get_target_point") as Vector3
	var player := spatial_casting.get_node(spatial_casting.get("player_path") as NodePath) as Node3D
	var camera := spatial_casting.get_node(spatial_casting.get("camera_path") as NodePath)
	var camera_forward: Vector3 = camera.call("get_camera_planar_forward") as Vector3
	var player_to_target := target_point - player.global_position
	player_to_target.y = 0.0
	if player_to_target.normalized().dot(camera_forward.normalized()) < 0.9:
		_fail("Cast target is not in the camera-facing direction")
		return false

	spatial_casting.call("begin_cast")
	var quality: float = spatial_casting.call("get_landing_quality") as float
	if quality <= 0.0:
		_fail("Valid spatial cast did not produce landing quality")
		return false

	return true


func _validate_camera_input(camera: Node) -> bool:
	if not camera.has_method("get_yaw_degrees") or not camera.has_method("get_preferred_distance"):
		_fail("Camera controller is missing orbit or zoom inspection methods")
		return false

	var yaw_before: float = camera.call("get_yaw_degrees") as float
	var distance_before: float = camera.call("get_preferred_distance") as float

	var right_mouse_press := InputEventMouseButton.new()
	right_mouse_press.button_index = MOUSE_BUTTON_RIGHT
	right_mouse_press.pressed = true
	camera.call("_unhandled_input", right_mouse_press)

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(12.0, 0.0)
	camera.call("_unhandled_input", mouse_motion)

	var yaw_after: float = camera.call("get_yaw_degrees") as float
	if is_equal_approx(yaw_before, yaw_after):
		_fail("Camera yaw did not change after mouse-look input")
		return false

	var wheel_up := InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	camera.call("_unhandled_input", wheel_up)

	var distance_after: float = camera.call("get_preferred_distance") as float
	if is_equal_approx(distance_before, distance_after):
		_fail("Camera zoom did not change after mouse-wheel input")
		return false

	var right_mouse_release := InputEventMouseButton.new()
	right_mouse_release.button_index = MOUSE_BUTTON_RIGHT
	right_mouse_release.pressed = false
	camera.call("_unhandled_input", right_mouse_release)
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

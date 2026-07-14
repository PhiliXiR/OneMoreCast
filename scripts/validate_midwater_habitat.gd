extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load(WORLD_SCENE) as PackedScene
	if packed_scene == null:
		_fail("Could not load %s" % WORLD_SCENE)
		return
	var world := packed_scene.instantiate()
	root.add_child(world)
	await process_frame

	var presentation := world.get_node_or_null("HomeWater/Presentation") as HomeWaterPresentation
	var habitat := world.get_node_or_null("HomeWater/Presentation/OpenWaterLandmarks") as Node3D
	if presentation == null or habitat == null:
		_fail("Open-water landmarks need the game-owned home-water presentation")
		return
	var landmark_names := [
		HomeWaterPresentation.REED_ISLAND_NAME,
		HomeWaterPresentation.FALLEN_TIMBER_NAME,
		HomeWaterPresentation.ROWBOAT_NAME,
		HomeWaterPresentation.WEST_BUOY_NAME,
		HomeWaterPresentation.EAST_BUOY_NAME,
	]
	for landmark in landmark_names:
		if habitat.get_node_or_null(landmark) == null:
			_fail("Open-water composition is missing %s" % landmark)
			return
	if habitat.get_meta("interactive", true) or _has_collision_shape(habitat):
		_fail("Open-water landmarks must remain non-interactive and non-blocking")
		return
	if not presentation.has_open_fishable_water():
		_fail("Open-water landmarks must leave the central fishable-water corridor open")
		return

	var camera := world.get_node_or_null("MMOCameraRig/Camera3D") as Camera3D
	if camera == null:
		_fail("Focused habitat validation needs the player's initial camera")
		return
	var viewport_size := root.get_viewport().get_visible_rect().size
	for landmark in landmark_names:
		var landmark_node := habitat.get_node(landmark) as Node3D
		if not _is_visible_in_camera(camera, landmark_node.global_position, viewport_size):
			_fail("Initial camera composition must visibly include %s" % landmark)
			return

	print("Open-water landmark composition validation passed")
	quit(0)


func _has_collision_shape(node: Node) -> bool:
	if node is CollisionShape3D:
		return true
	for child in node.get_children():
		if _has_collision_shape(child):
			return true
	return false


func _is_visible_in_camera(camera: Camera3D, world_position: Vector3, viewport_size: Vector2) -> bool:
	if camera.is_position_behind(world_position):
		return false
	var screen_position := camera.unproject_position(world_position)
	return Rect2(Vector2.ZERO, viewport_size).grow(-12.0).has_point(screen_position)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

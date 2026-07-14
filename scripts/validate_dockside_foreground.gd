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

	var presentation := world.get_node_or_null("HomeWater/Presentation") as Node3D
	if presentation == null:
		_fail("Dockside foreground needs the game-owned home-water presentation")
		return
	var foreground := presentation.get_node_or_null("DocksideForeground") as Node3D
	if foreground == null:
		_fail("Dockside foreground dressing is missing")
		return
	var expected_details := ["MooringPost", "TackleCrate", "LandingNet", "Bucket", "RopeCoil", "ShoreGrass00", "ShoreStone00"]
	for detail_name in expected_details:
		if foreground.get_node_or_null(detail_name) == null:
			_fail("Dockside foreground is missing %s" % detail_name)
			return
	if foreground.get_meta("interactive", true):
		_fail("Dockside foreground must remain non-interactive dressing")
		return
	if _has_collision_shape(foreground):
		_fail("Dockside foreground must not obstruct player movement or dock access")
		return
	if not presentation.has_clear_dock_approach():
		_fail("Dockside dressing must preserve a clear cast approach")
		return
	var camera := world.get_node_or_null("MMOCameraRig/Camera3D") as Camera3D
	if camera == null:
		_fail("Focused foreground validation needs the player's initial camera")
		return
	var viewport_size := get_root().get_viewport().get_visible_rect().size
	for detail_name in ["MooringPost", "TackleCrate", "ShoreGrass00"]:
		var detail := foreground.get_node_or_null(detail_name) as Node3D
		if detail == null or not _is_visible_in_camera(camera, detail.global_position, viewport_size):
			_fail("Initial camera view must visibly include %s" % detail_name)
			return

	print("Dockside foreground validation passed")
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

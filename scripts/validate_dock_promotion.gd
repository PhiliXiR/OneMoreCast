extends SceneTree

const DOCK_ASSET := "res://assets/docks/dock_straight_01.glb"
const DOCK_SCENE := "res://scenes/docks/dock_straight_01.tscn"
const WORLD_SCENE := "res://scenes/world_prototype.tscn"


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	if not _validate_packed_scene(DOCK_ASSET, "promoted dock asset"):
		return
	if not _validate_packed_scene(DOCK_SCENE, "reusable dock scene"):
		return

	var world_scene := load(WORLD_SCENE) as PackedScene
	if world_scene == null:
		_fail("Could not load %s" % WORLD_SCENE)
		return

	var world := world_scene.instantiate()
	root.add_child(world)

	var dock := world.get_node_or_null("Dock") as Node3D
	if dock == null:
		_fail("World prototype is missing Dock")
		return
	if dock.scene_file_path != DOCK_SCENE:
		_fail("World Dock does not instance %s" % DOCK_SCENE)
		return
	if dock.global_position.distance_to(Vector3(0.0, 0.0, 4.0)) > 0.01:
		_fail("World Dock is not placed at the expected shoreline prototype position")
		return

	print("Dock promotion validation passed")
	quit(0)


func _validate_packed_scene(path: String, label: String) -> bool:
	var packed_scene := load(path) as PackedScene
	if packed_scene == null:
		_fail("Could not load %s: %s" % [label, path])
		return false

	var instance := packed_scene.instantiate()
	if instance == null:
		_fail("Could not instantiate %s: %s" % [label, path])
		return false

	if _count_mesh_instances(instance) < 1:
		_fail("%s has no MeshInstance3D nodes: %s" % [label, path])
		return false

	instance.queue_free()
	return true


func _count_mesh_instances(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		count += 1

	for child in node.get_children():
		count += _count_mesh_instances(child)

	return count


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

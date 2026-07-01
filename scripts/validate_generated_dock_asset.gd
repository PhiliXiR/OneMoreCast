extends SceneTree

const DOCK_SCENE := "res://assets/_review/generated/issue-44-procedural-dock/dock_straight_01.glb"


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	if not FileAccess.file_exists(DOCK_SCENE):
		_fail("Missing generated dock GLB: %s" % DOCK_SCENE)
		return

	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(DOCK_SCENE, state)
	if error != OK:
		_fail("Could not parse %s: error %d" % [DOCK_SCENE, error])
		return

	var dock := document.generate_scene(state)
	if dock == null:
		_fail("Could not generate scene from %s" % DOCK_SCENE)
		return

	root.add_child(dock)

	var mesh_count := _count_mesh_instances(dock)
	if mesh_count < 1:
		_fail("Generated dock import has no MeshInstance3D nodes")
		return

	print("Generated dock validation passed: %d mesh instances" % mesh_count)
	quit(0)


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

extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const INPUT_ACTIONS := [
	&"move_forward",
	&"move_backward",
	&"move_left",
	&"move_right",
]


func _init() -> void:
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
	if not _require_node(world, "CastingUILayer/CastingUI"):
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

	print("3D prototype validation passed")
	quit(0)


func _require_node(parent: Node, path: NodePath) -> bool:
	if parent.get_node_or_null(path) == null:
		_fail("Missing node: %s" % path)
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

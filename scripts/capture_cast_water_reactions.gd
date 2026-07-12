extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const ENTRY_CAPTURE := "res://docs/visual-review/issue-68-cast-entry.png"
const WAITING_CAPTURE := "res://docs/visual-review/issue-68-waiting-lure.png"


func _initialize() -> void:
	call_deferred("_capture_sequence")


func _capture_sequence() -> void:
	var packed_scene := load(WORLD_SCENE) as PackedScene
	if packed_scene == null:
		_fail("Could not load %s" % WORLD_SCENE)
		return
	var world := packed_scene.instantiate()
	root.add_child(world)
	await process_frame

	var camera_rig := world.get_node("MMOCameraRig") as Node3D
	camera_rig.set_process(false)
	var camera := world.get_node("MMOCameraRig/Camera3D") as Camera3D
	camera.global_position = Vector3(0.0, 5.8, -1.0)
	camera.look_at(Vector3(0.0, 0.0, 8.5))
	var spatial_casting := world.get_node("SpatialCasting")
	spatial_casting.call("begin_cast")
	for frame in 10:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	_capture(ENTRY_CAPTURE)

	for frame in 16:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	_capture(WAITING_CAPTURE)
	print("Cast-entry and waiting-lure visual review captures saved")
	quit(0)


func _capture(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_fail("Could not save visual review capture: %s" % path)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

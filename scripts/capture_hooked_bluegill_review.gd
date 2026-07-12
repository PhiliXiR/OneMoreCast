extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const RECOVERY_CAPTURE := "res://docs/visual-review/issue-71-bluegill-recovery.png"
const LANDING_CAPTURE := "res://docs/visual-review/issue-71-bluegill-landing.png"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
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

	var spatial_casting := world.get_node("SpatialCasting")
	spatial_casting.call("begin_cast")
	for frame in 14:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	spatial_casting.call("begin_reel_feedback", 8.0)
	spatial_casting.call("apply_fight_snapshot", {
		"phase": FishFightModel.Phase.RECOVERY,
		"landing_progress": 0.2,
		"tension": 0.52,
	}, true)
	_frame_hooked_fish(camera, world.get_node("HookedFishMarker") as Node3D)
	await RenderingServer.frame_post_draw
	_capture_png(RECOVERY_CAPTURE)

	spatial_casting.call("present_landed_fish")
	_frame_hooked_fish(camera, world.get_node("HookedFishMarker") as Node3D)
	await RenderingServer.frame_post_draw
	_capture_png(LANDING_CAPTURE)
	print("Hooked Dock Bluegill review captures saved")
	quit(0)


func _capture_png(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_fail("Could not save visual review capture: %s" % path)


func _frame_hooked_fish(camera: Camera3D, fish: Node3D) -> void:
	camera.global_position = fish.global_position + Vector3(0.0, 0.65, -2.25)
	camera.look_at(fish.global_position + Vector3(0.0, 0.04, 0.0))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

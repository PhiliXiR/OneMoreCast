extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const ENTRY_CAPTURE := "res://docs/visual-review/issue-68-cast-entry.png"
const WAITING_CAPTURE := "res://docs/visual-review/issue-68-waiting-lure.png"
const FISH_SIGN_CAPTURE := "res://docs/visual-review/issue-69-fish-signs.png"
const BITE_CAPTURE := "res://docs/visual-review/issue-69-bite-signal.png"
const RECOVERY_CAPTURE := "res://docs/visual-review/issue-70-fight-recovery.png"
const WINDUP_CAPTURE := "res://docs/visual-review/issue-70-surge-windup.png"
const SURGE_CAPTURE := "res://docs/visual-review/issue-70-surge.png"
const LANDING_CAPTURE := "res://docs/visual-review/issue-70-landing.png"


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
	_capture(FISH_SIGN_CAPTURE)
	spatial_casting.call("trigger_bite_feedback")
	spatial_casting.call("refresh_casting_visuals", 0.12)
	await process_frame
	_capture(BITE_CAPTURE)
	spatial_casting.call("begin_reel_feedback", 1.2)
	var lake_surface := world.get_node("LakeSurface") as LakeSurface
	_capture_fight_reaction(lake_surface, LakeSurface.Reaction.FIGHT_RECOVERY, 0.34, 0.48, RECOVERY_CAPTURE)
	_capture_fight_reaction(lake_surface, LakeSurface.Reaction.SURGE_WINDUP, 0.62, 0.72, WINDUP_CAPTURE)
	_capture_fight_reaction(lake_surface, LakeSurface.Reaction.SURGE, 0.94, 1.05, SURGE_CAPTURE)
	spatial_casting.call("present_landed_fish")
	lake_surface.request_landing_reaction(Vector3(0.8, 0.03, 8.2), 1.0, 1.28)
	lake_surface.call("_apply_reaction_visuals")
	await create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	_capture(LANDING_CAPTURE)
	print("Cast, fish-sign, bite, and fight visual review captures saved")
	quit(0)


func _capture_fight_reaction(lake_surface: LakeSurface, reaction: LakeSurface.Reaction, strength: float, radius: float, path: String) -> void:
	lake_surface.set_fight_water_reaction(reaction, Vector3(0.8, 0.03, 8.2), strength, radius, Vector3(0.7, 0.0, 1.0))
	lake_surface.call("_apply_reaction_visuals")
	await create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	_capture(path)


func _capture(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_fail("Could not save visual review capture: %s" % path)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

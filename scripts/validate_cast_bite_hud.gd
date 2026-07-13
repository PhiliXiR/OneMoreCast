extends SceneTree

const WORLD_SCENE := preload("res://scenes/world_prototype.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	var hud := world.get_node("CastingUILayer/CastingUI")
	var spatial := world.get_node("SpatialCasting")
	var player := world.get_node("PlayerRig") as Node3D
	player.global_position = Vector3(0.0, 0.1, 5.0)
	spatial.call("refresh_casting_visuals", 0.0)
	var button := hud.get_node("ActionPanel/Layout/CastButton") as Button
	var rig_tag := hud.get_node("ActionPanel/Layout/RigTag") as Label
	var local_need := hud.get_node("ActionPanel/Layout/LocalNeedLabel") as Label
	var prompt := hud.get_node("ActionPanel/Layout/PromptLabel") as Label
	var teaching := hud.get_node("ActionPanel/Layout/TutorialLabel") as Label
	var spatial_label := hud.get_node("ActionPanel/Layout/SpatialLabel") as Label
	var quality_label := hud.get_node("ActionPanel/Layout/QualityLabel") as Label
	var state_label := hud.get_node("ActionPanel/Layout/StateLabel") as Label
	if not rig_tag.visible or not local_need.visible or prompt.text != "Cast":
		_fail("Ready HUD must show the active rig, collapsed local need, and Cast prompt")
		return
	if not local_need.text.contains("▸") or spatial_label.visible or quality_label.visible:
		_fail("Ready HUD must keep the local need collapsed and avoid spatial quality panels")
		return
	if not (spatial.call("can_start_cast") as bool) or not (spatial.call("is_line_showing_valid_feedback") as bool):
		_fail("Preparing a cast must retain valid estimated landing feedback in the world")
		return
	player.global_position = Vector3(0.0, 0.1, -8.0)
	spatial.call("refresh_casting_visuals", 0.0)
	if spatial.call("can_start_cast") as bool or spatial.call("is_line_showing_valid_feedback") as bool:
		_fail("Preparing a cast must make invalid landing feedback distinct without a HUD quality score")
		return
	player.global_position = Vector3(0.0, 0.1, 5.0)
	spatial.call("refresh_casting_visuals", 0.0)
	button.pressed.emit()
	var saw_waiting := false
	for frame in 60:
		await create_timer(0.05).timeout
		if state_label.text == "State: waiting":
			saw_waiting = true
			break
	if not saw_waiting or not teaching.text.is_empty() or spatial_label.visible or quality_label.visible:
		_fail("Waiting HUD must remain quiet and keep fish signs and landing feedback in the world")
		return
	if spatial.call("get_fish_presence_feedback_label") as String == "none":
		await create_timer(0.25).timeout
	if spatial.call("get_fish_presence_feedback_label") as String == "none" or prompt.visible:
		_fail("Ambient fish signs must remain world feedback and must not create an action prompt")
		return
	var saw_bite := false
	for frame in 60:
		await create_timer(0.05).timeout
		if prompt.text == "Set Hook":
			saw_bite = true
			break
	if not saw_bite or button.text != "Set Hook" or not teaching.text.contains("sharp line twitch") or not hud.call("is_bite_cue_playing"):
		_fail("Bite HUD must provide a distinct audible Set Hook prompt with first-use teaching")
		return
	print("Cast and bite HUD validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

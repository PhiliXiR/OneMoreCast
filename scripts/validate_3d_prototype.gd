extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const INPUT_ACTIONS := [
	&"move_forward",
	&"move_backward",
	&"move_left",
	&"move_right",
	&"set_hook",
]


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	if not _validate_window_stretch_settings():
		return
	if not _validate_fight_model_outcomes():
		return

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
	if not _require_node(world, "CastTargetMarker/TickNorth"):
		return
	if not _require_node(world, "CastTargetMarker/TickEast"):
		return
	if not _require_node(world, "CastTargetMarker/TickSouth"):
		return
	if not _require_node(world, "CastTargetMarker/TickWest"):
		return
	if not _require_node(world, "LureMarker"):
		return
	if not _require_node(world, "HookMarker"):
		return
	if not _require_node(world, "LineEndpoint"):
		return
	if not _require_node(world, "HookedFishMarker"):
		return
	if not _require_node(world, "HookedFishMouthMarker"):
		return
	if not _require_node(world, "LandingFeedback"):
		return
	if not _require_node(world, "LandingFeedback/WaterRippleOuter"):
		return
	if not _require_node(world, "LandingFeedback/WaterRippleInner"):
		return
	if not _require_node(world, "LandingFeedback/MissPuff"):
		return
	if not _require_node(world, "FishingLine"):
		return
	if not _require_node(world, "LineOverlayLayer/FishingLineOverlay"):
		return
	if not _require_node(world, "PlayerRig/VisualRoot/RodRoot"):
		return
	if not _require_node(world, "PlayerRig/VisualRoot/RodRoot/RodMesh"):
		return
	if not _require_node(world, "PlayerRig/VisualRoot/RodRoot/RodTip"):
		return
	if not _require_node(world, "CastingUILayer/CastingUI"):
		return
	if not _validate_casting_hud(world.get_node("CastingUILayer/CastingUI")):
		return
	if not _validate_cast_target_marker(world.get_node("CastTargetMarker")):
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
	if not await _validate_rod_and_line(world):
		return
	if not _validate_spatial_casting(world.get_node("SpatialCasting")):
		return
	if not await _validate_cast_button_starts_cast(world.get_node("CastingUILayer/CastingUI")):
		return

	print("3D prototype validation passed")
	quit(0)


func _validate_fight_model_outcomes() -> bool:
	var fast_config := {
		"recovery_durations": [0.2, 0.2, 0.2, 0.2],
		"windup_durations": [0.1, 0.1, 0.1],
		"surge_durations": [0.2, 0.2, 0.2],
		"danger_window": 0.25,
	}
	var success := FishFightModel.new()
	success.start(fast_config)
	for step in 500:
		var snapshot := success.snapshot()
		success.advance(0.05, String(snapshot["phase_name"]) == "recovery")
		if int(success.snapshot()["outcome"]) != FishFightModel.Outcome.ONGOING: break
	if int(success.snapshot()["outcome"]) != FishFightModel.Outcome.LANDED:
		_fail("Recovery reeling and surge yielding should land the Dock Bluegill")
		return false

	var slack_loss := FishFightModel.new()
	slack_loss.start({"recovery_durations": [2.0], "danger_window": 0.2})
	for step in 30: slack_loss.advance(0.1, false)
	if int(slack_loss.snapshot()["outcome"]) != FishFightModel.Outcome.THROWN_HOOK:
		_fail("Sustained line slack should let the fish throw the hook")
		return false

	var line_break := FishFightModel.new()
	line_break.start({"recovery_durations": [0.05], "windup_durations": [0.05], "surge_durations": [2.0], "danger_window": 0.2})
	for step in 30: line_break.advance(0.1, true)
	if int(line_break.snapshot()["outcome"]) != FishFightModel.Outcome.LINE_BREAK:
		_fail("Sustained excessive line tension should break the line")
		return false
	return true


func _require_node(parent: Node, path: NodePath) -> bool:
	if parent.get_node_or_null(path) == null:
		_fail("Missing node: %s" % path)
		return false
	return true


func _validate_window_stretch_settings() -> bool:
	var stretch_mode: String = ProjectSettings.get_setting("display/window/stretch/mode", "")
	var stretch_aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect", "")
	if stretch_mode != "canvas_items":
		_fail("Window stretch mode must be canvas_items so UI hitboxes stay aligned with rendered controls")
		return false
	if stretch_aspect != "expand":
		_fail("Window stretch aspect must be expand so the 1920x1080 UI scales without mouse offset")
		return false
	return true


func _validate_casting_hud(casting_ui: Node) -> bool:
	if casting_ui.get("mouse_filter") == Control.MOUSE_FILTER_STOP:
		_fail("Casting HUD root must not stop mouse input outside HUD controls")
		return false

	var cast_button := casting_ui.get_node_or_null("ActionPanel/Layout/CastButton") as Button
	if cast_button == null:
		_fail("Casting HUD is missing the cast button")
		return false
	for path in ["ActionPanel/Layout/TensionGauge", "ActionPanel/Layout/TensionRegions", "ActionPanel/Layout/TutorialLabel"]:
		if casting_ui.get_node_or_null(path) == null:
			_fail("Casting HUD is missing fish-fight feedback: %s" % path)
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


func _validate_cast_target_marker(cast_target_marker: Node) -> bool:
	var disc := cast_target_marker.get_node("TargetDisc") as MeshInstance3D
	var pin := cast_target_marker.get_node("TargetPin") as MeshInstance3D
	var top := cast_target_marker.get_node("TargetTop") as MeshInstance3D
	var tick_north := cast_target_marker.get_node("TickNorth") as MeshInstance3D
	var disc_mesh := disc.mesh as CylinderMesh
	var pin_mesh := pin.mesh as CylinderMesh
	var top_mesh := top.mesh as SphereMesh
	var tick_mesh := tick_north.mesh as BoxMesh
	if disc_mesh == null or disc_mesh.top_radius > 0.35:
		_fail("Cast target disc should stay compact and unobtrusive")
		return false
	if pin_mesh == null or pin_mesh.height > 0.35:
		_fail("Cast target pin should stay low-profile")
		return false
	if top_mesh == null or top_mesh.radius > 0.1:
		_fail("Cast target top marker should stay subtle")
		return false
	if top.position.y > 0.35:
		_fail("Cast target marker should not tower over the water")
		return false
	if tick_mesh == null or tick_mesh.size.x > 0.3 or tick_mesh.size.z > 0.05:
		_fail("Cast target ticks should stay clean and minimal")
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
		"get_rod_tip_position",
		"get_line_endpoint",
		"get_lure_marker_position",
		"get_hook_marker_position",
		"get_line_points_world",
		"get_line_state_label",
		"get_line_overlay_width",
		"is_line_showing_valid_feedback",
		"is_world_line_disabled",
		"is_line_endpoint_visible",
		"get_rod_cast_motion_offset",
		"get_landing_feedback_label",
		"is_landing_feedback_visible",
		"did_last_cast_land_in_water",
		"is_cast_landed",
		"get_waiting_for_bite_duration",
		"trigger_bite_feedback",
		"is_bite_feedback_active",
		"get_bite_feedback_label",
		"begin_reel_feedback",
		"is_reel_feedback_active",
		"apply_fight_snapshot",
		"present_landed_fish",
		"end_fight_presentation",
		"refresh_casting_visuals",
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
	if not (spatial_casting.call("did_last_cast_land_in_water") as bool):
		_fail("Valid spatial cast should record that it landed in water")
		return false
	if (spatial_casting.call("get_waiting_for_bite_duration") as float) <= 0.0:
		_fail("Valid spatial cast should expose a short waiting-for-bite duration")
		return false

	return true


func _validate_rod_and_line(world: Node) -> bool:
	var spatial_casting := world.get_node("SpatialCasting")
	var rod_root := world.get_node("PlayerRig/VisualRoot/RodRoot") as Node3D
	var rod_mesh := world.get_node("PlayerRig/VisualRoot/RodRoot/RodMesh") as MeshInstance3D
	var rod_tip := world.get_node("PlayerRig/VisualRoot/RodRoot/RodTip") as Node3D
	var fishing_line_overlay := world.get_node("LineOverlayLayer/FishingLineOverlay") as Line2D
	var lure_marker := world.get_node("LureMarker") as MeshInstance3D
	var hook_marker := world.get_node("HookMarker") as MeshInstance3D
	var line_endpoint_node := world.get_node("LineEndpoint") as Node3D
	if not rod_mesh.visible:
		_fail("Fishing rod mesh should be visible")
		return false
	if rod_tip.global_position.distance_to(world.get_node("PlayerRig").global_position) < 1.0:
		_fail("Fishing rod tip should be out in front of the player")
		return false
	if rod_root.rotation.x < 0.7:
		_fail("Fishing rod should rest in a more upright ready pose")
		return false

	spatial_casting.call("refresh_casting_visuals")
	await process_frame
	if not (spatial_casting.call("is_world_line_disabled") as bool):
		_fail("Thick world fishing line should be disabled during normal gameplay")
		return false
	if spatial_casting.call("is_line_endpoint_visible") as bool:
		_fail("LineEndpoint should be an invisible simulation anchor")
		return false
	if lure_marker.visible or hook_marker.visible:
		_fail("Visible terminal tackle should stay hidden while only aiming")
		return false
	if not fishing_line_overlay.visible:
		_fail("Projected fishing line should preview the cast target")
		return false
	if (spatial_casting.call("get_line_overlay_width") as float) > 2.0:
		_fail("Projected fishing line should be thin enough to read as fishing line")
		return false

	var target_point: Vector3 = spatial_casting.call("get_target_point") as Vector3
	var line_endpoint: Vector3 = spatial_casting.call("get_line_endpoint") as Vector3
	if line_endpoint.distance_to(target_point + Vector3.UP * 0.12) < 1.0:
		_fail("Aiming line endpoint should not extend to the cast target before casting")
		return false
	if line_endpoint.distance_to(rod_tip.global_position) > 1.0:
		_fail("Aiming line should stay near the rod before casting")
		return false
	if line_endpoint.distance_to(line_endpoint_node.global_position) > 0.01:
		_fail("Spatial casting line endpoint should match the LineEndpoint node")
		return false
	var line_points: Array = spatial_casting.call("get_line_points_world") as Array
	if line_points.size() < 12:
		_fail("Fishing line should expose enough world points for sagging line rendering")
		return false
	if not (spatial_casting.call("is_line_showing_valid_feedback") as bool):
		_fail("Fishing line should show valid feedback for the initial cast target")
		return false

	var original_water_center: Vector3 = spatial_casting.get("water_center") as Vector3
	spatial_casting.set("water_center", Vector3(100.0, original_water_center.y, 100.0))
	spatial_casting.call("refresh_casting_visuals")
	await process_frame
	if spatial_casting.call("is_line_showing_valid_feedback") as bool:
		_fail("Fishing line should show invalid feedback when the target is off water")
		return false
	spatial_casting.set("water_center", original_water_center)
	spatial_casting.call("refresh_casting_visuals")
	await process_frame

	spatial_casting.call("begin_cast")
	target_point = spatial_casting.call("get_target_point") as Vector3
	if spatial_casting.call("get_line_state_label") as String != "casting":
		_fail("Fishing line should enter casting state after cast starts")
		return false
	if not lure_marker.visible or not hook_marker.visible:
		_fail("Visible lure and hook should appear when the cast starts")
		return false
	line_endpoint = spatial_casting.call("get_line_endpoint") as Vector3
	if line_endpoint.distance_to(rod_tip.global_position) > 0.1:
		_fail("LineEndpoint should start near the rod tip")
		return false
	if lure_marker.global_position.distance_to(line_endpoint) <= 0.01:
		_fail("LureMarker should be a visible object offset from the invisible LineEndpoint")
		return false
	if hook_marker.global_position.distance_to(line_endpoint) <= 0.01:
		_fail("HookMarker should be a visible object offset from the invisible LineEndpoint")
		return false
	spatial_casting.call("refresh_casting_visuals", 0.08)
	await process_frame
	if absf(spatial_casting.call("get_rod_cast_motion_offset") as float) <= 0.001:
		_fail("Rod should begin moving when the cast starts")
		return false

	for frame in 7:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame

	line_endpoint = spatial_casting.call("get_line_endpoint") as Vector3
	if line_endpoint.distance_to(line_endpoint_node.global_position) > 0.01:
		_fail("Fishing line endpoint should follow the invisible LineEndpoint node during cast")
		return false
	if lure_marker.global_position.distance_to(line_endpoint) > 0.2:
		_fail("LureMarker should visually follow the moving LineEndpoint during cast")
		return false
	if hook_marker.global_position.distance_to(line_endpoint) > 0.2:
		_fail("HookMarker should visually follow the moving LineEndpoint during cast")
		return false
	line_points = spatial_casting.call("get_line_points_world") as Array
	if line_points.size() < 16:
		_fail("Casting fishing line should expose a multi-point unrolling loop")
		return false
	if line_endpoint.distance_to(rod_tip.global_position) < 0.5:
		_fail("LineEndpoint should travel away from the rod during the cast arc")
		return false

	for frame in 2:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame

	var state_label := spatial_casting.call("get_line_state_label") as String
	if state_label != "slack" and state_label != "taut":
		_fail("Fishing line should settle into slack or taut state after landing")
		return false
	line_endpoint = spatial_casting.call("get_line_endpoint") as Vector3
	if line_endpoint.distance_to(target_point + Vector3.UP * 0.12) > 0.15:
		_fail(
			"LineEndpoint should land at the target point. Endpoint=%s expected=%s target=%s"
			% [line_endpoint, target_point + Vector3.UP * 0.12, target_point]
		)
		return false
	if lure_marker.global_position.distance_to(line_endpoint) > 0.2:
		_fail("LureMarker should stay attached to the endpoint after landing")
		return false
	if hook_marker.global_position.distance_to(line_endpoint) > 0.2:
		_fail("HookMarker should stay attached to the endpoint after landing")
		return false
	if not (spatial_casting.call("is_landing_feedback_visible") as bool):
		_fail("Water landing feedback should be visible as the lure lands")
		return false
	if spatial_casting.call("get_landing_feedback_label") as String != "water splash":
		_fail("Water landing should register water splash feedback")
		return false
	var landing_feedback := world.get_node("LandingFeedback") as Node3D
	if landing_feedback.global_position.distance_to(target_point + Vector3.UP * 0.15) > 0.35:
		_fail("Landing feedback should appear at the lure landing point")
		return false

	for frame in 18:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	if spatial_casting.call("get_line_state_label") as String != "taut":
		_fail("Fishing line should transition to taut after the landed slack settles")
		return false

	var lure_before_bite := lure_marker.global_position
	var line_before_reel := Vector3.ZERO
	var rod_before_bite := spatial_casting.call("get_rod_cast_motion_offset") as float
	if not (spatial_casting.call("trigger_bite_feedback") as bool):
		_fail("Valid landed water cast should trigger bite feedback")
		return false
	if not (spatial_casting.call("is_bite_feedback_active") as bool):
		_fail("Bite feedback should become active after being triggered")
		return false
	if spatial_casting.call("get_bite_feedback_label") as String != "bite twitch":
		_fail("Bite feedback should expose a bite twitch label")
		return false
	for frame in 3:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	var lure_after_bite := lure_marker.global_position
	var rod_after_bite := spatial_casting.call("get_rod_cast_motion_offset") as float
	if lure_after_bite.distance_to(lure_before_bite) <= 0.02 and absf(rod_after_bite - rod_before_bite) <= 0.01:
		_fail("Bite feedback should visibly twitch the lure, line, or rod")
		return false
	line_before_reel = spatial_casting.call("get_line_endpoint") as Vector3
	if not (spatial_casting.call("begin_reel_feedback", 1.2) as bool):
		_fail("Valid hooked cast should start reel feedback")
		return false
	if not (spatial_casting.call("is_reel_feedback_active") as bool):
		_fail("Reel feedback should become active")
		return false
	var hooked_fish_marker := world.get_node("HookedFishMarker") as MeshInstance3D
	var hooked_fish_mouth_marker := world.get_node("HookedFishMouthMarker") as MeshInstance3D
	if not hooked_fish_marker.visible:
		_fail("Hooked fish marker should appear during reel feedback")
		return false
	if not hooked_fish_mouth_marker.visible:
		_fail("Hooked fish mouth marker should appear during reel feedback")
		return false
	if hooked_fish_marker.global_position.y >= original_water_center.y:
		_fail("Hooked fish should start underwater during reel feedback")
		return false
	var hook_position := spatial_casting.call("get_hook_marker_position") as Vector3
	var reel_endpoint := spatial_casting.call("get_line_endpoint") as Vector3
	if reel_endpoint.y >= original_water_center.y:
		_fail("Line endpoint should stay underwater with the hooked fish during reel feedback")
		return false
	if hook_position.distance_to(reel_endpoint) > 0.03:
		_fail("Hook should stay at the line endpoint once a fish is hooked")
		return false
	if hooked_fish_mouth_marker.global_position.distance_to(reel_endpoint) > 0.03:
		_fail("Fish mouth marker should stay at the underwater line endpoint")
		return false
	if hook_position.y >= original_water_center.y:
		_fail("Hook should stay underwater in the fish mouth during reel feedback")
		return false
	if hook_position.distance_to(hooked_fish_marker.global_position) > 0.25:
		_fail("Hook should stay embedded in the hooked fish during reel feedback")
		return false
	for frame in 8:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	var line_during_reel := spatial_casting.call("get_line_endpoint") as Vector3
	if line_during_reel.distance_to(rod_tip.global_position) >= line_before_reel.distance_to(rod_tip.global_position):
		_fail("Reel feedback should shorten the fishing line toward the rod")
		return false
	if line_during_reel.y >= original_water_center.y:
		_fail("Line endpoint should remain underwater until the fish is caught")
		return false
	hook_position = spatial_casting.call("get_hook_marker_position") as Vector3
	if hook_position.distance_to(line_during_reel) > 0.03:
		_fail("Hook should continue riding the line endpoint while reeling")
		return false
	if hooked_fish_mouth_marker.global_position.distance_to(line_during_reel) > 0.03:
		_fail("Fish mouth marker should continue riding the underwater line endpoint")
		return false
	if hook_position.y >= original_water_center.y:
		_fail("Hook should remain underwater with the fish until caught")
		return false
	if hook_position.distance_to(hooked_fish_marker.global_position) > 0.25:
		_fail("Hook should remain in the hooked fish as it moves toward the rod")
		return false
	if hooked_fish_marker.global_position.y >= original_water_center.y:
		_fail("Hooked fish should stay underwater until it gets closer to the rod")
		return false

	spatial_casting.set("water_center", Vector3(100.0, original_water_center.y, 100.0))
	spatial_casting.call("refresh_casting_visuals")
	await process_frame
	spatial_casting.call("begin_cast")
	for frame in 10:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	if not (spatial_casting.call("is_landing_feedback_visible") as bool):
		_fail("Off-water landing feedback should be visible as the lure lands")
		return false
	if spatial_casting.call("get_landing_feedback_label") as String != "miss puff":
		_fail("Off-water landing should register miss puff feedback")
		return false
	if spatial_casting.call("trigger_bite_feedback") as bool:
		_fail("Off-water landing should not trigger bite feedback")
		return false
	spatial_casting.set("water_center", original_water_center)
	spatial_casting.call("refresh_casting_visuals")
	await process_frame

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


func _validate_cast_button_starts_cast(casting_ui: Node) -> bool:
	var cast_button := casting_ui.get_node("ActionPanel/Layout/CastButton") as Button
	var state_label := casting_ui.get_node("ActionPanel/Layout/StateLabel") as Label
	var result_label := casting_ui.get_node("ActionPanel/Layout/ResultLabel") as Label
	var inventory_label := casting_ui.get_node("LogPanel/Layout/InventoryLabel") as Label
	var button_center := cast_button.get_global_rect().get_center()
	var mouse_press := InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	mouse_press.position = button_center
	root.push_input(mouse_press)
	await process_frame
	var mouse_release := InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_LEFT
	mouse_release.pressed = false
	mouse_release.position = button_center
	root.push_input(mouse_release)
	await process_frame
	if state_label.text == "State: ready":
		_fail(
			"Cast button press did not start the casting loop. Rect=%s disabled=%s mouse_filter=%s"
			% [cast_button.get_global_rect(), cast_button.disabled, cast_button.mouse_filter]
		)
		return false

	var saw_waiting := false
	for frame in 60:
		await create_timer(0.05).timeout
		if state_label.text == "State: waiting":
			saw_waiting = true
			break
		if state_label.text == "State: result":
			_fail("Cast loop reached result before entering waiting-for-bite")
			return false
	if not saw_waiting:
		_fail("Cast loop did not enter waiting-for-bite after the lure landed")
		return false
	_push_action(&"set_hook", true)
	_push_action(&"set_hook", false)
	await create_timer(0.05).timeout
	if state_label.text != "State: waiting":
		_fail("Hook input before the bite window should not leave waiting state")
		return false
	var saw_bite := false
	for frame in 60:
		await create_timer(0.05).timeout
		if state_label.text == "State: bite":
			saw_bite = true
			break
		if state_label.text == "State: result":
			_fail("Cast loop reached result before showing bite state")
			return false
	if not saw_bite:
		_fail("Cast loop did not enter bite state after waiting-for-bite")
		return false
	if cast_button.text != "Set Hook" or cast_button.disabled:
		_fail("Cast button should become an enabled Set Hook action during the bite window")
		return false
	_push_action(&"set_hook", true)
	_push_action(&"set_hook", false)
	var saw_reeling := false
	for frame in 40:
		await create_timer(0.05).timeout
		if state_label.text == "State: reeling":
			saw_reeling = true
			break
	if not saw_reeling:
		_fail("Hook-set input should enter a reeling state before the catch result")
		return false
	if cast_button.text != "Hold to Reel":
		_fail("Fish fight should label the contextual action Hold to Reel")
		return false
	var tension_gauge := casting_ui.get_node("ActionPanel/Layout/TensionGauge") as ProgressBar
	if not tension_gauge.visible:
		_fail("Line-tension gauge should be visible during the fish fight")
		return false
	# Follow the world-readable rhythm through the public controller snapshot.
	var reeling_input_held := false
	for frame in 500:
		var snapshot: Dictionary = casting_ui.call("get_fight_snapshot") as Dictionary
		var should_reel := String(snapshot.get("phase_name", "recovery")) == "recovery"
		if should_reel != reeling_input_held:
			_push_action(&"set_hook", should_reel)
			reeling_input_held = should_reel
		await create_timer(0.05).timeout
		if state_label.text == "State: landed fish":
			if inventory_label.text.contains("Dock Bluegill"):
				_fail("Catch must not be recorded before landed-fish presentation completes")
				return false
		if state_label.text == "State: result": break
	if reeling_input_held: _push_action(&"set_hook", false)
	if state_label.text != "State: result":
		_fail("Competent reel-or-yield input should resolve the fight into a result state")
		return false
	if not result_label.text.contains("Dock Bluegill"):
		_fail("Hook-set input during the bite window should produce a named fish result")
		return false
	if not inventory_label.text.contains("Dock Bluegill x1"):
		_fail("Successful catch should update inventory feedback")
		return false
	for frame in 30:
		await create_timer(0.05).timeout
		if state_label.text == "State: ready":
			break
	if state_label.text != "State: ready":
		_fail("Fishing loop should return to ready after catch result")
		return false
	return true


func _push_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	root.push_input(event)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

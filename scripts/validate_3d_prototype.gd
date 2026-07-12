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
	if not await _validate_waiting_fish_signs(world):
		return
	if not await _validate_cast_button_starts_cast(world.get_node("CastingUILayer/CastingUI")):
		return

	print("3D prototype validation passed")
	quit(0)


func _validate_fight_model_outcomes() -> bool:
	var recovery_only := FishFightModel.new()
	recovery_only.start({"recovery_only": true, "recovery_reel_rate": 0.5})
	var starting_tension: float = recovery_only.snapshot()["tension"]
	recovery_only.advance(0.5, false)
	if float(recovery_only.snapshot()["tension"]) >= starting_tension:
		_fail("Yielding during recovery should lower line tension")
		return false
	if int(recovery_only.snapshot()["outcome"]) != FishFightModel.Outcome.ONGOING:
		_fail("Yielding during the recovery-only fight should not throw the hook")
		return false
	for step in 50:
		recovery_only.advance(0.05, true)
		if int(recovery_only.snapshot()["outcome"]) != FishFightModel.Outcome.ONGOING:
			break
	if int(recovery_only.snapshot()["outcome"]) != FishFightModel.Outcome.LANDED:
		_fail("Holding reel should land a recovery-only hooked fish")
		return false

	var surge_response := FishFightModel.new()
	surge_response.start({
		"recovery_only": false,
		"recovery_durations": [0.4, 0.4],
		"windup_durations": [0.3, 0.1],
		"surge_durations": [4.0, 0.2],
		"surge_count": 2,
		"danger_window": 10.0,
		"recovery_reel_rate": 0.5,
	})
	var initial_snapshot := surge_response.snapshot()
	if int(initial_snapshot["phase"]) != FishFightModel.Phase.RECOVERY:
		_fail("A fish fight must begin in recovery before its first surge wind-up")
		return false
	if not is_equal_approx(float(initial_snapshot["phase_duration"]), 0.4):
		_fail("Configured phase durations should be selected at fight start")
		return false
	surge_response.advance(0.4, true)
	var windup_snapshot := surge_response.snapshot()
	if int(windup_snapshot["phase"]) != FishFightModel.Phase.SURGE_WINDUP:
		_fail("Recovery should lead into a surge wind-up")
		return false
	if not is_equal_approx(float(windup_snapshot["phase_duration"]), 0.3):
		_fail("The first deterministic surge wind-up duration should remain stable")
		return false
	surge_response.advance(0.3, true)
	var surge_start := surge_response.snapshot()
	if int(surge_start["phase"]) != FishFightModel.Phase.SURGE:
		_fail("Surge wind-up should lead into a surge")
		return false
	var tension_before_reeling: float = surge_start["tension"]
	surge_response.advance(0.2, true)
	if float(surge_response.snapshot()["tension"]) <= tension_before_reeling:
		_fail("Reeling during a surge should rapidly raise line tension")
		return false
	if int(surge_response.snapshot()["outcome"]) != FishFightModel.Outcome.ONGOING:
		_fail("A brief surge response should remain playable instead of resolving a line break")
		return false
	var progress_before_yielding: float = surge_response.snapshot()["landing_progress"]
	var tension_before_yielding: float = surge_response.snapshot()["tension"]
	surge_response.advance(0.2, false)
	var yielding_snapshot := surge_response.snapshot()
	if float(yielding_snapshot["tension"]) >= tension_before_yielding:
		_fail("Yielding during a surge should move line tension toward safety")
		return false
	if float(yielding_snapshot["landing_progress"]) >= progress_before_yielding:
		_fail("Yielding during a surge should let the hooked fish regain modest distance")
		return false
	for step in 14:
		surge_response.advance(0.2, false)
	var floor_snapshot := surge_response.snapshot()
	if float(floor_snapshot["landing_progress"]) < float(floor_snapshot["surge_progress_floor"]):
		_fail("A surge must not erase landing progress below its captured floor")
		return false
	if float(floor_snapshot["surge_progress_floor"]) <= 0.0:
		_fail("A surge after recovery should retain a non-zero landing-progress floor")
		return false

	var fast_config := {
		"recovery_only": false,
		"recovery_durations": [0.2, 0.2, 0.2, 0.2],
		"windup_durations": [0.1, 0.1, 0.1],
		"surge_durations": [0.2, 0.2, 0.2],
		"danger_window": 0.25,
	}
	var success := FishFightModel.new()
	success.start(fast_config)
	for step in 500:
		var snapshot := success.snapshot()
		success.advance(0.05, int(snapshot["phase"]) == FishFightModel.Phase.RECOVERY)
		if int(success.snapshot()["outcome"]) != FishFightModel.Outcome.ONGOING: break
	if int(success.snapshot()["outcome"]) != FishFightModel.Outcome.LANDED:
		_fail("Recovery reeling and surge yielding should land the Dock Bluegill")
		return false

	var slack_loss := FishFightModel.new()
	slack_loss.start({"recovery_only": false, "recovery_durations": [4.0], "danger_window": 0.9})
	for step in 18: slack_loss.advance(0.1, false)
	var recoverable_slack := slack_loss.snapshot()
	if float(recoverable_slack["slack_danger"]) <= 0.0:
		_fail("Prolonged yielding during recovery should accumulate slack danger")
		return false
	if int(recoverable_slack["outcome"]) != FishFightModel.Outcome.ONGOING:
		_fail("Entering line slack once should remain recoverable through a danger window")
		return false
	for step in 4: slack_loss.advance(0.1, true)
	if not is_zero_approx(float(slack_loss.snapshot()["slack_danger"])):
		_fail("Returning to safe tension should fully drain brief slack danger quickly")
		return false
	for step in 30: slack_loss.advance(0.1, false)
	if int(slack_loss.snapshot()["outcome"]) != FishFightModel.Outcome.THROWN_HOOK:
		_fail("Sustained line slack should let the fish throw the hook")
		return false

	var line_break := FishFightModel.new()
	line_break.start({"recovery_only": false, "recovery_durations": [0.05], "windup_durations": [0.05], "surge_durations": [3.0], "danger_window": 0.6})
	for step in 9: line_break.advance(0.1, true)
	var recoverable_high_tension := line_break.snapshot()
	if float(recoverable_high_tension["high_tension_danger"]) <= 0.0:
		_fail("Reeling through a surge should accumulate high-tension danger")
		return false
	if int(recoverable_high_tension["outcome"]) != FishFightModel.Outcome.ONGOING:
		_fail("Brief excessive line tension should remain recoverable through a danger window")
		return false
	for step in 5: line_break.advance(0.1, false)
	if not is_zero_approx(float(line_break.snapshot()["high_tension_danger"])):
		_fail("Yielding to safe tension should fully drain brief line-break danger quickly")
		return false
	for step in 20: line_break.advance(0.1, true)
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
		"get_hooked_fish_animation",
		"is_hooked_fish_silhouette",
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
		"get_fish_presence_feedback_label",
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


func _validate_waiting_fish_signs(world: Node) -> bool:
	var spatial_casting := world.get_node("SpatialCasting")
	var lake_surface := world.get_node("LakeSurface")
	var observed_reactions: Array = []
	lake_surface.reaction_requested.connect(
		func(reaction: LakeSurface.Reaction, world_position: Vector3, _strength: float, _radius: float) -> void:
			observed_reactions.append([reaction, world_position])
	)
	spatial_casting.call("begin_cast")
	for frame in 11:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	for frame in 12:
		spatial_casting.call("refresh_casting_visuals", 0.08)
		await process_frame
	var saw_ambient := false
	var saw_lure_sign := false
	var cast_destination: Vector3 = spatial_casting.call("get_line_endpoint") as Vector3
	for reaction_entry in observed_reactions:
		var reaction: LakeSurface.Reaction = reaction_entry[0]
		var sign_position: Vector3 = reaction_entry[1]
		if reaction == LakeSurface.Reaction.AMBIENT_FISH_SIGN:
			saw_ambient = true
			if sign_position.distance_to(cast_destination) < 1.0:
				_fail("Ambient fish signs must remain independent of the active lure")
				return false
		if reaction == LakeSurface.Reaction.LURE_FISH_SIGN:
			saw_lure_sign = true
			if sign_position.distance_to(cast_destination) < 0.2:
				_fail("Lure-focused fish signs should not obscure active tackle")
				return false
	if not saw_ambient or not saw_lure_sign:
		_fail("Waiting-for-bite should emit both ambient and lure-focused fish signs")
		return false
	if spatial_casting.call("get_fish_presence_feedback_label") as String != "lure fish sign":
		_fail("Waiting fish-sign feedback should be observable through external state")
		return false
	if not (spatial_casting.call("trigger_bite_feedback") as bool):
		_fail("A valid waiting cast should trigger bite feedback")
		return false
	if spatial_casting.call("get_fish_presence_feedback_label") as String != "bite signal":
		_fail("The actionable bite must be externally distinct from fish signs")
		return false
	if lake_surface.call("get_active_reaction_label") as String != "bite signal":
		_fail("The lake surface must expose the bite as distinct feedback")
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
	if spatial_casting.call("get_landing_feedback_label") as String != "water splash":
		_fail("Water landing should register water splash feedback")
		return false
	var lake_surface := world.get_node("LakeSurface") as LakeSurface
	if lake_surface == null or not lake_surface.is_cast_entry_reaction_active():
		_fail("Water landing should request an active lake-surface cast-entry reaction")
		return false
	if not lake_surface.is_waiting_lure_reaction_active():
		_fail("Landed tackle should activate a readable waiting-lure reaction")
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
	var hooked_fish_marker := world.get_node("HookedFishMarker") as Node3D
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

	var cast_entry_requests := 0
	lake_surface.reaction_requested.connect(
		func(reaction: LakeSurface.Reaction, _world_position: Vector3, _strength: float, _radius: float) -> void:
			if reaction == LakeSurface.Reaction.CAST_ENTRY:
				cast_entry_requests += 1
	)
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
	if lake_surface.is_waiting_lure_reaction_active():
		_fail("Off-water landing should not keep a waiting-lure reaction active")
		return false
	if cast_entry_requests != 0:
		_fail("Off-water landing should not request a lake-surface cast-entry reaction")
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
	var message_label := casting_ui.get_node("ActionPanel/Layout/MessageLabel") as Label
	var result_label := casting_ui.get_node("ActionPanel/Layout/ResultLabel") as Label
	var inventory_label := casting_ui.get_node("LogPanel/Layout/InventoryLabel") as Label
	casting_ui.call("configure_next_fight", {
		"recovery_only": false,
		"recovery_reel_rate": 0.5,
		"recovery_durations": [0.35, 0.3, 0.3],
		"windup_durations": [0.3, 0.12],
		"surge_durations": [0.25, 0.25],
		"surge_count": 2,
		"danger_window": 2.0,
	})
	cast_button.pressed.emit()
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
	var tension_regions := casting_ui.get_node("ActionPanel/Layout/TensionRegions") as HBoxContainer
	if not tension_regions.visible:
		_fail("Line-tension regions should be visible during the fish fight")
		return false
	if tension_regions.get_node("Slack").text != "SLACK":
		_fail("Line-tension gauge should distinguish the slack region")
		return false
	if not tension_regions.get_node("Safe").text.contains("SAFE TENSION"):
		_fail("Line-tension gauge should distinguish safe tension")
		return false
	if tension_regions.get_node("Excessive").text != "EXCESSIVE":
		_fail("Line-tension gauge should distinguish high tension")
		return false
	var tutorial_label := casting_ui.get_node("ActionPanel/Layout/TutorialLabel") as Label
	if not tutorial_label.text.contains("Hold to reel"):
		_fail("The first fight should show the hold-to-reel instruction")
		return false
	var spatial_casting := casting_ui.get_node("../../SpatialCasting")
	var endpoint_before_reeling := spatial_casting.call("get_line_endpoint") as Vector3
	var fight_snapshot: Dictionary = casting_ui.call("get_fight_snapshot") as Dictionary
	var yielded_tension: float = fight_snapshot.get("tension", 0.0)
	await create_timer(0.15).timeout
	fight_snapshot = casting_ui.call("get_fight_snapshot") as Dictionary
	var tension_after_yield: float = fight_snapshot.get("tension", 0.0)
	if tension_after_yield >= yielded_tension:
		_fail("Released contextual input should yield and lower line tension")
		return false
	var hook_marker := casting_ui.get_node("../../HookMarker") as MeshInstance3D
	var hooked_fish := casting_ui.get_node("../../HookedFishMarker") as Node3D
	var hooked_fish_mouth := casting_ui.get_node("../../HookedFishMouthMarker") as MeshInstance3D
	var lake_surface := casting_ui.get_node("../../LakeSurface") as LakeSurface
	var fight_water_reactions: Array = []
	lake_surface.reaction_requested.connect(
		func(reaction: LakeSurface.Reaction, world_position: Vector3, strength: float, radius: float) -> void:
			if reaction >= LakeSurface.Reaction.FIGHT_RECOVERY:
				fight_water_reactions.append([reaction, world_position, strength, radius])
	)
	if hook_marker.global_position.y >= spatial_casting.get("water_center").y:
		_fail("Hook should remain underwater during the interactive fight")
		return false
	if hooked_fish.global_position.y >= spatial_casting.get("water_center").y:
		_fail("Hooked fish should remain underwater during the interactive fight")
		return false
	if hooked_fish_mouth.global_position.distance_to(hook_marker.global_position) > 0.03:
		_fail("Hook should remain attached at the hooked fish mouth during the fight")
		return false
	var bluegill_mouth := hooked_fish.get_node_or_null("DockBluegill/FishMouthAnchor") as Node3D
	if bluegill_mouth == null or bluegill_mouth.global_position.distance_to(hook_marker.global_position) > 0.03:
		_fail("Hook should attach to the authored Dock Bluegill mouth anchor during the fight")
		return false
	if hooked_fish.get_node_or_null("DockBluegill") == null:
		_fail("Hooked-fish presentation should instance the approved Dock Bluegill asset")
		return false
	if spatial_casting.call("get_hooked_fish_animation") as StringName != &"calm_swim":
		_fail("Recovery should play the Dock Bluegill calm swimming animation")
		return false
	if not (spatial_casting.call("is_hooked_fish_silhouette") as bool):
		_fail("Early fight presentation should keep the Dock Bluegill as an underwater silhouette")
		return false
	cast_button.button_down.emit()
	await process_frame
	if cast_button.modulate == Color.WHITE:
		_fail("On-screen hold-to-reel input should visibly acknowledge its held state")
		return false
	cast_button.button_up.emit()
	await process_frame
	if cast_button.modulate != Color.WHITE:
		_fail("On-screen release should immediately return to yielding presentation")
		return false
	_push_action(&"set_hook", true)
	await process_frame
	if cast_button.modulate == Color.WHITE:
		_fail("Keyboard hold should use the same held presentation as the on-screen button")
		return false
	var saw_windup := false
	var saw_surge := false
	var saw_recovery_after_surge := false
	var active_phase := FishFightModel.Phase.RECOVERY
	var recovery_rod_offset := absf(float(spatial_casting.call("get_rod_cast_motion_offset")))
	var windup_fish_origin := Vector3.ZERO
	var surge_fish_origin := Vector3.ZERO
	var windup_fish_motion := 0.0
	var surge_fish_motion := 0.0
	var saw_landed_fish := false
	for frame in 220:
		await create_timer(0.05).timeout
		fight_snapshot = casting_ui.call("get_fight_snapshot") as Dictionary
		var phase := int(fight_snapshot.get("phase", FishFightModel.Phase.RECOVERY))
		var should_reel := phase == FishFightModel.Phase.RECOVERY
		if phase != active_phase:
			_push_action(&"set_hook", should_reel)
			active_phase = phase
		if phase == FishFightModel.Phase.SURGE_WINDUP:
			var first_windup_frame := not saw_windup
			if first_windup_frame:
				windup_fish_origin = hooked_fish.global_position
			saw_windup = true
			windup_fish_motion = maxf(windup_fish_motion, hooked_fish.global_position.distance_to(windup_fish_origin))
			if not tutorial_label.text.contains("release to yield"):
				_fail("The first surge wind-up should teach release-to-yield")
				return false
			if first_windup_frame and not (casting_ui.call("is_surge_cue_playing") as bool):
				_fail("A lightweight audio cue should accompany surge wind-up")
				return false
			if float(spatial_casting.call("get_line_overlay_width")) <= 1.35:
				_fail("Surge wind-up should visibly load the rod and fishing line")
				return false
			if absf(float(spatial_casting.call("get_rod_cast_motion_offset"))) <= recovery_rod_offset:
				_fail("Surge wind-up should visibly load the rod beyond recovery")
				return false
			if spatial_casting.call("get_hooked_fish_animation") as StringName != &"struggle_surge":
				_fail("Surge wind-up should switch the Dock Bluegill to its struggle animation")
				return false
		if phase == FishFightModel.Phase.SURGE:
			if not saw_surge:
				surge_fish_origin = hooked_fish.global_position
			saw_surge = true
			surge_fish_motion = maxf(surge_fish_motion, hooked_fish.global_position.distance_to(surge_fish_origin))
			if float(spatial_casting.call("get_line_overlay_width")) <= 1.85:
				_fail("A surge should intensify fish and fishing-line behavior beyond wind-up")
				return false
		if phase == FishFightModel.Phase.RECOVERY and saw_surge:
			saw_recovery_after_surge = true
		if state_label.text == "State: landed fish":
			saw_landed_fish = true
			if spatial_casting.call("get_hooked_fish_animation") as StringName != &"landed_presentation":
				_fail("Only the landed-fish presentation should play the Dock Bluegill landed animation")
				return false
			if inventory_label.text.contains("Dock Bluegill"):
				_fail("Catch must not be recorded before landed-fish presentation completes")
				return false
		if state_label.text == "State: result": break
	_push_action(&"set_hook", false)
	if not saw_windup or not saw_surge or not saw_recovery_after_surge:
		_fail("Playable fight should alternate through recovery, surge wind-up, surge, and recovery")
		return false
	if windup_fish_motion <= 0.005 or surge_fish_motion <= windup_fish_motion:
		_fail("Hooked-fish movement should visibly escalate from wind-up into surge")
		return false
	if not saw_landed_fish:
		_fail("Landing threshold should enter a distinct landed-fish presentation")
		return false
	var expected_water_reactions := [LakeSurface.Reaction.FIGHT_RECOVERY, LakeSurface.Reaction.SURGE_WINDUP, LakeSurface.Reaction.SURGE, LakeSurface.Reaction.LANDING]
	for reaction in expected_water_reactions:
		if not fight_water_reactions.any(func(entry: Array) -> bool: return entry[0] == reaction):
			_fail("Playable fight should request a semantic water reaction for %s" % LakeSurface.Reaction.keys()[reaction])
			return false
	var landing_reaction: Array = fight_water_reactions.filter(func(entry: Array) -> bool: return entry[0] == LakeSurface.Reaction.LANDING).back()
	if float(landing_reaction[2]) <= 0.9 or float(landing_reaction[3]) <= 1.0:
		_fail("Landing water feedback should be stronger and broader than the fight wake")
		return false
	var landing_reaction_count := fight_water_reactions.filter(func(entry: Array) -> bool: return entry[0] == LakeSurface.Reaction.LANDING).size()
	if (spatial_casting.call("get_line_endpoint") as Vector3).distance_to(endpoint_before_reeling) <= 0.2:
		_fail("Landing progress should move the hooked-fish presentation toward the rod")
		return false
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
	var inventory_before_loss := inventory_label.text
	var journal_label := casting_ui.get_node("LogPanel/Layout/JournalLabel") as Label
	casting_ui.call("configure_next_fight", {
		"recovery_only": false,
		"recovery_durations": [4.0],
		"windup_durations": [1.0],
		"surge_durations": [1.0],
		"surge_count": 1,
		"danger_window": 0.25,
	})
	cast_button.pressed.emit()
	for frame in 80:
		await create_timer(0.05).timeout
		if state_label.text == "State: bite": break
	_push_action(&"set_hook", true)
	_push_action(&"set_hook", false)
	var saw_slack_warning := false
	var saw_slack_pulse := false
	var saw_landed_presentation := false
	for frame in 120:
		await create_timer(0.05).timeout
		if state_label.text == "State: landed fish": saw_landed_presentation = true
		if tutorial_label.text.contains("throw the hook"): saw_slack_warning = true
		if tension_regions.get_node("Slack").modulate != Color.WHITE: saw_slack_pulse = true
		if state_label.text == "State: result": break
	if not saw_slack_warning or not saw_slack_pulse:
		_fail("Slack danger should show a cause-specific warning and pulse the slack gauge region")
		return false
	if saw_landed_presentation:
		_fail("A thrown hook should skip the landed-fish presentation")
		return false
	if fight_water_reactions.filter(func(entry: Array) -> bool: return entry[0] == LakeSurface.Reaction.LANDING).size() != landing_reaction_count:
		_fail("A thrown hook must not request successful landing water feedback")
		return false
	if not result_label.text.contains("thrown hook") or not message_label.text.contains("Reel during recovery"):
		_fail("Thrown-hook result should identify the cause and give a corrective hint")
		return false
	if not journal_label.text.contains("thrown hook"):
		_fail("Journal should distinguish a thrown hook from other outcomes")
		return false
	if inventory_label.text != inventory_before_loss:
		_fail("A thrown hook must not add inventory or consume existing catch records")
		return false
	for frame in 25:
		await create_timer(0.05).timeout
		if state_label.text == "State: ready": break
	if state_label.text != "State: ready" or cast_button.disabled:
		_fail("Thrown-hook result should return promptly to cast readiness")
		return false
	if hooked_fish.visible:
		_fail("A thrown hook should resolve the hooked Dock Bluegill without a landed presentation")
		return false
	var inventory_before_line_break := inventory_label.text
	casting_ui.call("configure_next_fight", {
		"recovery_only": false,
		"recovery_durations": [0.1],
		"windup_durations": [0.1],
		"surge_durations": [3.0],
		"surge_count": 1,
		"danger_window": 0.35,
	})
	cast_button.pressed.emit()
	for frame in 80:
		await create_timer(0.05).timeout
		if state_label.text == "State: bite": break
	_push_action(&"set_hook", true)
	_push_action(&"set_hook", false)
	for frame in 40:
		await create_timer(0.05).timeout
		if state_label.text == "State: reeling": break
	_push_action(&"set_hook", true)
	var saw_high_tension_danger := false
	var saw_high_tension_warning := false
	var saw_high_tension_pulse := false
	var saw_line_break_landed_presentation := false
	for frame in 60:
		await create_timer(0.05).timeout
		fight_snapshot = casting_ui.call("get_fight_snapshot") as Dictionary
		if float(fight_snapshot.get("high_tension_danger", 0.0)) > 0.0:
			saw_high_tension_danger = true
		if tutorial_label.text.contains("line may break"):
			saw_high_tension_warning = true
		if tension_regions.get_node("Excessive").modulate != Color.WHITE:
			saw_high_tension_pulse = true
		if saw_high_tension_danger and saw_high_tension_warning and saw_high_tension_pulse: break
	_push_action(&"set_hook", false)
	if not saw_high_tension_danger or not saw_high_tension_warning or not saw_high_tension_pulse:
		_fail("Line-break danger should accumulate visibly with a cause-specific warning and excessive-region pulse")
		return false
	for frame in 40:
		await create_timer(0.05).timeout
		fight_snapshot = casting_ui.call("get_fight_snapshot") as Dictionary
		if is_zero_approx(float(fight_snapshot.get("high_tension_danger", 0.0))): break
	if int(fight_snapshot.get("outcome", FishFightModel.Outcome.ONGOING)) != FishFightModel.Outcome.ONGOING:
		_fail("Yielding after brief excessive tension should keep the hooked fish playable")
		return false
	if not is_zero_approx(float(fight_snapshot.get("high_tension_danger", 0.0))):
		_fail("Yielding through the playable-world input should quickly drain line-break danger")
		return false
	await process_frame
	if tension_regions.get_node("Excessive").modulate != Color.WHITE:
		_fail("The excessive-tension pulse should clear after yielding back to safety")
		return false
	_push_action(&"set_hook", true)
	for frame in 120:
		await create_timer(0.05).timeout
		if state_label.text == "State: landed fish": saw_line_break_landed_presentation = true
		if state_label.text == "State: result": break
	_push_action(&"set_hook", false)
	if saw_line_break_landed_presentation:
		_fail("A line break should skip the landed-fish presentation")
		return false
	if fight_water_reactions.filter(func(entry: Array) -> bool: return entry[0] == LakeSurface.Reaction.LANDING).size() != landing_reaction_count:
		_fail("A line break must not request successful landing water feedback")
		return false
	if not result_label.text.contains("line break") or not message_label.text.contains("Yield sooner"):
		_fail("Line-break result should identify the cause and give a corrective hint")
		return false
	if not journal_label.text.contains("line break"):
		_fail("Journal should distinguish a line break from other outcomes")
		return false
	if inventory_label.text != inventory_before_line_break:
		_fail("A line break must not add inventory or consume existing catch records")
		return false
	for frame in 25:
		await create_timer(0.05).timeout
		if state_label.text == "State: ready": break
	if state_label.text != "State: ready" or cast_button.disabled:
		_fail("Line-break result should return promptly to cast readiness")
		return false
	if hooked_fish.visible:
		_fail("A line break should resolve the hooked Dock Bluegill without a landed presentation")
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

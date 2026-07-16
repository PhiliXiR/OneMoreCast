extends SceneTree

const WORLD_SCENE := preload("res://scenes/world_prototype.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	var lens := world.get_node_or_null("CinematicWaterLens")
	var panel := world.get_node_or_null("CastingUILayer/CastingUI/WaterLens") as Control
	var texture := world.get_node_or_null("CastingUILayer/CastingUI/WaterLens/Texture") as TextureRect
	var hud := world.get_node_or_null("CastingUILayer/CastingUI")
	var spatial := world.get_node_or_null("SpatialCasting")
	if lens == null or panel == null or texture == null or hud == null or spatial == null:
		_fail("Water Lens validation requires the live world lens and casting UI")
		return
	if texture.texture != lens.get_node("SubViewport").get_texture():
		_fail("Water Lens must display the live SubViewport render texture")
		return
	if panel.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("Water Lens must not intercept Reel or Yield interaction")
		return
	if lens.call("get_shot_policy_names") != ["water read", "line pull", "landing focus"]:
		_fail("Water Read, Line Pull, and Landing Focus must be selectable shot policies")
		return
	var shared_snapshot := {"phase": FishFightModel.Phase.RECOVERY, "landing_progress": 0.5}
	for fixture in ["recovery", "surge", "line break", "thrown hook", "landed fish"]:
		for policy in lens.call("get_shot_policy_names"):
			hud.call("start_playtest_fixture", fixture, policy)
			var fixture_configuration := hud.get("next_fight_configuration") as Dictionary
			if String(fixture_configuration.get("water_lens_shot_policy", "")) != policy:
				_fail("%s fixture must select the %s Water Lens policy" % [fixture, policy])
				return
			hud.call("_begin_fight")
			lens.call("apply_fight_snapshot", shared_snapshot)
			if lens.call("get_active_shot_policy_name") != policy:
				_fail("%s fixture must apply the selected %s Water Lens policy" % [fixture, policy])
				return

	var expected_shots := {"water read": "wide", "line pull": "pursuit", "landing focus": "landing"}
	for policy in expected_shots:
		lens.call("set_shot_policy", policy)
		lens.call("begin_fight")
		lens.call("apply_fight_snapshot", shared_snapshot)
		if lens.call("get_active_shot_policy_name") != policy or lens.call("get_active_shot_name") != expected_shots[policy]:
			_fail("%s must select its distinct active shot for the same fight state" % policy.capitalize())
			return
	lens.call("set_shot_policy", "line pull")

	spatial.set("last_landing_quality", 0.8)
	spatial.set("_phase", 3) # SpatialCastingController.CastPhase.LANDED_TAUT
	if not spatial.call("begin_reel_feedback"):
		_fail("A successful hook set must begin the live fight presentation")
		return
	if not panel.visible or lens.call("get_active_shot_name") != "wide":
		_fail("A successful hook set must open the Water Lens on a wide shot")
		return
	hud.set("state", 4) # CastingController.CastState.REELING
	var reel_input := InputEventAction.new()
	reel_input.action = &"set_hook"
	reel_input.pressed = true
	hud.call("_input", reel_input)
	if not bool(hud.get("reel_held")):
		_fail("Reel input must remain usable while the Water Lens is visible")
		return
	reel_input.pressed = false
	hud.call("_input", reel_input)
	lens.call("apply_fight_snapshot", {"phase": FishFightModel.Phase.RECOVERY, "landing_progress": 0.2})
	if lens.call("get_active_shot_name") != "pursuit":
		_fail("Recovery must move the Water Lens to a pursuit shot")
		return
	lens.call("apply_fight_snapshot", {"phase": FishFightModel.Phase.SURGE, "landing_progress": 0.45})
	if lens.call("get_active_shot_name") != "close-up":
		_fail("A surge must move the Water Lens to a close-up shot")
		return

	lens.call("begin_fight")
	await hud.call("_finish_landed_fish")
	if panel.visible or not (hud.get_node("OutcomeCard") as Control).visible:
		_fail("Water Lens must close before the landed-fish outcome")
		return
	hud.call("_dismiss_outcome_card")
	lens.call("begin_fight")
	hud.call("_finish_fight_loss", FishFightModel.Outcome.LINE_BREAK)
	if panel.visible or not (hud.get_node("OutcomeCard") as Control).visible:
		_fail("Water Lens must close before the lost-fish outcome")
		return
	print("Water Lens validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

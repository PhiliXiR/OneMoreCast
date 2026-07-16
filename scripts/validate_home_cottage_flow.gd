extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const INTERIOR_ENTRY := Vector3(28.0, 0.12, -198.1)
const INTERIOR_EXIT := Vector3(28.0, 0.12, -202.45)


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	var flow := world.get_node_or_null("HomeCottageFlow") as Node
	var player := world.get_node_or_null("PlayerRig") as CharacterBody3D
	var casting_ui := world.get_node_or_null("CastingUILayer/CastingUI") as Node
	var camera := world.get_node_or_null("MMOCameraRig") as Node
	if flow == null or player == null or casting_ui == null or camera == null:
		_fail("Home Cottage flow needs player, camera, fishing, and routing seams")
		return
	if flow.get_node_or_null("HomeCottageInterior") == null or not flow.get_node("HomeCottageInterior").get_meta("roofless", false):
		_fail("Home Cottage requires a readable roofless runtime interior")
		return
	player.global_position = flow.get_porch_position()
	await process_frame
	if not flow.try_handle_interact():
		_fail("Porch interaction should be handled")
		return
	await create_timer(0.3).timeout
	if not flow.call("is_inside_home_cottage") or player.global_position.distance_to(INTERIOR_ENTRY) > 0.35:
		_fail("Settled fishing should enter the compact Home Cottage interior (inside=%s position=%s)" % [flow.call("is_inside_home_cottage"), player.global_position])
		return
	if float(camera.call("get_preferred_distance")) > 3.5:
		_fail("Interior should use a closer camera profile")
		return
	player.global_position = INTERIOR_EXIT
	flow.try_handle_interact()
	await create_timer(0.3).timeout
	if flow.call("is_inside_home_cottage") or _horizontal_distance(player.global_position, flow.call("get_porch_position") as Vector3) > 0.1:
		_fail("Interior exit should return the player to the porch (inside=%s position=%s)" % [flow.call("is_inside_home_cottage"), player.global_position])
		return
	casting_ui.call("record_observation", "fish sign", "A wake crossed the dock shallows.")
	var observation_before := casting_ui.call("get_latest_observation") as Dictionary
	for active_state in [1, 3, 4]:
		casting_ui.set("state", active_state)
		player.global_position = flow.call("get_porch_position") as Vector3
		var interact := InputEventAction.new()
		interact.action = &"set_hook"
		interact.pressed = true
		casting_ui.call("_input", interact)
		if flow.call("is_inside_home_cottage") or int(casting_ui.get("state")) != active_state or casting_ui.call("get_latest_observation") != observation_before:
			_fail("Active fishing state %s should block entry while preserving fishing and observation data" % active_state)
			return
	print("Home Cottage flow validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

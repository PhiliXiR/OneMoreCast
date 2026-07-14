extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const HUD_SCENE := preload("res://scenes/main.tscn")
const VIEWPORTS := [Vector2i(1920, 1080), Vector2i(390, 844)]


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load(WORLD_SCENE) as PackedScene
	if packed_scene == null:
		_fail("Could not load %s" % WORLD_SCENE)
		return
	var world := packed_scene.instantiate()
	root.add_child(world)
	await process_frame

	var presentation := world.get_node_or_null("HomeWater/Presentation") as HomeWaterPresentation
	var spatial := world.get_node_or_null("SpatialCasting") as Node
	if presentation == null or spatial == null:
		_fail("Environmental-life validation needs the home water and fishing seams")
		return
	if not presentation.has_quiet_environmental_life():
		_fail("Home water needs sparse reed, smoke, and bird environmental life")
		return
	var life := presentation.get_node_or_null(HomeWaterPresentation.ENVIRONMENTAL_LIFE_NAME) as Node3D
	if life == null or life.get_meta("interactive", true) or _has_collision_shape(life):
		_fail("Environmental life must remain decorative and non-blocking")
		return

	var reed := presentation.get_node_or_null("OpenWaterLandmarks/ReedIsland/Reed00") as MeshInstance3D
	var smoke := life.get_node_or_null("CottageSmoke/SmokePuff00") as MeshInstance3D
	if reed == null or smoke == null:
		_fail("Environmental life needs its authored motion anchors")
		return
	var reed_before := reed.rotation.z
	var smoke_before := smoke.position
	await create_timer(0.4).timeout
	if is_equal_approx(reed.rotation.z, reed_before) or smoke.position.is_equal_approx(smoke_before):
		_fail("Environmental life should move quietly without fishing input")
		return

	presentation.set_reduced_motion(true)
	var reduced_reed := reed.rotation.z
	var reduced_smoke := smoke.position
	await create_timer(0.3).timeout
	if presentation.is_environmental_motion_active() or not is_equal_approx(reed.rotation.z, reduced_reed) or not smoke.position.is_equal_approx(reduced_smoke):
		_fail("Reduced motion must freeze decorative environmental movement")
		return

	var target := world.get_node_or_null("CastTargetMarker") as Node3D
	spatial.call("refresh_casting_visuals", 0.0)
	if target == null or not target.visible:
		_fail("Environmental life must not replace the readable cast target")
		return
	# Compact layouts retain the same game-world focal point; their HUD is
	# separately covered by validate_responsive_hud.gd. The environmental layer
	# is entirely outside this action seam, so verify an active cast still keeps
	# its tackle and UI presentation alive.
	spatial.call("begin_cast")
	for frame in 11:
		spatial.call("refresh_casting_visuals", 0.08)
	var line := world.get_node_or_null("LineOverlayLayer/FishingLineOverlay") as Line2D
	var casting_ui := world.get_node_or_null("CastingUILayer/CastingUI") as CanvasItem
	if line == null or casting_ui == null or not line.visible or not casting_ui.visible:
		_fail("Desktop and compact fishing presentations must retain tackle and HUD readability")
		return
	if not await _validate_completed_viewports():
		return

	print("Environmental life and fishing readability validation passed")
	quit(0)


func _validate_completed_viewports() -> bool:
	for viewport_size in VIEWPORTS:
		root.content_scale_size = viewport_size
		var hud := HUD_SCENE.instantiate() as Control
		root.add_child(hud)
		hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
		hud.size = Vector2(viewport_size)
		await process_frame
		var action_panel := hud.get_node("ActionPanel") as Control
		var cast_button := hud.get_node("ActionPanel/Layout/CastButton") as Button
		if not _inside_viewport(action_panel, viewport_size) or not _inside(action_panel, cast_button):
			_fail("Completed home-water view must retain its active fishing control at %s" % viewport_size)
			return false
		root.remove_child(hud)
		hud.queue_free()
	return true


func _has_collision_shape(node: Node) -> bool:
	if node is CollisionShape3D:
		return true
	for child in node.get_children():
		if _has_collision_shape(child):
			return true
	return false


func _inside_viewport(control: Control, viewport_size: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y


func _inside(parent: Control, child: Control) -> bool:
	var parent_rect := parent.get_global_rect()
	var child_rect := child.get_global_rect()
	return child_rect.position.x >= parent_rect.position.x and child_rect.position.y >= parent_rect.position.y and child_rect.end.x <= parent_rect.end.x and child_rect.end.y <= parent_rect.end.y


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

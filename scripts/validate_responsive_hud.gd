extends SceneTree

const HUD_SCENE := preload("res://scenes/main.tscn")
const VIEWPORTS := [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(390, 844)]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in VIEWPORTS:
		await _validate_viewport(viewport_size)
	print("Responsive HUD layout validation passed")
	quit(0)


func _validate_viewport(viewport_size: Vector2i) -> void:
	root.content_scale_size = viewport_size
	var hud := HUD_SCENE.instantiate() as Control
	root.add_child(hud)
	hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud.size = Vector2(viewport_size)
	await process_frame
	await process_frame
	var action_panel := hud.get_node("ActionPanel") as Control
	var log_panel := hud.get_node("LogPanel") as Control
	var home_panel := hud.get_node("HomePanel") as Control
	var drawer_toggle := hud.get_node("DrawerToggleButton") as Button
	var prompt := hud.get_node("ActionPanel/Layout/PromptLabel") as Label
	var cast_button := hud.get_node("ActionPanel/Layout/CastButton") as Button
	var meter_button := hud.get_node("LogPanel/Scroll/Layout/AccessibilityMeterButton") as Button
	if not _inside_viewport(action_panel, viewport_size) or not _inside(action_panel, prompt) or not _inside(action_panel, cast_button):
		_fail("Active fishing prompt or control leaves its panel at %s" % viewport_size)
		return
	if viewport_size == Vector2i(1920, 1080):
		if drawer_toggle.visible or not log_panel.visible or not home_panel.visible:
			_fail("Desktop must keep journal and community controls reachable without the drawer")
			return
		if _overlaps(action_panel, log_panel) or _overlaps(action_panel, home_panel) or _overlaps(log_panel, home_panel):
			_fail("Desktop HUD panels overlap")
			return
	else:
		if not drawer_toggle.visible or not _inside_viewport(drawer_toggle, viewport_size) or _overlaps(action_panel, drawer_toggle) or log_panel.visible or home_panel.visible:
			_fail("Compact HUD must move secondary controls into a closed drawer")
			return
		drawer_toggle.pressed.emit()
		await process_frame
		if not log_panel.visible or home_panel.visible or not meter_button.visible:
			_fail("Journal drawer must expose its controls, including the accessibility meter")
			return
		var log_scroll := hud.get_node("LogPanel/Scroll") as ScrollContainer
		log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)
		await process_frame
		if not _inside(log_panel, meter_button):
			_fail("Accessibility meter must be reachable by scrolling the journal drawer")
			return
		if _overlaps(action_panel, log_panel):
			_fail("Journal drawer overlaps the active fishing prompt at %s: %s / %s" % [viewport_size, log_panel.get_global_rect(), action_panel.get_global_rect()])
			return
		hud.get_node("CommunityDrawerTab").pressed.emit()
		await process_frame
		if not home_panel.visible or log_panel.visible or _overlaps(action_panel, home_panel):
			_fail("Community drawer must remain separate from the active fishing prompt at %s" % viewport_size)
			return
	root.remove_child(hud)
	hud.queue_free()


func _inside_viewport(control: Control, viewport_size: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y


func _overlaps(first: Control, second: Control) -> bool:
	return first.get_global_rect().intersects(second.get_global_rect())


func _inside(parent: Control, child: Control) -> bool:
	var parent_rect := parent.get_global_rect()
	var child_rect := child.get_global_rect()
	return child_rect.position.x >= parent_rect.position.x and child_rect.position.y >= parent_rect.position.y and child_rect.end.x <= parent_rect.end.x and child_rect.end.y <= parent_rect.end.y


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

extends SceneTree

const WORLD_SCENE := preload("res://scenes/world_prototype.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	var hud := world.get_node("CastingUILayer/CastingUI")
	for fixture in ["recovery", "surge", "line break", "thrown hook", "landed fish"]:
		hud.call("start_playtest_fixture", fixture)
		if (hud.get("next_fight_configuration") as Dictionary).is_empty():
			_fail("Missing repeatable developer fixture: %s" % fixture)
			return
	var gauge := hud.get_node("ActionPanel/Layout/TensionGauge") as ProgressBar
	var readout := hud.get_node("ActionPanel/Layout/FightReadout") as Label
	if gauge.visible or readout.visible:
		_fail("Default HUD must not expose a permanent tension meter or playtest values")
		return
	hud.call("set_accessibility_tension_meter_enabled", true)
	hud.call("set_playtest_readout_enabled", true)
	hud.call("configure_next_fight", {"recovery_only": true, "recovery_reel_rate": 0.1})
	hud.call("_begin_fight")
	await process_frame
	if not gauge.visible or not readout.visible or not readout.text.contains("tension"):
		_fail("Opt-in accessibility meter and playtest readout must expose their distinct information")
		return
	var prompt := hud.get_node("ActionPanel/Layout/PromptLabel") as Label
	if not prompt.text.contains("REEL"):
		_fail("Recovery must teach the contextual Reel action")
		return
	var fight := hud.get("fight_model") as FishFightModel
	fight.start({"recovery_durations": [0.01], "windup_durations": [0.01], "surge_durations": [1.0], "danger_window": 2.0})
	hud.set("fight_snapshot", fight.advance(0.02, true))
	hud.call("_present_fight")
	if not prompt.text.contains("YIELD"):
		_fail("Surge must teach the contextual Yield action")
		return
	print("Fight feedback validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

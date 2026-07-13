extends SceneTree

const WORLD_SCENE := preload("res://scenes/world_prototype.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	var hud := world.get_node_or_null("CastingUILayer/CastingUI")
	if hud == null:
		_fail("Fishing outcome validation requires the casting UI")
		return

	await hud.call("_finish_landed_fish")
	var outcome_card := hud.get_node("OutcomeCard") as Control
	var details := hud.get_node("OutcomeCard/Layout/Details") as Label
	if not outcome_card.visible or not details.text.contains("Dock Bluegill") or not details.text.contains("lb"):
		_fail("A landed fish needs a concise species and weight outcome card")
		return
	if not details.text.contains("presentation") and not details.text.contains("lure rig"):
		_fail("The landed-fish card must retain fishing conditions")
		return
	hud.call("_resolve_landed_fish", 1) # LandedFishAction.RELEASE
	var released_observation := hud.call("get_latest_observation") as Dictionary
	if String(released_observation.get("kind", "")) != "catch" or not (hud.get("inventory") as Dictionary).is_empty():
		_fail("Release must record the catch without adding it to the temporary outing catch list")
		return

	await hud.call("_finish_landed_fish")
	hud.call("_resolve_landed_fish", 0) # LandedFishAction.KEEP
	if int((hud.get("inventory") as Dictionary).get("Dock Bluegill", 0)) != 1:
		_fail("Keep must add the landed fish to the temporary outing catch list")
		return

	await hud.call("_finish_fight_loss", FishFightModel.Outcome.LINE_BREAK)
	var loss_title := hud.get_node("OutcomeCard/Layout/Title") as Label
	var fish_again := hud.get_node("OutcomeCard/Layout/FishAgainButton") as Button
	if not outcome_card.visible or not loss_title.text.contains("Line break") or not fish_again.visible:
		_fail("A line break needs a cause-specific Fish Again outcome card")
		return
	var loss_observation := hud.call("get_latest_observation") as Dictionary
	if String(loss_observation.get("kind", "")) != "line break" or not String(loss_observation.get("lesson", "")).contains("Yield sooner"):
		_fail("A line break must record its corrective lesson")
		return
	hud.call("_dismiss_outcome_card")
	await hud.call("_finish_fight_loss", FishFightModel.Outcome.THROWN_HOOK)
	var hook_observation := hud.call("get_latest_observation") as Dictionary
	if String(hook_observation.get("kind", "")) != "thrown hook" or not String(hook_observation.get("lesson", "")).contains("Reel during recovery"):
		_fail("A thrown hook must receive its own corrective observation")
		return
	if not (hud.get_node("OutcomeCard/Layout/FishAgainButton") as Button).visible:
		_fail("A thrown hook needs a Fish Again action")
		return
	hud.call("_dismiss_outcome_card")
	hud.call("_toggle_field_journal")
	var journal_menu := hud.get_node("FieldJournalMenu") as Control
	var observations := hud.get_node("FieldJournalMenu/Layout/Observations") as Label
	if not journal_menu.visible or not observations.text.contains("Thrown hook") or not observations.text.contains("Line break") or observations.text.find("Thrown hook") > observations.text.find("Line break"):
		_fail("The field-journal menu must show latest-first observations")
		return
	hud.call("_on_journal_return_home_pressed")
	var return_button := hud.get_node("FieldJournalMenu/Layout/ReturnHomeButton") as Button
	if return_button.text != "Confirm Return Home":
		_fail("Return home must summarize the latest observation before confirmation")
		return
	hud.call("_on_journal_return_home_pressed")
	if not return_button.disabled:
		_fail("An observation-gated return home must complete only after confirmation")
		return
	print("Fishing outcome and field-journal validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

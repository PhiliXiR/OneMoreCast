extends SceneTree

const FieldJournalScript = preload("res://journal/field_journal.gd")
const HomeCommunityScript = preload("res://community/home_community.gd")
const WORLD_SCENE := "res://scenes/world_prototype.tscn"


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var journal := FieldJournalScript.new()
	var observation := journal.record(
		"catch",
		{"micro_habitat": "vegetated inlet", "time_of_day": "early morning", "presentation": "lure rig"},
		"Caught Dock Bluegill (0.7 lb).",
		"This presentation can produce a Dock Bluegill here."
	)
	var community := HomeCommunityScript.new()
	var return_beat := community.return_from_outing(observation, "early morning", HomeCommunityScript.Disposition.HELP) as Dictionary
	if String(return_beat.get("local_need_response", "")).is_empty():
		_fail("A catch should receive a visible local-need response at home")
		return
	if String(return_beat.get("journal_disposition", "")) != "retained as field-journal evidence":
		_fail("A recorded observation must remain meaningful field-journal evidence after returning home")
		return
	var mystery_clues := return_beat.get("watershed_mystery_clues", []) as Array
	if mystery_clues.size() != 2 or String(mystery_clues[0]) == String(mystery_clues[1]):
		_fail("Returning home must reveal two incomplete, conflicting watershed-mystery accounts")
		return
	if String(return_beat.get("next_time_of_day", "")) != "late afternoon":
		_fail("The return-home beat should advance local context without a maintenance chore")
		return
	if not String(community.get_relationship_summary()).contains("Mara"):
		_fail("Helping with a catch should change a recurring relationship")
		return
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	var casting_ui := world.get_node_or_null("CastingUILayer/CastingUI")
	var home_water := world.get_node_or_null("HomeWater")
	if casting_ui == null or home_water == null or not casting_ui.has_method("return_home_with_latest_observation"):
		_fail("The playable fishing UI must expose the return-home beat")
		return
	casting_ui.field_journal.record("catch", casting_ui._provider_conditions(), "Caught Dock Bluegill (0.7 lb).")
	var visible_response := String(casting_ui.call("return_home_with_latest_observation", HomeCommunityScript.Disposition.HELP))
	if not visible_response.contains("Mara") or not visible_response.contains("Aunt Sable") or not visible_response.contains("Eli"):
		_fail("The player-visible return-home response must include all three recurring home-community perspectives")
		return
	if not visible_response.contains(String(mystery_clues[0])) or not visible_response.contains(String(mystery_clues[1])):
		_fail("The player-visible return-home response must include both conflicting watershed-mystery clues")
		return
	if String(home_water.call("get_fishing_conditions")["time_of_day"]) != "late afternoon":
		_fail("Returning home through the playable UI must advance the home-water context")
		return
	print("Return-home story validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

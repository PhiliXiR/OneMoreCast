extends SceneTree

## Behavior-focused proof of the compact foundation's first complete loop.
## Physical casting and fish-fight behavior remain covered by their focused
## validations; this asserts the player-facing integration between them.

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const HomeCommunityScript = preload("res://community/home_community.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	var player := world.get_node_or_null("PlayerRig") as Node3D
	var home_water := world.get_node_or_null("HomeWater")
	var casting_ui := world.get_node_or_null("CastingUILayer/CastingUI")
	if player == null or home_water == null or casting_ui == null:
		_fail("The first complete loop requires the player, home water, and casting UI")
		return
	if not String(casting_ui.message_label.text).contains("Mara needs a read"):
		_fail("A new player must receive the local need in the playable briefing")
		return
	if not String(casting_ui.message_label.text).contains("working dock shallows") or not String(casting_ui.message_label.text).contains("vegetated inlet"):
		_fail("The playable briefing must name two viable micro-habitats and their visible cues")
		return

	player.global_position = Vector3(0.0, 0.1, -2.0)
	var dock_conditions := home_water.call("get_fishing_conditions") as Dictionary
	player.global_position = Vector3(7.0, 0.1, -2.0)
	var inlet_conditions := home_water.call("get_fishing_conditions") as Dictionary
	if String(dock_conditions["micro_habitat"]) == String(inlet_conditions["micro_habitat"]):
		_fail("Moving between visible home-water cues must produce a meaningful micro-habitat choice")
		return

	casting_ui.call("_record_observation", "catch", "Caught Dock Bluegill (0.7 lb).", "The lure rig can produce Dock Bluegill beside the reeds.")
	var catch_observation := casting_ui.field_journal.latest() as Dictionary
	if String(catch_observation["kind"]) != "catch" or String(catch_observation["micro_habitat"]) != "vegetated inlet":
		_fail("A landed-fish outcome must record the selected fishing conditions in the field journal")
		return
	var catch_return := String(casting_ui.call("return_home_with_latest_observation", HomeCommunityScript.Disposition.HELP))
	if not catch_return.contains("Mara") or not catch_return.contains("Aunt Sable") or not catch_return.contains("Eli"):
		_fail("Returning from a landed fish must produce the contextual home-community response")
		return
	if not catch_return.contains("mill dam") or not catch_return.contains("nothing passes it now"):
		_fail("The first return must deliver the contradictory watershed-mystery clue")
		return

	casting_ui.call("_record_observation", "thrown hook", "Lost the hooked fish after allowing line slack during recovery.", "Reel during recovery to prevent line slack.")
	var loss_observation := casting_ui.field_journal.latest() as Dictionary
	if String(loss_observation["kind"]) != "thrown hook" or not String(loss_observation["lesson"]).contains("Reel during recovery"):
		_fail("An instructive-loss outcome must preserve its cause-specific lesson in the field journal")
		return
	var loss_return := String(casting_ui.call("return_home_with_latest_observation", HomeCommunityScript.Disposition.RETAIN))
	if not loss_return.contains("Mara"):
		_fail("An instructive loss must remain meaningful when returning home")
		return
	if String(home_water.call("get_fishing_conditions")["time_of_day"]) != "early morning":
		_fail("Two returns must advance local context without adding a maintenance loop")
		return
	print("First complete home-water loop validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

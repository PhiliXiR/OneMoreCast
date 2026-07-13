extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(world)
	var provider := world.get_node("HomeWater")
	var player := world.get_node("PlayerRig") as Node3D
	if world.get_node_or_null("HomeWater/DeepRockyFarBank/RockShelfOne") == null:
		_fail("The deep rocky far bank must have a visible landmark")
	if String(provider.call("get_fishing_conditions")["presentation"]) != "lure rig":
		_fail("The lure rig must remain the starting presentation")
	if not String(provider.call("travel_to_far_bank")).contains("not marked"):
		_fail("The far bank must require learned access")
	var field_note := provider.call("inspect_lure_evidence", {"kind": "lure-focused sign"}) as String
	if not field_note.contains("bottom rig") or not field_note.contains("far bank"):
		_fail("Journal evidence must point to both the new presentation and far-bank route")
	if not String(provider.call("cycle_presentation")).begins_with("Bottom rig selected"):
		_fail("The unlocked presentation must explain its deep-rock purpose")
	provider.call("travel_to_far_bank")
	if player.global_position.x > -6.0:
		_fail("The learned route must move the player to the deep rocky far bank")
	var conditions := provider.call("get_fishing_conditions") as Dictionary
	if String(conditions["micro_habitat"]) != "deep rocky far bank" or String(conditions["presentation"]) != "bottom rig":
		_fail("The resulting choice must be observable in the fishing conditions")
	var response := provider.call("get_fish_presence_response") as Dictionary
	if float(response["bite_wait_multiplier"]) >= 1.0 or String(provider.call("get_hooked_fish")["name"]) != "Rock Bass":
		_fail("Bottom-rig fishing at the far bank must produce a distinct authored result")
	var preferences := provider.call("get_species_preferences") as Dictionary
	if not (preferences["Dock Bluegill"]["times"] as Array).has("early morning") or not (preferences["Rock Bass"]["times"] as Array).has("early morning"):
		_fail("Species preferences must overlap at a readable time of day")
	if not String(provider.call("cycle_presentation")).begins_with("Lure rig selected"):
		_fail("Presentations must remain sidegrades rather than a linear replacement")
	print("Knowledge-and-access progression validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

class_name HomeCommunity
extends RefCounted

## Keeps the compact home-community return beat game-owned and separate from
## physical fishing. Its small public surface accepts one recorded observation
## and returns the player-visible consequences of coming home with it.

var mara_helped := false
var outings_shared := 0

enum Disposition { SHARE, RETAIN, HELP }

const RECURRING_INTERACTIONS := [
	{
		"name": "Mara Vale",
		"role": "local need",
		"summary": "Keeps the dockside supper going while her father mends the public landing.",
	},
	{
		"name": "Eli Rowan",
		"role": "fieldcraft",
		"summary": "Trades practical notes about presentations, cover, and the safe shore path.",
	},
	{
		"name": "Aunt Sable",
		"role": "local stories",
		"summary": "Keeps the old lake accounts and notices what the water has changed.",
	},
]

const WATERSHED_MYSTERY_CLUES := [
	"Aunt Sable says the long silver fish still passes the mill dam every spring.",
	"Eli insists the dam sealed that run before he was born; nothing passes it now.",
]


func begin_first_outing() -> String:
	return "Mara needs a read on the home water for the dockside supper. Start at the working dock shallows, or walk east to the vegetated inlet: dock posts mark open shallows; reeds mark sheltered water. Record what the lure rig tells you, then bring the observation home."


func get_recurring_interactions() -> Array[Dictionary]:
	var interactions: Array[Dictionary] = []
	for interaction in RECURRING_INTERACTIONS:
		interactions.append((interaction as Dictionary).duplicate(true))
	return interactions


func get_available_dispositions(observation: Dictionary) -> Array[int]:
	var dispositions: Array[int] = [Disposition.RETAIN, Disposition.SHARE]
	if String(observation.get("kind", "")) == "catch":
		dispositions.append(Disposition.HELP)
	return dispositions


func return_from_outing(observation: Dictionary, current_time_of_day: String, disposition := Disposition.SHARE) -> Dictionary:
	var next_time := "late afternoon" if current_time_of_day == "early morning" else "early morning"
	var observation_kind := String(observation.get("kind", "observation"))
	var local_need_response := "Mara reads the note and asks you to keep watching the dock shallows while the landing is repaired."
	var catch_disposition := "shared as an observation"
	if disposition == Disposition.HELP and observation_kind == "catch":
		mara_helped = true
		local_need_response = "Mara sets the Dock Bluegill aside for the dockside supper and trusts you with tomorrow's check on the public landing."
		catch_disposition = "used to help Mara"
	elif disposition == Disposition.RETAIN:
		local_need_response = "Mara asks you to keep the record close; the dock shallows may say more tomorrow."
		catch_disposition = "retained with the field-journal evidence"
	outings_shared += 1
	return {
		"local_need_response": local_need_response,
		"fieldcraft_response": "Eli marks the %s in your field journal: conditions first, then another careful cast." % String(observation.get("micro_habitat", "home water")),
		"local_story_response": "Aunt Sable hears the account, then offers two versions of the same old fish story.",
		"watershed_mystery_clues": WATERSHED_MYSTERY_CLUES.duplicate(),
		"journal_disposition": "retained as field-journal evidence",
		"catch_disposition": catch_disposition,
		"next_time_of_day": next_time,
		"local_context": "The dock lamps come on; the next outing will begin in %s." % next_time,
	}


func get_relationship_summary() -> String:
	var mara_status := "Mara trusts you with the public-landing check." if mara_helped else "Mara still needs help keeping the dockside supper going."
	return "Mara: %s Eli: %d outing note%s shared. Aunt Sable is waiting by the lamps." % [
		mara_status,
		outings_shared,
		"" if outings_shared == 1 else "s",
	]

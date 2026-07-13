extends Node3D

## Owns the player-facing fishing conditions for the home water.  Casting asks
## this provider for context, but continues to own the physical cast and fight.

@export var player_path: NodePath
@export var time_of_day := "early morning"
@export var inlet_start_x := 6.0
@export var far_bank_end_x := -6.0
@export var far_bank_arrival := Vector3(-7.4, 0.1, -2.0)

@onready var player: Node3D = get_node_or_null(player_path) as Node3D

var selected_presentation := "lure rig"
var bottom_rig_known := false
var far_bank_reachable := false

const SPECIES_PREFERENCES := {
	"Dock Bluegill": {
		"micro_habitats": ["working dock shallows", "vegetated inlet", "deep rocky far bank"],
		"presentations": ["lure rig", "bottom rig"],
		"times": ["early morning", "day"],
		"weight": 0.7,
	},
	"Rock Bass": {
		"micro_habitats": ["deep rocky far bank", "working dock shallows"],
		"presentations": ["bottom rig", "lure rig"],
		"times": ["early morning", "late afternoon"],
		"weight": 1.2,
	},
}


func get_fishing_conditions() -> Dictionary:
	var habitat := _micro_habitat()
	var cue := "dark drop-off and exposed rock shelves" if habitat == "deep rocky far bank" else ("reeds and sheltered water" if habitat == "vegetated inlet" else "dock posts and open shallows")
	return {
		"micro_habitat": habitat,
		"time_of_day": time_of_day,
		"presentation": selected_presentation,
		"visible_cue": cue,
	}


func inspect_lure_evidence(observation: Dictionary) -> String:
	var kind := String(observation.get("kind", ""))
	if not bottom_rig_known and kind in ["fish sign", "lure-focused sign", "bite", "catch"]:
		bottom_rig_known = true
		far_bank_reachable = true
		return "Field note: the lively shallows respond to a moving lure. For the deep rocky far bank, pack the bottom rig and follow the newly marked shore path."
	if far_bank_reachable:
		return "Field note: the marked shore path reaches the deep rocky far bank. A bottom rig can stay near the rocks; the lure rig still works best for moving fish in the shallows."
	return "Record a lure-focused fish sign, bite, or catch, then inspect it for a field note."


func cycle_presentation() -> String:
	if not bottom_rig_known:
		return "Only the lure rig is ready. Inspect a lure observation to learn the next presentation."
	selected_presentation = "bottom rig" if selected_presentation == "lure rig" else "lure rig"
	return "Bottom rig selected — let it settle and hold near rocks for fish feeding deep." if selected_presentation == "bottom rig" else "Lure rig selected — retrieve it through active shallows to draw moving fish."


func travel_to_far_bank() -> String:
	if not far_bank_reachable:
		return "The far-bank shore path is not marked yet. Inspect a useful lure observation first."
	if player != null:
		player.global_position = far_bank_arrival
	return "You follow the marked shore path to the deep rocky far bank."


func get_hooked_fish() -> Dictionary:
	var rock_bass_score := _species_score("Rock Bass")
	var bluegill_score := _species_score("Dock Bluegill")
	var name := "Rock Bass" if rock_bass_score > bluegill_score else "Dock Bluegill"
	return {"name": name, "weight": float(SPECIES_PREFERENCES[name]["weight"])}


func get_species_preferences() -> Dictionary:
	return SPECIES_PREFERENCES.duplicate(true)


func get_condition_summary() -> String:
	var conditions := get_fishing_conditions()
	return "%s · %s · %s" % [
		String(conditions["micro_habitat"]).capitalize(),
		String(conditions["time_of_day"]),
		String(conditions["presentation"]),
	]


## This is readable authored behavior, not a hidden catch table.  It controls
## only the frequency and character of pre-hook evidence at each micro-habitat.
func get_fish_presence_response() -> Dictionary:
	if _micro_habitat() == "deep rocky far bank":
		var using_bottom := selected_presentation == "bottom rig"
		var morning_bonus := 0.08 if time_of_day == "early morning" else -0.08
		return {
			"ambient_interval": 1.5 if using_bottom else 2.5,
			"ambient_strength": 0.78 if using_bottom else 0.42,
			"lure_interval": 0.38 if using_bottom else 0.92,
			"lure_strength": 0.9 if using_bottom else 0.48,
			"bite_wait_multiplier": (0.7 if using_bottom else 1.28) + morning_bonus,
			"ambient_detail": "A dark shape holds beside the far-bank rocks.",
			"lure_detail": "The %s draws a %s response along the rocky drop-off." % [selected_presentation, "firm" if using_bottom else "cautious"],
			"bite_detail": "The %s loads steadily beside the deep rocks." % selected_presentation,
		}
	if _is_at_inlet():
		return {
			"ambient_interval": 1.55,
			"ambient_strength": 0.72,
			"lure_interval": 0.42 if selected_presentation == "lure rig" else 0.72,
			"lure_strength": 0.84 if selected_presentation == "lure rig" else 0.56,
			"bite_wait_multiplier": 0.72 if selected_presentation == "lure rig" else 1.08,
			"ambient_detail": "A shadow slips along the reeds.",
			"lure_detail": "A wake turns toward the %s beside the reeds." % selected_presentation,
			"bite_detail": "The %s disappears in a sharp inlet-side take." % selected_presentation,
		}
	return {
		"ambient_interval": 2.75,
		"ambient_strength": 0.48,
		"lure_interval": 0.82,
		"lure_strength": 0.58,
		"bite_wait_multiplier": 1.18,
		"ambient_detail": "A small wake crosses the dock shallows.",
		"lure_detail": "A cautious wake passes near the %s." % selected_presentation,
		"bite_detail": "The %s moves with a clear take by the dock." % selected_presentation,
	}


func _micro_habitat() -> String:
	if player != null and player.global_position.x <= far_bank_end_x and far_bank_reachable:
		return "deep rocky far bank"
	return "vegetated inlet" if _is_at_inlet() else "working dock shallows"


func _species_score(species_name: String) -> int:
	var preference := SPECIES_PREFERENCES[species_name] as Dictionary
	var habitat := _micro_habitat()
	var score := _preference_rank(preference["micro_habitats"] as Array, habitat)
	score += _preference_rank(preference["presentations"] as Array, selected_presentation)
	score += _preference_rank(preference["times"] as Array, time_of_day)
	if species_name == "Rock Bass" and habitat == "deep rocky far bank":
		score += 2
	if species_name == "Rock Bass" and selected_presentation == "bottom rig":
		score += 2
	if species_name == "Dock Bluegill" and selected_presentation == "lure rig":
		score += 2
	return score


func _preference_rank(preferences: Array, value: String) -> int:
	if preferences.is_empty() or not preferences.has(value):
		return 0
	return 2 if String(preferences[0]) == value else 1


func _is_at_inlet() -> bool:
	return player != null and player.global_position.x >= inlet_start_x

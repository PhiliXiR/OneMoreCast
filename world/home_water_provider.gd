extends Node3D

## Owns the player-facing fishing conditions for the home water.  Casting asks
## this provider for context, but continues to own the physical cast and fight.

@export var player_path: NodePath
@export var time_of_day := "early morning"
@export var inlet_start_x := 6.0

@onready var player: Node3D = get_node_or_null(player_path) as Node3D


func get_fishing_conditions() -> Dictionary:
	var habitat := "vegetated inlet" if _is_at_inlet() else "working dock shallows"
	var cue := "reeds and sheltered water" if habitat == "vegetated inlet" else "dock posts and open shallows"
	return {
		"micro_habitat": habitat,
		"time_of_day": time_of_day,
		"presentation": "lure rig",
		"visible_cue": cue,
	}


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
	if _is_at_inlet():
		return {
			"ambient_interval": 1.55,
			"ambient_strength": 0.72,
			"lure_interval": 0.42,
			"lure_strength": 0.84,
			"bite_wait_multiplier": 0.72,
			"ambient_detail": "A shadow slips along the reeds.",
			"lure_detail": "A wake turns toward the lure beside the reeds.",
			"bite_detail": "The lure disappears in a sharp inlet-side take.",
		}
	return {
		"ambient_interval": 2.75,
		"ambient_strength": 0.48,
		"lure_interval": 0.82,
		"lure_strength": 0.58,
		"bite_wait_multiplier": 1.18,
		"ambient_detail": "A small wake crosses the dock shallows.",
		"lure_detail": "A cautious wake passes near the lure.",
		"bite_detail": "The lure jumps with a clear take by the dock.",
	}


func _is_at_inlet() -> bool:
	return player != null and player.global_position.x >= inlet_start_x

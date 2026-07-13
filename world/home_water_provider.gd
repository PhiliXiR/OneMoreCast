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


func _is_at_inlet() -> bool:
	return player != null and player.global_position.x >= inlet_start_x

class_name LakeSurface
extends Node3D

enum Reaction { CAST_ENTRY, WAITING_LURE, AMBIENT_FISH_SIGN, LURE_FISH_SIGN, BITE_SIGNAL, FIGHT_RECOVERY, SURGE_WINDUP, SURGE, LANDING }

signal localized_reaction_requested(world_position: Vector3, strength: float, radius: float)
signal reaction_requested(reaction: Reaction, world_position: Vector3, strength: float, radius: float)

@onready var _material := $Mesh.get_active_material(0) as ShaderMaterial

var _cast_entry_position := Vector3.ZERO
var _cast_entry_strength := 0.0
var _cast_entry_radius := 0.0
var _cast_entry_elapsed := 10.0
var _waiting_lure_position := Vector3.ZERO
var _waiting_lure_active := false
var _ambient_sign_position := Vector3.ZERO
var _ambient_sign_strength := 0.0
var _ambient_sign_radius := 0.0
var _ambient_sign_elapsed := 10.0
var _lure_sign_position := Vector3.ZERO
var _lure_sign_strength := 0.0
var _lure_sign_radius := 0.0
var _lure_sign_elapsed := 10.0
var _bite_position := Vector3.ZERO
var _bite_strength := 0.0
var _bite_radius := 0.0
var _bite_elapsed := 10.0
var _fight_position := Vector3.ZERO
var _fight_strength := 0.0
var _fight_radius := 0.0
var _fight_direction := Vector3.FORWARD
var _fight_phase := Reaction.FIGHT_RECOVERY
var _fight_active := false
var _landing_position := Vector3.ZERO
var _landing_strength := 0.0
var _landing_radius := 0.0
var _landing_elapsed := 10.0


func _process(delta: float) -> void:
	_cast_entry_elapsed += delta
	_ambient_sign_elapsed += delta
	_lure_sign_elapsed += delta
	_bite_elapsed += delta
	_landing_elapsed += delta
	_apply_reaction_visuals()


func request_localized_reaction(world_position: Vector3, strength: float = 1.0, radius: float = 1.0) -> void:
	localized_reaction_requested.emit(world_position, maxf(strength, 0.0), maxf(radius, 0.0))


func request_cast_entry(world_position: Vector3, strength: float = 1.0, radius: float = 1.0) -> void:
	_cast_entry_position = world_position
	_cast_entry_strength = clampf(strength, 0.0, 1.0)
	_cast_entry_radius = maxf(radius, 0.1)
	_cast_entry_elapsed = 0.0
	reaction_requested.emit(Reaction.CAST_ENTRY, world_position, _cast_entry_strength, _cast_entry_radius)
	request_localized_reaction(world_position, _cast_entry_strength, _cast_entry_radius)


func set_waiting_lure_reaction(world_position: Vector3, active: bool) -> void:
	var became_active := active and not _waiting_lure_active
	_waiting_lure_position = world_position
	_waiting_lure_active = active
	if became_active:
		reaction_requested.emit(Reaction.WAITING_LURE, world_position, 0.35, 0.65)


func request_ambient_fish_sign(world_position: Vector3, strength: float = 1.0, radius: float = 1.0) -> void:
	_ambient_sign_position = world_position
	_ambient_sign_strength = clampf(strength, 0.0, 1.0)
	_ambient_sign_radius = maxf(radius, 0.1)
	_ambient_sign_elapsed = 0.0
	reaction_requested.emit(Reaction.AMBIENT_FISH_SIGN, world_position, _ambient_sign_strength, _ambient_sign_radius)


func request_lure_fish_sign(world_position: Vector3, strength: float = 1.0, radius: float = 1.0) -> void:
	_lure_sign_position = world_position
	_lure_sign_strength = clampf(strength, 0.0, 1.0)
	_lure_sign_radius = maxf(radius, 0.1)
	_lure_sign_elapsed = 0.0
	reaction_requested.emit(Reaction.LURE_FISH_SIGN, world_position, _lure_sign_strength, _lure_sign_radius)


func request_bite_signal(world_position: Vector3, strength: float = 1.0, radius: float = 1.0) -> void:
	_bite_position = world_position
	_bite_strength = clampf(strength, 0.0, 1.0)
	_bite_radius = maxf(radius, 0.1)
	_bite_elapsed = 0.0
	reaction_requested.emit(Reaction.BITE_SIGNAL, world_position, _bite_strength, _bite_radius)


func set_fight_water_reaction(reaction: Reaction, world_position: Vector3, strength: float, radius: float, direction: Vector3 = Vector3.FORWARD) -> void:
	if reaction < Reaction.FIGHT_RECOVERY or reaction > Reaction.SURGE:
		return
	_fight_position = world_position
	_fight_strength = clampf(strength, 0.0, 1.0)
	_fight_radius = maxf(radius, 0.1)
	_fight_direction = direction.normalized()
	if _fight_direction.length_squared() <= 0.0001:
		_fight_direction = Vector3.FORWARD
	var changed := not _fight_active or _fight_phase != reaction
	_fight_phase = reaction
	_fight_active = true
	if changed:
		reaction_requested.emit(reaction, world_position, _fight_strength, _fight_radius)


func clear_fight_water_reaction() -> void:
	_fight_active = false


func request_landing_reaction(world_position: Vector3, strength: float = 1.0, radius: float = 1.0) -> void:
	_fight_active = false
	_landing_position = world_position
	_landing_strength = clampf(strength, 0.0, 1.0)
	_landing_radius = maxf(radius, 0.1)
	_landing_elapsed = 0.0
	reaction_requested.emit(Reaction.LANDING, world_position, _landing_strength, _landing_radius)


func get_active_reaction_label() -> String:
	if _landing_elapsed < 1.35:
		return "landing splash"
	if _fight_active:
		return ["fight recovery", "surge wind-up", "surge"][_fight_phase - Reaction.FIGHT_RECOVERY]
	if _bite_elapsed < 0.9:
		return "bite signal"
	if _lure_sign_elapsed < 0.72:
		return "lure fish sign"
	if _ambient_sign_elapsed < 0.95:
		return "ambient fish sign"
	if _waiting_lure_active:
		return "waiting lure"
	return "none"


func is_cast_entry_reaction_active() -> bool:
	return _cast_entry_elapsed < 1.15 and _cast_entry_strength > 0.0


func is_waiting_lure_reaction_active() -> bool:
	return _waiting_lure_active


func set_tackle_readability(world_position: Vector3, radius: float, strength: float) -> void:
	_material.set_shader_parameter("tackle_clarity_center", world_position)
	_material.set_shader_parameter("tackle_clarity_radius", maxf(radius, 0.0))
	_material.set_shader_parameter("tackle_clarity_strength", clampf(strength, 0.0, 1.0))


func _apply_reaction_visuals() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("cast_entry_center", _cast_entry_position)
	_material.set_shader_parameter("cast_entry_strength", _cast_entry_strength)
	_material.set_shader_parameter("cast_entry_radius", _cast_entry_radius)
	_material.set_shader_parameter("cast_entry_elapsed", _cast_entry_elapsed)
	_material.set_shader_parameter("waiting_lure_center", _waiting_lure_position)
	_material.set_shader_parameter("waiting_lure_active", 1.0 if _waiting_lure_active else 0.0)
	_material.set_shader_parameter("ambient_sign_center", _ambient_sign_position)
	_material.set_shader_parameter("ambient_sign_strength", _ambient_sign_strength)
	_material.set_shader_parameter("ambient_sign_radius", _ambient_sign_radius)
	_material.set_shader_parameter("ambient_sign_elapsed", _ambient_sign_elapsed)
	_material.set_shader_parameter("lure_sign_center", _lure_sign_position)
	_material.set_shader_parameter("lure_sign_strength", _lure_sign_strength)
	_material.set_shader_parameter("lure_sign_radius", _lure_sign_radius)
	_material.set_shader_parameter("lure_sign_elapsed", _lure_sign_elapsed)
	_material.set_shader_parameter("bite_center", _bite_position)
	_material.set_shader_parameter("bite_strength", _bite_strength)
	_material.set_shader_parameter("bite_radius", _bite_radius)
	_material.set_shader_parameter("bite_elapsed", _bite_elapsed)
	_material.set_shader_parameter("fight_center", _fight_position)
	_material.set_shader_parameter("fight_strength", _fight_strength)
	_material.set_shader_parameter("fight_radius", _fight_radius)
	_material.set_shader_parameter("fight_direction", _fight_direction)
	_material.set_shader_parameter("fight_phase", float(_fight_phase - Reaction.FIGHT_RECOVERY) if _fight_active else -1.0)
	_material.set_shader_parameter("landing_center", _landing_position)
	_material.set_shader_parameter("landing_strength", _landing_strength)
	_material.set_shader_parameter("landing_radius", _landing_radius)
	_material.set_shader_parameter("landing_elapsed", _landing_elapsed)

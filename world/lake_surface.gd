class_name LakeSurface
extends Node3D

enum Reaction { CAST_ENTRY, WAITING_LURE }

signal localized_reaction_requested(world_position: Vector3, strength: float, radius: float)
signal reaction_requested(reaction: Reaction, world_position: Vector3, strength: float, radius: float)

@onready var _material := $Mesh.get_active_material(0) as ShaderMaterial

var _cast_entry_position := Vector3.ZERO
var _cast_entry_strength := 0.0
var _cast_entry_radius := 0.0
var _cast_entry_elapsed := 10.0
var _waiting_lure_position := Vector3.ZERO
var _waiting_lure_active := false


func _process(delta: float) -> void:
	_cast_entry_elapsed += delta
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

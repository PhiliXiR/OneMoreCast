class_name LakeSurface
extends Node3D

signal localized_reaction_requested(world_position: Vector3, strength: float, radius: float)

@onready var _material := $Mesh.get_active_material(0) as ShaderMaterial


func request_localized_reaction(world_position: Vector3, strength: float = 1.0, radius: float = 1.0) -> void:
	localized_reaction_requested.emit(world_position, maxf(strength, 0.0), maxf(radius, 0.0))


func set_tackle_readability(world_position: Vector3, radius: float, strength: float) -> void:
	_material.set_shader_parameter("tackle_clarity_center", world_position)
	_material.set_shader_parameter("tackle_clarity_radius", maxf(radius, 0.0))
	_material.set_shader_parameter("tackle_clarity_strength", clampf(strength, 0.0, 1.0))


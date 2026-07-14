class_name HomeWaterPresentation
extends Node3D

## Builds the readable, game-owned dressing for the first home-water outing.
## These simple forms are deliberately deterministic: they establish authored
## fishing conditions without requiring a third-party environment pack.

@export var shore_line_z := 2.05
@export var dock_approach_half_width := 1.7

const WARM_WINDOW := Color("#ffbd70")
const SHORE_GREEN := Color("#315333")
const REED_GREEN := Color("#294d29")
const ROCK_GREY := Color("#3b4650")

var _shore_collision_count := 0


func _ready() -> void:
	_build_shoreline()
	_build_cottage()
	_build_inlet_dressing()
	_build_far_bank_dressing()


func has_natural_shore_collision() -> bool:
	return _shore_collision_count >= 4


func _build_shoreline() -> void:
	# A continuous bank, interrupted only at the dock approach, prevents an
	# unexplained walk into the lake while leaving all fishable water open.
	var shore_half_width := 12.0
	var bank_width := shore_half_width - dock_approach_half_width
	var bank_center := (shore_half_width + dock_approach_half_width) * 0.5
	_add_bank_segment("WestShoreBank", Vector3(-bank_center, 0.38, shore_line_z), Vector3(bank_width, 0.75, 0.8))
	_add_bank_segment("EastShoreBank", Vector3(bank_center, 0.38, shore_line_z), Vector3(bank_width, 0.75, 0.8))
	_add_bank_segment("WestBoundary", Vector3(-11.7, 0.7, -3.2), Vector3(0.65, 1.4, 10.4))
	_add_bank_segment("EastBoundary", Vector3(11.7, 0.7, -3.2), Vector3(0.65, 1.4, 10.4))


func _build_cottage() -> void:
	var cottage := Node3D.new()
	cottage.name = "DocksideCottage"
	cottage.position = Vector3(5.9, 0.0, -5.7)
	cottage.set_meta("interactive", false)
	add_child(cottage)
	_add_box(cottage, "Walls", Vector3(0, 1.35, 0), Vector3(3.4, 2.7, 2.6), Color("#76513a"))
	_add_box(cottage, "Roof", Vector3(0, 3.0, 0), Vector3(4.05, 0.46, 3.15), Color("#2d3037"), Vector3(0.0, 0.0, 0.0))
	_add_box(cottage, "Porch", Vector3(-1.95, 0.3, 0.5), Vector3(0.85, 0.25, 1.55), Color("#543d2d"))
	_add_window(cottage, "WarmWindowOne", Vector3(-1.73, 1.55, 0.35))
	_add_window(cottage, "WarmWindowTwo", Vector3(-1.73, 1.55, -0.65))
	_add_static_collision(cottage, "CottageCollision", Vector3(0, 1.35, 0), Vector3(3.4, 2.7, 2.6))


func _build_inlet_dressing() -> void:
	var inlet := Node3D.new()
	inlet.name = "ProceduralInletDressing"
	inlet.position = Vector3(8.25, 0.0, 4.15)
	add_child(inlet)
	for index in 10:
		var angle := float(index) * 0.61
		var radius := 0.65 + float(index % 3) * 0.28
		var reed := _add_cylinder(inlet, "InletReed%02d" % index, Vector3(cos(angle) * radius, 0.8, sin(angle) * radius), 0.065, 1.6 + float(index % 2) * 0.22, REED_GREEN)
		reed.rotation.z = sin(angle * 1.7) * 0.08
	for index in 5:
		_add_disc(inlet, "InletLily%02d" % index, Vector3(-0.5 + float(index) * 0.38, 0.035, 1.0 + sin(float(index)) * 0.3), 0.25, Color("#234c2b"))


func _build_far_bank_dressing() -> void:
	var far_bank := Node3D.new()
	far_bank.name = "ProceduralRockyFarBank"
	far_bank.position = Vector3(-8.4, 0.0, 3.0)
	add_child(far_bank)
	for index in 7:
		var x := -1.35 + float(index) * 0.46
		var z := sin(float(index) * 1.9) * 0.5
		var scale := Vector3(0.65 + float(index % 2) * 0.22, 0.45 + float(index % 3) * 0.12, 0.6)
		_add_rock(far_bank, "FarBankRock%02d" % index, Vector3(x, scale.y * 0.5, z), scale)


func _add_bank_segment(node_name: String, position: Vector3, size: Vector3) -> void:
	var bank := Node3D.new()
	bank.name = node_name
	add_child(bank)
	_add_box(bank, "ShoreDressing", position, size, SHORE_GREEN)
	_add_static_collision(bank, "ShoreCollision", position, size)
	_shore_collision_count += 1


func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	instance.rotation = rotation
	instance.mesh = mesh
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _add_window(parent: Node3D, node_name: String, position: Vector3) -> void:
	var window := _add_box(parent, node_name, position, Vector3(0.035, 0.64, 0.56), WARM_WINDOW)
	var material := window.material_override as StandardMaterial3D
	material.emission_enabled = true
	material.emission = WARM_WINDOW
	material.emission_energy_multiplier = 1.4


func _add_cylinder(parent: Node3D, node_name: String, position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.7
	mesh.bottom_radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	instance.mesh = mesh
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _add_disc(parent: Node3D, node_name: String, position: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.025
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	instance.mesh = mesh
	instance.material_override = _material(color)
	parent.add_child(instance)


func _add_rock(parent: Node3D, node_name: String, position: Vector3, scale: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.8
	mesh.height = 1.0
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	instance.scale = scale
	instance.mesh = mesh
	instance.material_override = _material(ROCK_GREY)
	parent.add_child(instance)


func _add_static_collision(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = position
	body.add_child(shape)
	parent.add_child(body)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material

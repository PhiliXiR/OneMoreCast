class_name HomeWaterPresentation
extends Node3D

## Builds the readable, game-owned dressing for the first home-water outing.
## These simple forms are deliberately deterministic: they establish authored
## fishing conditions without requiring a third-party environment pack.

@export var shore_line_z := 2.05
@export var dock_approach_half_width := 1.7
@export var reduced_motion := false

const WARM_WINDOW := Color("#ffbd70")
const SHORE_GREEN := Color("#315333")
const REED_GREEN := Color("#294d29")
const ROCK_GREY := Color("#3b4650")
const WEATHERED_WOOD := Color("#51443a")
const TACKLE_CANVAS := Color("#9b7441")
const GALVANIZED_METAL := Color("#6d7a78")
const BUOY_RED := Color("#9a493c")
const BOAT_BLUE := Color("#405662")
const OPEN_FISHING_CORRIDOR_HALF_WIDTH := 3.4
const REED_ISLAND_NAME := "ReedIsland"
const FALLEN_TIMBER_NAME := "FallenTimber"
const ROWBOAT_NAME := "MooringRowboat"
const WEST_BUOY_NAME := "MarkerBuoyWest"
const EAST_BUOY_NAME := "MarkerBuoyEast"
const FAR_BANK_NAME := "FarBankSilhouette"
const WATERSHED_MARKER_NAME := "WatershedSurveyMarker"
const FAR_HORIZON_POSITION := Vector3(0.0, 0.0, 31.0)
const FAR_HORIZON_WIDTH := 28.0
const ENVIRONMENTAL_LIFE_NAME := "EnvironmentalLife"
const REDUCED_MOTION_SETTING := "accessibility/reduce_motion"

var _shore_collision_count := 0
var _environment_elapsed := 0.0
var _swaying_reeds: Array[MeshInstance3D] = []
var _smoke_puffs: Array[MeshInstance3D] = []
var _bird_silhouettes: Array[Node3D] = []


func _ready() -> void:
	reduced_motion = reduced_motion or bool(ProjectSettings.get_setting(REDUCED_MOTION_SETTING, false))
	_build_shoreline()
	_build_cottage()
	_build_dockside_foreground()
	_build_open_water_landmarks()
	_build_inlet_dressing()
	_build_far_bank_dressing()
	_build_far_horizon()
	_build_environmental_life()


func _process(delta: float) -> void:
	if reduced_motion:
		return
	_environment_elapsed += delta
	_animate_environmental_life()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled:
		_reset_environmental_life()


func has_quiet_environmental_life() -> bool:
	var life := get_node_or_null(ENVIRONMENTAL_LIFE_NAME) as Node3D
	return life != null and _swaying_reeds.size() >= 8 and _smoke_puffs.size() >= 3 and _bird_silhouettes.size() >= 3


func is_environmental_motion_active() -> bool:
	return not reduced_motion and _environment_elapsed > 0.0


func has_natural_shore_collision() -> bool:
	return _shore_collision_count >= 4


func has_clear_dock_approach() -> bool:
	var foreground := get_node_or_null("DocksideForeground") as Node3D
	if foreground == null:
		return false
	# The player-to-dock lane is centered on x = -0.65. Foreground props stay
	# beyond this generous lane and are visual only, so walking and casting keep
	# the same unobstructed approach.
	for detail in foreground.get_children():
		if detail is Node3D and absf((detail as Node3D).position.x + 0.65) < 2.15:
			return false
	return true


func has_open_fishable_water() -> bool:
	var habitat := get_node_or_null("OpenWaterLandmarks") as Node3D
	if habitat == null:
		return false
	# The player faces a broad central corridor while casting. Keep scenic forms
	# beyond it so the cast target, terminal tackle, line, and nearby fish signs
	# retain a quiet water backdrop.
	for landmark in habitat.get_children():
		if landmark is Node3D and absf((landmark as Node3D).position.x) < OPEN_FISHING_CORRIDOR_HALF_WIDTH:
			return false
	return true


func has_layered_far_horizon() -> bool:
	var horizon := get_node_or_null(FAR_BANK_NAME) as Node3D
	if horizon == null or horizon.get_child_count() < 3:
		return false
	return horizon.get_node_or_null(WATERSHED_MARKER_NAME) != null


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


func _build_dockside_foreground() -> void:
	# These are deliberate, game-owned signs of an ordinary fishing morning.
	# They remain outside the dock approach and have no collision or interaction.
	var foreground := Node3D.new()
	foreground.name = "DocksideForeground"
	foreground.set_meta("interactive", false)
	add_child(foreground)

	_add_cylinder(foreground, "MooringPost", Vector3(-3.35, 0.58, 1.25), 0.15, 1.16, WEATHERED_WOOD)
	_add_cylinder(foreground, "MooringCap", Vector3(-3.35, 1.18, 1.25), 0.2, 0.1, GALVANIZED_METAL)
	_add_box(foreground, "TackleCrate", Vector3(3.05, 0.3, -0.3), Vector3(0.82, 0.6, 0.6), TACKLE_CANVAS, Vector3(0.0, 0.22, 0.0))
	_add_cylinder(foreground, "Bucket", Vector3(3.72, 0.27, 0.22), 0.22, 0.5, GALVANIZED_METAL)
	_add_box(foreground, "LandingNetHandle", Vector3(3.4, 0.34, 1.28), Vector3(0.08, 0.08, 1.2), WEATHERED_WOOD, Vector3(0.0, 0.62, 0.0))
	_add_disc(foreground, "LandingNet", Vector3(3.75, 0.08, 1.75), 0.4, Color("#48625a"))
	_add_rope_coil(foreground, "RopeCoil", Vector3(-3.55, 0.04, 0.55))
	for index in 9:
		var side := -1.0 if index % 2 == 0 else 1.0
		var x := side * (3.1 + float(index % 3) * 0.42)
		var z := -0.15 + float(index) * 0.42
		var grass := _add_cylinder(foreground, "ShoreGrass%02d" % index, Vector3(x, 0.38, z), 0.045, 0.76 + float(index % 2) * 0.18, SHORE_GREEN)
		grass.rotation.z = side * 0.14
	for index in 7:
		var side := -1.0 if index % 2 == 0 else 1.0
		var x := side * (3.45 + float(index % 2) * 0.36)
		var z := -0.05 + float(index) * 0.5
		var scale := Vector3(0.28 + float(index % 3) * 0.07, 0.15 + float(index % 2) * 0.05, 0.24)
		_add_rock(foreground, "ShoreStone%02d" % index, Vector3(x, scale.y * 0.5, z), scale)


func _build_open_water_landmarks() -> void:
	# These landmarks establish a lived-in micro-habitat rhythm at the water's edges.
	# They intentionally have no collision or interaction: fishable water remains
	# open and the central casting corridor stays legible.
	var habitat := Node3D.new()
	habitat.name = "OpenWaterLandmarks"
	habitat.set_meta("interactive", false)
	add_child(habitat)

	_add_reed_island(habitat, Vector3(-6.3, 0.0, 6.6))
	_add_fallen_timber(habitat, Vector3(5.5, 0.08, 8.2))
	_add_rowboat(habitat, Vector3(-5.2, 0.2, 13.0))
	_add_marker_buoy(habitat, WEST_BUOY_NAME, Vector3(-6.8, 0.08, 11.0))
	_add_marker_buoy(habitat, EAST_BUOY_NAME, Vector3(6.4, 0.08, 14.0))


func _add_reed_island(parent: Node3D, position: Vector3) -> void:
	var island := Node3D.new()
	island.name = REED_ISLAND_NAME
	island.position = position
	parent.add_child(island)
	_add_disc(island, "Muck", Vector3.ZERO, 1.18, Color("#314733")).scale.z = 0.7
	for index in 9:
		var angle := float(index) * 0.7
		var radius := 0.25 + float(index % 3) * 0.24
		var reed := _add_cylinder(island, "Reed%02d" % index, Vector3(cos(angle) * radius, 0.72, sin(angle) * radius * 0.68), 0.045, 1.35 + float(index % 2) * 0.22, REED_GREEN)
		reed.rotation.z = sin(angle) * 0.1
		_register_swaying_reed(reed, 0.045 + float(index % 3) * 0.012, angle)


func _add_fallen_timber(parent: Node3D, position: Vector3) -> void:
	var timber := Node3D.new()
	timber.name = FALLEN_TIMBER_NAME
	timber.position = position
	timber.rotation.y = -0.48
	parent.add_child(timber)
	_add_cylinder(timber, "Log", Vector3.ZERO, 0.18, 2.7, WEATHERED_WOOD).rotation.z = PI * 0.5
	_add_cylinder(timber, "BrokenBranch", Vector3(0.55, 0.2, 0.0), 0.06, 0.85, WEATHERED_WOOD).rotation.z = PI * 0.88


func _add_rowboat(parent: Node3D, position: Vector3) -> void:
	var boat := Node3D.new()
	boat.name = ROWBOAT_NAME
	boat.position = position
	boat.rotation.y = 0.42
	parent.add_child(boat)
	_add_box(boat, "Hull", Vector3.ZERO, Vector3(1.65, 0.28, 0.62), BOAT_BLUE)
	_add_box(boat, "Seat", Vector3(0.0, 0.2, 0.0), Vector3(0.18, 0.09, 0.72), WEATHERED_WOOD)
	_add_box(boat, "Oar", Vector3(0.15, 0.24, 0.52), Vector3(1.85, 0.045, 0.06), WEATHERED_WOOD, Vector3(0.0, 0.3, 0.0))


func _add_marker_buoy(parent: Node3D, node_name: String, position: Vector3) -> void:
	var buoy := Node3D.new()
	buoy.name = node_name
	buoy.position = position
	parent.add_child(buoy)
	_add_cylinder(buoy, "Float", Vector3(0.0, 0.18, 0.0), 0.16, 0.36, BUOY_RED)
	_add_cylinder(buoy, "Mast", Vector3(0.0, 0.5, 0.0), 0.035, 0.42, GALVANIZED_METAL)


func _add_rope_coil(parent: Node3D, node_name: String, position: Vector3) -> void:
	var coil := Node3D.new()
	coil.name = node_name
	coil.position = position
	parent.add_child(coil)
	for index in 3:
		var ring := _add_disc(coil, "Loop%02d" % index, Vector3(0.06 * float(index), 0.016 * float(index), 0), 0.32 - float(index) * 0.065, Color("#b8996b"))
		ring.scale.z = 0.58


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
		_register_swaying_reed(reed, 0.04 + float(index % 3) * 0.01, angle * 1.7)
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


func _build_far_horizon() -> void:
	# The bank sits beyond the fishable water rather than making a reachable
	# promise. Its staggered ridges preserve a cool, fog-softened lake horizon.
	var horizon := Node3D.new()
	horizon.name = FAR_BANK_NAME
	horizon.position = FAR_HORIZON_POSITION
	horizon.set_meta("interactive", false)
	add_child(horizon)

	_add_box(horizon, "DistantShore", Vector3(0.0, 1.0, 0.8), Vector3(FAR_HORIZON_WIDTH, 2.0, 1.6), Color("#253d3b"))
	_add_box(horizon, "NearTreeLine", Vector3(-1.4, 2.25, -0.35), Vector3(FAR_HORIZON_WIDTH - 4.0, 1.25, 0.8), Color("#1c332f"))
	_add_box(horizon, "HighRidge", Vector3(5.0, 3.15, 1.55), Vector3(15.0, 1.35, 0.7), Color("#304243"))
	for index in 17:
		var x := -12.5 + float(index) * 1.55
		var height := 2.7 + float(index % 4) * 0.5
		var tree := _add_cylinder(horizon, "FarTree%02d" % index, Vector3(x, height * 0.5, -0.95 + sin(float(index) * 1.7) * 0.22), 0.2 + float(index % 3) * 0.045, height, Color("#172d2c"))
		tree.rotation.z = sin(float(index) * 0.8) * 0.055

	# An old watershed survey marker is intentionally small and unlit: it reads
	# as a question on the horizon, never as a destination or active objective.
	var marker := Node3D.new()
	marker.name = WATERSHED_MARKER_NAME
	marker.position = Vector3(6.8, 3.85, -1.12)
	marker.set_meta("interactive", false)
	horizon.add_child(marker)
	_add_cylinder(marker, "WeatheredMast", Vector3.ZERO, 0.075, 2.15, Color("#665f4c"))
	_add_box(marker, "SurveyCrossbar", Vector3(0.0, 0.72, 0.0), Vector3(0.86, 0.07, 0.07), Color("#665f4c"))
	_add_disc(marker, "MarkerCap", Vector3(0.0, 1.12, 0.0), 0.16, Color("#8b7c54"))


func _build_environmental_life() -> void:
	# These cues make the lake feel inhabited, but remain distant, slow, and
	# wholly decorative. Fishing reactions continue to come from LakeSurface.
	var life := Node3D.new()
	life.name = ENVIRONMENTAL_LIFE_NAME
	life.set_meta("interactive", false)
	add_child(life)

	var smoke := Node3D.new()
	smoke.name = "CottageSmoke"
	smoke.position = Vector3(5.9, 3.35, -5.7)
	life.add_child(smoke)
	for index in 3:
		var puff := _add_disc(smoke, "SmokePuff%02d" % index, Vector3(0.08 * float(index), 0.35 + float(index) * 0.32, 0.0), 0.17 + float(index) * 0.055, Color("#9aa1a0"))
		puff.scale.z = 0.72
		puff.set_meta("life_origin", puff.position)
		_smoke_puffs.append(puff)

	var birds := Node3D.new()
	birds.name = "BirdSilhouettes"
	birds.position = Vector3(-4.0, 5.9, 25.0)
	life.add_child(birds)
	for index in 3:
		var bird := Node3D.new()
		bird.name = "Bird%02d" % index
		bird.position = Vector3(float(index) * 1.25, sin(float(index)) * 0.24, float(index) * 0.18)
		bird.set_meta("life_origin", bird.position)
		_add_box(bird, "WingLeft", Vector3(-0.16, 0.0, 0.0), Vector3(0.28, 0.025, 0.06), Color("#202b31"), Vector3(0.0, 0.0, -0.28))
		_add_box(bird, "WingRight", Vector3(0.16, 0.0, 0.0), Vector3(0.28, 0.025, 0.06), Color("#202b31"), Vector3(0.0, 0.0, 0.28))
		birds.add_child(bird)
		_bird_silhouettes.append(bird)


func _register_swaying_reed(reed: MeshInstance3D, amplitude: float, phase: float) -> void:
	reed.set_meta("sway_origin", reed.rotation.z)
	reed.set_meta("sway_amplitude", amplitude)
	reed.set_meta("sway_phase", phase)
	_swaying_reeds.append(reed)


func _animate_environmental_life() -> void:
	for reed in _swaying_reeds:
		reed.rotation.z = float(reed.get_meta("sway_origin")) + sin(_environment_elapsed * 0.52 + float(reed.get_meta("sway_phase"))) * float(reed.get_meta("sway_amplitude"))
	for index in _smoke_puffs.size():
		var puff := _smoke_puffs[index]
		var origin := puff.get_meta("life_origin") as Vector3
		var drift := fmod(_environment_elapsed * 0.055 + float(index) * 0.27, 0.34)
		puff.position = origin + Vector3(drift, drift * 1.4, 0.0)
	for index in _bird_silhouettes.size():
		var bird := _bird_silhouettes[index]
		var origin := bird.get_meta("life_origin") as Vector3
		bird.position = origin + Vector3(sin(_environment_elapsed * 0.2 + float(index)) * 0.34, sin(_environment_elapsed * 0.45 + float(index)) * 0.06, 0.0)


func _reset_environmental_life() -> void:
	for reed in _swaying_reeds:
		reed.rotation.z = float(reed.get_meta("sway_origin"))
	for puff in _smoke_puffs:
		puff.position = puff.get_meta("life_origin") as Vector3
	for bird in _bird_silhouettes:
		bird.position = bird.get_meta("life_origin") as Vector3


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


func _add_disc(parent: Node3D, node_name: String, position: Vector3, radius: float, color: Color) -> MeshInstance3D:
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
	return instance


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

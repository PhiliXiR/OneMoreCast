extends Node3D

@export var player_path: NodePath
@export var camera_path: NodePath
@export var target_marker_path: NodePath
@export var lure_marker_path: NodePath
@export var rod_tip_path: NodePath
@export var fishing_line_path: NodePath
@export var water_center := Vector3(0.0, 0.0, 10.0)
@export var water_size := Vector2(28.0, 16.0)
@export var cast_distance := 8.0
@export var near_water_distance := 5.0
@export var sweet_spot := Vector3(0.0, 0.0, 10.0)
@export var sweet_spot_radius := 6.0

@onready var player: Node3D = get_node_or_null(player_path) as Node3D
@onready var camera: Node = get_node_or_null(camera_path)
@onready var target_marker: Node3D = get_node_or_null(target_marker_path) as Node3D
@onready var lure_marker: MeshInstance3D = get_node_or_null(lure_marker_path) as MeshInstance3D
@onready var rod_tip: Node3D = get_node_or_null(rod_tip_path) as Node3D
@onready var fishing_line: MeshInstance3D = get_node_or_null(fishing_line_path) as MeshInstance3D

var target_point := Vector3.ZERO
var target_valid := false
var player_near_water := false
var last_landing_quality := 0.0
var last_landing_label := "No cast yet"

var _valid_material := StandardMaterial3D.new()
var _invalid_material := StandardMaterial3D.new()
var _lure_material := StandardMaterial3D.new()
var _line_valid_material := StandardMaterial3D.new()
var _line_invalid_material := StandardMaterial3D.new()
var _cast_line_locked_to_lure := false
var _last_line_start := Vector3.ZERO
var _last_line_end := Vector3.ZERO
var _last_line_valid := false


func _ready() -> void:
	_valid_material.albedo_color = Color(0.25, 0.9, 0.55, 0.85)
	_invalid_material.albedo_color = Color(1.0, 0.25, 0.2, 0.85)
	_lure_material.albedo_color = Color(1.0, 0.88, 0.3, 1.0)
	_line_valid_material.albedo_color = Color(0.25, 0.95, 0.55, 1.0)
	_line_invalid_material.albedo_color = Color(1.0, 0.25, 0.2, 1.0)
	_configure_marker_material(_valid_material, Color(0.25, 1.0, 0.55, 1.0))
	_configure_marker_material(_invalid_material, Color(1.0, 0.2, 0.1, 1.0))
	_configure_marker_material(_lure_material, Color(1.0, 0.88, 0.25, 1.0))
	_configure_marker_material(_line_valid_material, Color(0.25, 1.0, 0.55, 1.0))
	_configure_marker_material(_line_invalid_material, Color(1.0, 0.2, 0.1, 1.0))
	if lure_marker != null:
		lure_marker.visible = false
		lure_marker.material_override = _lure_material
	if fishing_line != null:
		var line_mesh := CylinderMesh.new()
		line_mesh.top_radius = 0.018
		line_mesh.bottom_radius = 0.018
		line_mesh.height = 1.0
		fishing_line.mesh = line_mesh
		fishing_line.visible = false


func _process(_delta: float) -> void:
	refresh_casting_visuals()


func refresh_casting_visuals() -> void:
	_update_cast_target()
	_update_fishing_line()


func can_start_cast() -> bool:
	_update_cast_target()
	return player_near_water and target_valid


func get_cast_block_reason() -> String:
	_update_cast_target()
	if not player_near_water:
		return "Move closer to the water before casting."
	if not target_valid:
		return "Aim the cast marker onto the water."
	return ""


func begin_cast() -> void:
	_update_cast_target()
	last_landing_quality = _calculate_landing_quality(target_point)
	last_landing_label = _format_quality(last_landing_quality)
	_animate_lure()


func get_landing_quality() -> float:
	return last_landing_quality


func get_spatial_feedback() -> String:
	_update_cast_target()
	var near_text := "near water" if player_near_water else "too far from water"
	var target_text := "target valid" if target_valid else "target off water"
	return "Spatial: %s, %s, landing %s" % [near_text, target_text, last_landing_label]


func get_result_context() -> String:
	return "Landing quality: %s" % last_landing_label


func get_rod_tip_position() -> Vector3:
	if rod_tip == null:
		return Vector3.ZERO
	return rod_tip.global_position


func get_line_endpoint() -> Vector3:
	return _last_line_end


func is_line_showing_valid_feedback() -> bool:
	return _last_line_valid


func _update_cast_target() -> void:
	if player == null:
		return

	player_near_water = _is_near_water(player.global_position)
	var direction := _get_cast_direction()
	target_point = player.global_position + direction * cast_distance
	target_point.y = water_center.y + 0.38
	target_valid = _is_in_water(target_point)

	if target_marker == null:
		return

	target_marker.global_position = target_point
	target_marker.visible = true
	_apply_marker_material(target_marker, _valid_material if target_valid else _invalid_material)


func _get_cast_direction() -> Vector3:
	if camera != null and camera.has_method("get_camera_planar_forward"):
		var camera_forward: Vector3 = camera.call("get_camera_planar_forward") as Vector3
		if camera_forward.length_squared() > 0.0001:
			return camera_forward.normalized()

	return -player.global_transform.basis.z.normalized()


func get_target_point() -> Vector3:
	_update_cast_target()
	return target_point


func _is_in_water(point: Vector3) -> bool:
	var half_size := water_size * 0.5
	return (
		point.x >= water_center.x - half_size.x
		and point.x <= water_center.x + half_size.x
		and point.z >= water_center.z - half_size.y
		and point.z <= water_center.z + half_size.y
	)


func _is_near_water(point: Vector3) -> bool:
	var half_size := water_size * 0.5
	var nearest_x := clampf(point.x, water_center.x - half_size.x, water_center.x + half_size.x)
	var nearest_z := clampf(point.z, water_center.z - half_size.y, water_center.z + half_size.y)
	var nearest := Vector3(nearest_x, point.y, nearest_z)
	return point.distance_to(nearest) <= near_water_distance


func _calculate_landing_quality(point: Vector3) -> float:
	if not _is_in_water(point):
		return 0.0

	var distance_to_sweet_spot := Vector2(point.x - sweet_spot.x, point.z - sweet_spot.z).length()
	return clampf(1.0 - distance_to_sweet_spot / sweet_spot_radius, 0.2, 1.0)


func _format_quality(quality: float) -> String:
	if quality >= 0.75:
		return "excellent"
	if quality >= 0.45:
		return "good"
	if quality > 0.0:
		return "rough"
	return "invalid"


func _animate_lure() -> void:
	if lure_marker == null or player == null:
		return

	_cast_line_locked_to_lure = true
	lure_marker.visible = true
	lure_marker.global_position = get_rod_tip_position()
	lure_marker.material_override = _lure_material
	var tween := create_tween()
	tween.tween_property(lure_marker, "global_position", target_point + Vector3.UP * 0.12, 0.45)


func _update_fishing_line() -> void:
	if fishing_line == null or rod_tip == null:
		return

	var line_start := rod_tip.global_position
	var line_end := target_point + Vector3.UP * 0.12
	if _cast_line_locked_to_lure and lure_marker != null:
		line_end = lure_marker.global_position

	var line_valid := target_valid and player_near_water
	_draw_line_segment(line_start, line_end, line_valid)


func _draw_line_segment(line_start: Vector3, line_end: Vector3, line_valid: bool) -> void:
	var length := line_start.distance_to(line_end)
	if length <= 0.01:
		fishing_line.visible = false
		return

	var direction := (line_end - line_start).normalized()
	var midpoint := line_start.lerp(line_end, 0.5)
	fishing_line.visible = true
	fishing_line.global_transform = Transform3D(_basis_from_y_axis(direction), midpoint)
	fishing_line.scale = Vector3(1.0, length, 1.0)
	fishing_line.material_override = _line_valid_material if line_valid else _line_invalid_material
	_last_line_start = line_start
	_last_line_end = line_end
	_last_line_valid = line_valid


func _basis_from_y_axis(y_axis: Vector3) -> Basis:
	var up := y_axis.normalized()
	var side := Vector3.FORWARD.cross(up)
	if side.length_squared() <= 0.0001:
		side = Vector3.RIGHT.cross(up)
	side = side.normalized()
	var forward := up.cross(side).normalized()
	return Basis(side, up, forward)


func _configure_marker_material(material: StandardMaterial3D, color: Color) -> void:
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	material.no_depth_test = true


func _apply_marker_material(root: Node, material: StandardMaterial3D) -> void:
	if root is MeshInstance3D:
		(root as MeshInstance3D).material_override = material
	for child in root.get_children():
		_apply_marker_material(child, material)

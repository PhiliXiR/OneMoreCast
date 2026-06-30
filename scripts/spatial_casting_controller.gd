extends Node3D

@export var player_path: NodePath
@export var camera_path: NodePath
@export var target_marker_path: NodePath
@export var lure_marker_path: NodePath
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

var target_point := Vector3.ZERO
var target_valid := false
var player_near_water := false
var last_landing_quality := 0.0
var last_landing_label := "No cast yet"

var _valid_material := StandardMaterial3D.new()
var _invalid_material := StandardMaterial3D.new()
var _lure_material := StandardMaterial3D.new()


func _ready() -> void:
	_valid_material.albedo_color = Color(0.25, 0.9, 0.55, 0.85)
	_invalid_material.albedo_color = Color(1.0, 0.25, 0.2, 0.85)
	_lure_material.albedo_color = Color(1.0, 0.88, 0.3, 1.0)
	_configure_marker_material(_valid_material, Color(0.25, 1.0, 0.55, 1.0))
	_configure_marker_material(_invalid_material, Color(1.0, 0.2, 0.1, 1.0))
	_configure_marker_material(_lure_material, Color(1.0, 0.88, 0.25, 1.0))
	if lure_marker != null:
		lure_marker.visible = false
		lure_marker.material_override = _lure_material


func _process(_delta: float) -> void:
	_update_cast_target()


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

	lure_marker.visible = true
	lure_marker.global_position = player.global_position + Vector3.UP * 1.2
	lure_marker.material_override = _lure_material
	var tween := create_tween()
	tween.tween_property(lure_marker, "global_position", target_point + Vector3.UP * 0.12, 0.45)


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

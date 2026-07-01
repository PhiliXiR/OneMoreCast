extends Node3D

enum CastPhase { AIMING, CASTING, LANDED_SLACK, LANDED_TAUT }

@export var player_path: NodePath
@export var camera_path: NodePath
@export var target_marker_path: NodePath
@export var lure_marker_path: NodePath
@export var rod_root_path: NodePath
@export var rod_tip_path: NodePath
@export var fishing_line_path: NodePath
@export var line_overlay_path: NodePath
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
@onready var rod_root: Node3D = get_node_or_null(rod_root_path) as Node3D
@onready var rod_tip: Node3D = get_node_or_null(rod_tip_path) as Node3D
@onready var fishing_line: MeshInstance3D = get_node_or_null(fishing_line_path) as MeshInstance3D
@onready var line_overlay: Line2D = get_node_or_null(line_overlay_path) as Line2D

var target_point := Vector3.ZERO
var target_valid := false
var player_near_water := false
var last_landing_quality := 0.0
var last_landing_label := "No cast yet"

var _valid_material := StandardMaterial3D.new()
var _invalid_material := StandardMaterial3D.new()
var _lure_material := StandardMaterial3D.new()
var _phase := CastPhase.AIMING
var _cast_elapsed := 0.0
var _cast_duration := 0.72
var _cast_start := Vector3.ZERO
var _cast_destination := Vector3.ZERO
var _landed_elapsed := 0.0
var _line_points_world: Array[Vector3] = []
var _last_line_start := Vector3.ZERO
var _last_line_end := Vector3.ZERO
var _last_line_valid := false
var _rod_rest_rotation := Vector3.ZERO
var _rod_cast_rotation := Vector3.ZERO


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
	if fishing_line != null:
		fishing_line.visible = false
	if line_overlay != null:
		line_overlay.visible = false
		line_overlay.width = 1.35
	if rod_root != null:
		_rod_rest_rotation = rod_root.rotation
		_rod_cast_rotation = _rod_rest_rotation


func _process(delta: float) -> void:
	refresh_casting_visuals(delta)


func refresh_casting_visuals(delta := 0.0) -> void:
	if _phase == CastPhase.CASTING:
		_update_cast_motion(delta)
	else:
		_update_cast_target()
		if _phase == CastPhase.LANDED_SLACK or _phase == CastPhase.LANDED_TAUT:
			_update_landed_line(delta)
		else:
			_update_aiming_line()
	_update_rod_motion()
	_draw_projected_line()


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
	if lure_marker == null:
		return

	_phase = CastPhase.CASTING
	_cast_elapsed = 0.0
	_landed_elapsed = 0.0
	_cast_start = get_rod_tip_position()
	_cast_destination = target_point + Vector3.UP * 0.12
	lure_marker.visible = true
	lure_marker.global_position = _cast_start
	lure_marker.material_override = _lure_material
	_update_cast_line(0.0)


func get_landing_quality() -> float:
	return last_landing_quality


func get_spatial_feedback() -> String:
	_update_cast_target()
	var near_text := "near water" if player_near_water else "too far from water"
	var target_text := "target valid" if target_valid else "target off water"
	return "Spatial: %s, %s, line %s, landing %s" % [
		near_text,
		target_text,
		get_line_state_label(),
		last_landing_label,
	]


func get_result_context() -> String:
	return "Landing quality: %s" % last_landing_label


func get_rod_tip_position() -> Vector3:
	if rod_tip == null:
		return Vector3.ZERO
	return rod_tip.global_position


func get_line_endpoint() -> Vector3:
	return _last_line_end


func get_line_points_world() -> Array[Vector3]:
	return _line_points_world.duplicate()


func get_line_state_label() -> String:
	match _phase:
		CastPhase.CASTING:
			return "casting"
		CastPhase.LANDED_SLACK:
			return "slack"
		CastPhase.LANDED_TAUT:
			return "taut"
		_:
			return "aiming"


func get_line_overlay_width() -> float:
	if line_overlay == null:
		return 0.0
	return line_overlay.width


func is_line_showing_valid_feedback() -> bool:
	return _last_line_valid


func is_world_line_disabled() -> bool:
	return fishing_line == null or not fishing_line.visible


func get_rod_cast_motion_offset() -> float:
	if rod_root == null:
		return 0.0
	return rod_root.rotation.x - _rod_rest_rotation.x


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


func _update_aiming_line() -> void:
	var start := get_rod_tip_position()
	var forward := _get_cast_direction()
	var end := start + forward * 0.42 + Vector3.DOWN * 0.34
	var points := _build_sagging_line_points(start, end, 0.18, 0.035)
	_set_line_points(points, target_valid and player_near_water)


func _update_cast_motion(delta: float) -> void:
	_cast_elapsed += delta
	var progress := clampf(_cast_elapsed / _cast_duration, 0.0, 1.0)
	_update_cast_line(progress)
	if progress >= 1.0:
		_phase = CastPhase.LANDED_SLACK
		_landed_elapsed = 0.0
		_update_landed_line(0.0)


func _update_cast_line(progress: float) -> void:
	if lure_marker == null:
		return

	var eased := _ease_out_cubic(progress)
	var cast_vector := _cast_destination - _cast_start
	var cast_direction := cast_vector.normalized() if cast_vector.length_squared() > 0.0001 else Vector3.FORWARD
	var lure_position := _cast_start.lerp(_cast_destination, eased)
	var arc_height := sin(progress * PI) * 2.2
	lure_position += Vector3.UP * arc_height
	lure_marker.global_position = lure_position

	var start := get_rod_tip_position()
	var line_points := _build_casting_line_points(start, lure_position, cast_direction, progress, arc_height)
	_set_line_points(line_points, target_valid and player_near_water)


func _update_landed_line(delta: float) -> void:
	_landed_elapsed += delta
	if _landed_elapsed > 1.15:
		_phase = CastPhase.LANDED_TAUT

	var start := get_rod_tip_position()
	var end := _cast_destination
	if lure_marker != null:
		end = lure_marker.global_position

	var slack_amount := 0.75 if _phase == CastPhase.LANDED_SLACK else 0.14
	var lateral_sway := 0.18 if _phase == CastPhase.LANDED_SLACK else 0.04
	_set_line_points(_build_sagging_line_points(start, end, slack_amount, lateral_sway), target_valid and player_near_water)


func _set_line_points(points: Array[Vector3], line_valid: bool) -> void:
	_line_points_world = points.duplicate()
	if points.is_empty():
		_last_line_start = Vector3.ZERO
		_last_line_end = Vector3.ZERO
	else:
		_last_line_start = points.front()
		_last_line_end = points.back()
	_last_line_valid = line_valid


func _draw_projected_line() -> void:
	if line_overlay == null:
		return

	var camera_3d := _get_camera_3d()
	if camera_3d == null or _line_points_world.size() < 2:
		line_overlay.visible = false
		return

	var projected := PackedVector2Array()
	for point in _line_points_world:
		if camera_3d.is_position_behind(point):
			line_overlay.visible = false
			return
		projected.append(camera_3d.unproject_position(point))

	line_overlay.points = projected
	line_overlay.default_color = Color(0.82, 1.0, 0.78, 0.92) if _last_line_valid else Color(1.0, 0.35, 0.28, 0.92)
	line_overlay.visible = true


func _build_casting_line_points(start: Vector3, lure_position: Vector3, cast_direction: Vector3, progress: float, arc_height: float) -> Array[Vector3]:
	var right := cast_direction.cross(Vector3.UP).normalized()
	if right.length_squared() <= 0.0001:
		right = Vector3.RIGHT

	var unroll := sin(progress * PI)
	var trailing_pull := (1.0 - progress) * 0.75
	var loop_height := 0.45 + arc_height * 0.34 + unroll * 0.75
	var point_count := 17
	var points: Array[Vector3] = []
	for index in point_count:
		var t := float(index) / float(point_count - 1)
		var point := start.lerp(lure_position, t)
		var wave := sin((t * 1.35 - progress * 1.8) * TAU)
		var loop_envelope := sin(t * PI)
		var lead_lag := (1.0 - t) * trailing_pull
		var forward_lag := -cast_direction * lead_lag
		var vertical_loop := Vector3.UP * loop_height * loop_envelope * (1.0 - t * 0.45)
		var side_loop := right * wave * loop_envelope * (0.12 + unroll * 0.34)
		var gravity_sag := Vector3.DOWN * pow(t, 1.35) * (0.08 + progress * 0.18)
		points.append(point + forward_lag + vertical_loop + side_loop + gravity_sag)

	points[0] = start
	points[points.size() - 1] = lure_position
	return points


func _build_sagging_line_points(start: Vector3, end: Vector3, sag_amount: float, lateral_sway: float) -> Array[Vector3]:
	var direction := end - start
	var planar_direction := Vector3(direction.x, 0.0, direction.z)
	var right := planar_direction.normalized().cross(Vector3.UP).normalized() if planar_direction.length_squared() > 0.0001 else Vector3.RIGHT
	var point_count := 13
	var points: Array[Vector3] = []
	for index in point_count:
		var t := float(index) / float(point_count - 1)
		var sag_curve := sin(t * PI)
		var sway_curve := sin(t * TAU)
		var point := start.lerp(end, t)
		point += Vector3.DOWN * sag_amount * sag_curve
		point += right * lateral_sway * sway_curve * sag_curve
		points.append(point)

	points[0] = start
	points[points.size() - 1] = end
	return points


func _get_camera_3d() -> Camera3D:
	if camera is Camera3D:
		return camera as Camera3D
	if camera != null:
		var child_camera := camera.get_node_or_null("Camera3D") as Camera3D
		if child_camera != null:
			return child_camera
	return get_viewport().get_camera_3d()


func _update_rod_motion() -> void:
	if rod_root == null:
		return

	var target_rotation := _rod_rest_rotation
	if _phase == CastPhase.CASTING:
		var progress := clampf(_cast_elapsed / _cast_duration, 0.0, 1.0)
		if progress < 0.28:
			target_rotation = _rod_rest_rotation + Vector3(lerpf(0.0, 0.28, progress / 0.28), 0.0, 0.0)
		elif progress < 0.58:
			target_rotation = _rod_rest_rotation + Vector3(lerpf(0.28, -0.92, (progress - 0.28) / 0.3), 0.0, 0.0)
		else:
			target_rotation = _rod_rest_rotation + Vector3(lerpf(-0.92, -0.12, (progress - 0.58) / 0.42), 0.0, 0.0)
	elif _phase == CastPhase.LANDED_SLACK:
		target_rotation = _rod_rest_rotation + Vector3(-0.08, 0.0, 0.0)
	elif _phase == CastPhase.LANDED_TAUT:
		target_rotation = _rod_rest_rotation + Vector3(-0.03, 0.0, 0.0)

	_rod_cast_rotation = _rod_cast_rotation.lerp(target_rotation, 0.85)
	rod_root.rotation = _rod_cast_rotation


func _ease_out_cubic(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)


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

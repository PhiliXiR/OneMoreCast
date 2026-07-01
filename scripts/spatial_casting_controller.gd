extends Node3D

enum CastPhase { AIMING, CASTING, LANDED_SLACK, LANDED_TAUT }

@export var player_path: NodePath
@export var camera_path: NodePath
@export var target_marker_path: NodePath
@export var lure_marker_path: NodePath
@export var hooked_fish_marker_path: NodePath
@export var rod_root_path: NodePath
@export var rod_tip_path: NodePath
@export var fishing_line_path: NodePath
@export var line_overlay_path: NodePath
@export var landing_feedback_path: NodePath
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
@onready var hooked_fish_marker: MeshInstance3D = get_node_or_null(hooked_fish_marker_path) as MeshInstance3D
@onready var rod_root: Node3D = get_node_or_null(rod_root_path) as Node3D
@onready var rod_tip: Node3D = get_node_or_null(rod_tip_path) as Node3D
@onready var fishing_line: MeshInstance3D = get_node_or_null(fishing_line_path) as MeshInstance3D
@onready var line_overlay: Line2D = get_node_or_null(line_overlay_path) as Line2D
@onready var landing_feedback: Node3D = get_node_or_null(landing_feedback_path) as Node3D

var target_point := Vector3.ZERO
var target_valid := false
var player_near_water := false
var last_landing_quality := 0.0
var last_landing_label := "No cast yet"

var _valid_material := StandardMaterial3D.new()
var _invalid_material := StandardMaterial3D.new()
var _lure_material := StandardMaterial3D.new()
var _fish_material := StandardMaterial3D.new()
var _water_feedback_material := StandardMaterial3D.new()
var _miss_feedback_material := StandardMaterial3D.new()
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
var _landing_feedback_elapsed := 0.0
var _landing_feedback_duration := 0.9
var _landing_feedback_visible := false
var _landing_feedback_valid := false
var _landing_feedback_label := "none"
var _bite_feedback_active := false
var _bite_feedback_elapsed := 0.0
var _bite_feedback_duration := 0.85
var _bite_feedback_label := "none"
var _reel_feedback_active := false
var _reel_feedback_elapsed := 0.0
var _reel_feedback_duration := 1.2
var _reel_start := Vector3.ZERO
var _reel_end := Vector3.ZERO
var _reel_feedback_completed := false


func _ready() -> void:
	_valid_material.albedo_color = Color(0.32, 1.0, 0.74, 0.55)
	_invalid_material.albedo_color = Color(1.0, 0.32, 0.24, 0.55)
	_lure_material.albedo_color = Color(1.0, 0.88, 0.3, 1.0)
	_fish_material.albedo_color = Color(0.22, 0.74, 0.92, 1.0)
	_configure_marker_material(_valid_material, Color(0.32, 1.0, 0.74, 0.55))
	_configure_marker_material(_invalid_material, Color(1.0, 0.32, 0.24, 0.55))
	_configure_marker_material(_lure_material, Color(1.0, 0.88, 0.25, 1.0))
	_configure_fish_material()
	_configure_feedback_material(_water_feedback_material, Color(0.65, 0.95, 1.0, 0.82))
	_configure_feedback_material(_miss_feedback_material, Color(1.0, 0.38, 0.12, 0.82))
	if lure_marker != null:
		lure_marker.visible = false
		lure_marker.material_override = _lure_material
	if hooked_fish_marker != null:
		hooked_fish_marker.visible = false
		hooked_fish_marker.material_override = _fish_material
	if fishing_line != null:
		fishing_line.visible = false
	if line_overlay != null:
		line_overlay.visible = false
		line_overlay.width = 1.35
	if rod_root != null:
		_rod_rest_rotation = rod_root.rotation
		_rod_cast_rotation = _rod_rest_rotation
	_configure_landing_feedback()


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
	_update_landing_feedback(delta)
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
	_hide_landing_feedback(true)
	_stop_bite_feedback(true)
	_stop_reel_feedback()
	_reel_feedback_completed = false
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


func get_landing_feedback_label() -> String:
	return _landing_feedback_label


func is_landing_feedback_visible() -> bool:
	return _landing_feedback_visible


func did_last_cast_land_in_water() -> bool:
	return last_landing_quality > 0.0


func is_cast_landed() -> bool:
	return _phase == CastPhase.LANDED_SLACK or _phase == CastPhase.LANDED_TAUT


func get_waiting_for_bite_duration() -> float:
	if last_landing_quality <= 0.0:
		return 0.0
	return lerpf(1.25, 0.65, last_landing_quality)


func trigger_bite_feedback() -> bool:
	if not did_last_cast_land_in_water() or not is_cast_landed():
		return false

	_bite_feedback_active = true
	_bite_feedback_elapsed = 0.0
	_bite_feedback_label = "bite twitch"
	return true


func is_bite_feedback_active() -> bool:
	return _bite_feedback_active


func get_bite_feedback_label() -> String:
	return _bite_feedback_label


func begin_reel_feedback(duration := 1.2) -> bool:
	if not did_last_cast_land_in_water() or not is_cast_landed():
		return false

	_stop_bite_feedback()
	_reel_feedback_active = true
	_reel_feedback_completed = false
	_reel_feedback_elapsed = 0.0
	_reel_feedback_duration = maxf(duration, 0.1)
	_reel_start = _cast_destination
	_reel_end = get_rod_tip_position() + _get_cast_direction() * 0.55 + Vector3.DOWN * 0.22
	if lure_marker != null:
		lure_marker.visible = true
		lure_marker.global_position = _reel_start
	if hooked_fish_marker != null:
		hooked_fish_marker.visible = true
		hooked_fish_marker.global_position = _get_hooked_fish_position(_reel_start, 0.0)
	_update_reel_feedback(0.0)
	return true


func is_reel_feedback_active() -> bool:
	return _reel_feedback_active


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
		_show_landing_feedback(_cast_destination, target_valid and player_near_water)
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
	_update_bite_feedback(delta)
	_update_reel_feedback(delta)
	if _landed_elapsed > 1.15:
		_phase = CastPhase.LANDED_TAUT

	var start := get_rod_tip_position()
	var end := _cast_destination
	if lure_marker != null:
		if _reel_feedback_active:
			lure_marker.global_position = _get_reel_position()
		elif _reel_feedback_completed:
			lure_marker.global_position = _reel_end
		elif _bite_feedback_active:
			lure_marker.global_position = _cast_destination + _get_bite_feedback_offset()
		else:
			lure_marker.global_position = _cast_destination
		end = lure_marker.global_position

	var bite_sag := 0.16 if _bite_feedback_active else 0.0
	var bite_sway := 0.1 if _bite_feedback_active else 0.0
	var reel_tension := _get_reel_progress() if (_reel_feedback_active or _reel_feedback_completed) else 0.0
	var slack_amount := (0.75 if _phase == CastPhase.LANDED_SLACK else 0.14) + bite_sag
	var lateral_sway := (0.18 if _phase == CastPhase.LANDED_SLACK else 0.04) + bite_sway
	slack_amount = lerpf(slack_amount, 0.05, reel_tension)
	lateral_sway = lerpf(lateral_sway, 0.02, reel_tension)
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
	if _bite_feedback_active:
		var pulse := sin(clampf(_bite_feedback_elapsed / _bite_feedback_duration, 0.0, 1.0) * PI * 5.0)
		target_rotation += Vector3(-0.12 * pulse, 0.0, 0.0)
	if _reel_feedback_active:
		var reel_pulse := sin(_get_reel_progress() * PI * 6.0)
		target_rotation += Vector3(-0.08 - 0.05 * reel_pulse, 0.0, 0.0)

	_rod_cast_rotation = _rod_cast_rotation.lerp(target_rotation, 0.85)
	rod_root.rotation = _rod_cast_rotation


func _configure_landing_feedback() -> void:
	if landing_feedback == null:
		return

	landing_feedback.visible = false
	var water_ripple_outer := landing_feedback.get_node_or_null("WaterRippleOuter") as MeshInstance3D
	var water_ripple_inner := landing_feedback.get_node_or_null("WaterRippleInner") as MeshInstance3D
	var miss_puff := landing_feedback.get_node_or_null("MissPuff") as MeshInstance3D
	if water_ripple_outer != null:
		water_ripple_outer.material_override = _water_feedback_material
	if water_ripple_inner != null:
		water_ripple_inner.material_override = _water_feedback_material
	if miss_puff != null:
		miss_puff.material_override = _miss_feedback_material


func _show_landing_feedback(position: Vector3, landed_in_water: bool) -> void:
	_landing_feedback_elapsed = 0.0
	_landing_feedback_visible = landing_feedback != null
	_landing_feedback_valid = landed_in_water
	_landing_feedback_label = "water splash" if landed_in_water else "miss puff"
	if landing_feedback == null:
		return

	landing_feedback.visible = true
	landing_feedback.global_position = position + Vector3.UP * (0.03 if landed_in_water else 0.14)
	_set_feedback_child_visible("WaterRippleOuter", landed_in_water)
	_set_feedback_child_visible("WaterRippleInner", landed_in_water)
	_set_feedback_child_visible("MissPuff", not landed_in_water)
	_update_landing_feedback(0.0)


func _hide_landing_feedback(reset_label := false) -> void:
	_landing_feedback_elapsed = 0.0
	_landing_feedback_visible = false
	if reset_label:
		_landing_feedback_label = "none"
	if landing_feedback != null:
		landing_feedback.visible = false


func _set_feedback_child_visible(path: NodePath, is_visible: bool) -> void:
	if landing_feedback == null:
		return
	var child := landing_feedback.get_node_or_null(path) as Node3D
	if child != null:
		child.visible = is_visible


func _update_landing_feedback(delta: float) -> void:
	if not _landing_feedback_visible or landing_feedback == null:
		return

	_landing_feedback_elapsed += delta
	var progress := clampf(_landing_feedback_elapsed / _landing_feedback_duration, 0.0, 1.0)
	var fade := 1.0 - progress
	if _landing_feedback_valid:
		var outer := landing_feedback.get_node_or_null("WaterRippleOuter") as Node3D
		var inner := landing_feedback.get_node_or_null("WaterRippleInner") as Node3D
		if outer != null:
			outer.scale = Vector3.ONE * lerpf(0.35, 1.9, progress)
		if inner != null:
			inner.scale = Vector3.ONE * lerpf(0.18, 1.0, progress)
		_water_feedback_material.albedo_color.a = 0.82 * fade
	else:
		var puff := landing_feedback.get_node_or_null("MissPuff") as Node3D
		if puff != null:
			puff.scale = Vector3.ONE * lerpf(0.5, 1.25, progress)
			puff.position.y = lerpf(0.0, 0.22, progress)
		_miss_feedback_material.albedo_color.a = 0.82 * fade

	if progress >= 1.0:
		_hide_landing_feedback()


func _update_bite_feedback(delta: float) -> void:
	if not _bite_feedback_active:
		return

	_bite_feedback_elapsed += delta
	if _bite_feedback_elapsed >= _bite_feedback_duration:
		_stop_bite_feedback()


func _get_bite_feedback_offset() -> Vector3:
	if not _bite_feedback_active:
		return Vector3.ZERO

	var progress := clampf(_bite_feedback_elapsed / _bite_feedback_duration, 0.0, 1.0)
	var pulse := sin(progress * PI * 6.0)
	var cast_direction := (_cast_destination - _cast_start).normalized()
	if cast_direction.length_squared() <= 0.0001:
		cast_direction = Vector3.FORWARD
	var side := cast_direction.cross(Vector3.UP).normalized()
	if side.length_squared() <= 0.0001:
		side = Vector3.RIGHT
	return side * pulse * 0.18 + Vector3.DOWN * absf(pulse) * 0.12


func _stop_bite_feedback(reset_label := false) -> void:
	_bite_feedback_active = false
	_bite_feedback_elapsed = 0.0
	if reset_label:
		_bite_feedback_label = "none"
	if lure_marker != null and is_cast_landed():
		lure_marker.global_position = _cast_destination


func _update_reel_feedback(delta: float) -> void:
	if not _reel_feedback_active:
		return

	_reel_feedback_elapsed += delta
	var position := _get_reel_position()
	if lure_marker != null:
		lure_marker.global_position = position
	if hooked_fish_marker != null:
		hooked_fish_marker.global_position = _get_hooked_fish_position(position, _get_reel_progress())
		hooked_fish_marker.rotation.y += delta * 7.0
	if _reel_feedback_elapsed >= _reel_feedback_duration:
		_reel_feedback_active = false
		_reel_feedback_completed = true
		if lure_marker != null:
			lure_marker.global_position = _reel_end
		if hooked_fish_marker != null:
			hooked_fish_marker.visible = false


func _get_reel_progress() -> float:
	if _reel_feedback_duration <= 0.0:
		return 1.0
	return clampf(_reel_feedback_elapsed / _reel_feedback_duration, 0.0, 1.0)


func _get_reel_position() -> Vector3:
	var progress := _ease_out_cubic(_get_reel_progress())
	var position := _reel_start.lerp(_reel_end, progress)
	position += Vector3.UP * sin(progress * PI) * 0.35
	return position


func _get_hooked_fish_position(line_position: Vector3, progress: float) -> Vector3:
	var underwater_y := water_center.y - 0.22
	var emerge_progress := clampf((progress - 0.68) / 0.32, 0.0, 1.0)
	var fish_position := line_position + Vector3.DOWN * 0.28
	fish_position.y = lerpf(underwater_y, line_position.y - 0.16, emerge_progress)
	fish_position.y += sin(progress * PI * 8.0) * 0.05
	return fish_position


func _stop_reel_feedback() -> void:
	_reel_feedback_active = false
	_reel_feedback_elapsed = 0.0
	_reel_feedback_completed = false
	if hooked_fish_marker != null:
		hooked_fish_marker.visible = false


func _ease_out_cubic(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)


func _configure_marker_material(material: StandardMaterial3D, color: Color) -> void:
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = 0.75
	material.no_depth_test = true


func _configure_feedback_material(material: StandardMaterial3D, color: Color) -> void:
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = 0.9


func _configure_fish_material() -> void:
	_fish_material.roughness = 0.42
	_fish_material.metallic = 0.0
	_fish_material.albedo_color = Color(0.22, 0.74, 0.92, 1.0)


func _apply_marker_material(root: Node, material: StandardMaterial3D) -> void:
	if root is MeshInstance3D:
		(root as MeshInstance3D).material_override = material
	for child in root.get_children():
		_apply_marker_material(child, material)

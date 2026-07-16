class_name CinematicWaterLens
extends Node3D

## Game-owned prototype for proving authored fight framing before any pipeline promotion.
enum Shot { WIDE, PURSUIT, CLOSE_UP, LANDING }
enum ShotPolicy { WATER_READ, LINE_PULL, LANDING_FOCUS }

const SHOT_POLICY_NAMES := ["water read", "line pull", "landing focus"]

@export var hooked_fish_path: NodePath
@export var hook_path: NodePath
@export var water_lens_panel_path: NodePath
@export var water_lens_texture_path: NodePath
@export var water_lens_caption_path: NodePath
@export var water_level := 0.0

@onready var hooked_fish: Node3D = get_node_or_null(hooked_fish_path) as Node3D
@onready var hook: Node3D = get_node_or_null(hook_path) as Node3D
@onready var lens_panel: Control = get_node_or_null(water_lens_panel_path) as Control
@onready var lens_texture: TextureRect = get_node_or_null(water_lens_texture_path) as TextureRect
@onready var lens_caption: Label = get_node_or_null(water_lens_caption_path) as Label
@onready var viewport: SubViewport = $SubViewport
@onready var camera: Camera3D = $SubViewport/Camera3D

var active_shot := Shot.WIDE
var active_shot_policy := ShotPolicy.LINE_PULL
var _active := false
var _phase := FishFightModel.Phase.RECOVERY
var _landing_progress := 0.0
var _danger := false


func _ready() -> void:
	viewport.world_3d = get_viewport().world_3d
	if lens_texture != null:
		lens_texture.texture = viewport.get_texture()
	if lens_panel != null:
		lens_panel.visible = false
		_style_lens()
		_layout_lens()
	get_viewport().size_changed.connect(_layout_lens)


func begin_fight() -> void:
	_active = true
	_landing_progress = 0.0
	_danger = false
	_set_shot(Shot.WIDE)
	if lens_panel != null:
		lens_panel.visible = true


func set_shot_policy(policy_name: String) -> void:
	var policy_index := SHOT_POLICY_NAMES.find(policy_name.to_lower())
	if policy_index == -1:
		push_warning("Unknown Water Lens shot policy: %s" % policy_name)
		return
	active_shot_policy = policy_index as ShotPolicy


func get_active_shot_policy_name() -> String:
	return SHOT_POLICY_NAMES[active_shot_policy]


func get_shot_policy_names() -> Array[String]:
	return SHOT_POLICY_NAMES.duplicate()


func apply_fight_snapshot(snapshot: Dictionary) -> void:
	if not _active:
		return
	_phase = int(snapshot.get("phase", FishFightModel.Phase.RECOVERY))
	_landing_progress = clampf(float(snapshot.get("landing_progress", 0.0)), 0.0, 1.0)
	_danger = float(snapshot.get("high_tension_danger", 0.0)) > 0.0 or float(snapshot.get("slack_danger", 0.0)) > 0.0
	_set_shot(_select_shot())


func present_landed_fish() -> void:
	if not _active:
		return
	_landing_progress = 1.0
	_set_shot(Shot.LANDING)


func end_fight() -> void:
	_active = false
	if lens_panel != null:
		lens_panel.visible = false


func get_active_shot_name() -> String:
	return ["wide", "pursuit", "close-up", "landing"][active_shot]


func _process(_delta: float) -> void:
	if not _active or hooked_fish == null:
		return
	_update_camera()


func _select_shot() -> Shot:
	match active_shot_policy:
		ShotPolicy.WATER_READ:
			return Shot.LANDING if _landing_progress >= 0.96 else Shot.WIDE
		ShotPolicy.LINE_PULL:
			if _landing_progress >= 0.92:
				return Shot.LANDING
			if _phase != FishFightModel.Phase.RECOVERY or _danger:
				return Shot.CLOSE_UP
			return Shot.PURSUIT
		ShotPolicy.LANDING_FOCUS:
			if _landing_progress >= 0.45:
				return Shot.LANDING
			return Shot.CLOSE_UP if _phase != FishFightModel.Phase.RECOVERY or _danger else Shot.PURSUIT
	return Shot.PURSUIT


func _set_shot(next_shot: Shot) -> void:
	active_shot = next_shot
	if lens_caption != null:
		lens_caption.text = "HOOKED FISH  ·  %s" % get_active_shot_name().to_upper()
	_update_camera()


func _update_camera() -> void:
	if hooked_fish == null:
		return
	var fish_position := hooked_fish.global_position
	var hook_position := hook.global_position if hook != null else fish_position
	var direction := (hook_position - fish_position).normalized()
	if direction.length_squared() < 0.001:
		direction = Vector3.FORWARD
	var offset := Vector3(0.0, 1.7, -4.2)
	var look_target := fish_position
	match active_shot:
		Shot.WIDE:
			offset = Vector3(-3.6, 2.8, -5.8)
			look_target = fish_position.lerp(hook_position, 0.28)
		Shot.PURSUIT:
			offset = -direction * 2.6 + Vector3(0.0, 0.38, 0.0)
		Shot.CLOSE_UP:
			offset = -direction * 1.15 + Vector3(0.0, -0.16, 0.42)
		Shot.LANDING:
			offset = -direction * 1.85 + Vector3(0.0, 1.0, 0.35)
	var desired := fish_position + offset
	if active_shot != Shot.WIDE:
		desired.y = minf(desired.y, water_level - 0.12)
	camera.global_position = camera.global_position.lerp(desired, 0.16)
	camera.look_at(look_target + Vector3(0.0, -0.06, 0.0), Vector3.UP)


func _layout_lens() -> void:
	if lens_panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var width := clampf(viewport_size.x * 0.27, 280.0, 440.0)
	var height := width * 0.62
	lens_panel.position = Vector2(viewport_size.x - width - 24.0, 72.0)
	lens_panel.size = Vector2(width, height)


func _style_lens() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("182c36")
	frame.border_color = Color("bda770")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(3)
	frame.content_margin_left = 5.0
	frame.content_margin_top = 5.0
	frame.content_margin_right = 5.0
	frame.content_margin_bottom = 5.0
	lens_panel.add_theme_stylebox_override("panel", frame)

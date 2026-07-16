extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const HORIZON_LOOK_TARGET := Vector3(0.0, 2.0, 31.0)
const OPENING_VIEWPOINT := Vector3(0.0, 1.55, -2.0)
const FISHING_VIEWPOINTS := [OPENING_VIEWPOINT, Vector3(-1.7, 1.55, 2.5), Vector3(1.8, 1.55, 2.5)]
const SCREEN_EDGE_MARGIN_PX := 12.0
const SHORE_SILHOUETTE_NODES := ["DistantShore", "NearTreeLine", "HighRidge"]
const REQUIRED_PINE_VARIANT_PATHS := {
	"LandmarkPine": "res://assets/foliage/home_water_pine_landmark.glb",
	"StandardPine": "res://assets/foliage/home_water_pine_standard.glb",
	"LeaningPine": "res://assets/foliage/home_water_pine_leaning.glb",
}
const MIN_WATER_LUMINANCE_SEPARATION := 0.06
const MIN_FOG_LUMINANCE_SEPARATION := 0.2
# Matches the lake shader's authored deep_color default. Shader defaults are
# not readable from ShaderMaterial until explicitly assigned at runtime.
const DEEP_LAKE_COLOR := Color(0.015, 0.12, 0.24, 0.91)


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load(WORLD_SCENE) as PackedScene
	if packed_scene == null:
		_fail("Could not load %s" % WORLD_SCENE)
		return
	var world := packed_scene.instantiate()
	root.add_child(world)
	await process_frame

	var presentation := world.get_node_or_null("HomeWater/Presentation") as HomeWaterPresentation
	var horizon := world.get_node_or_null("HomeWater/Presentation/FarBankSilhouette") as Node3D
	if presentation == null or horizon == null or not presentation.has_layered_far_horizon():
		_fail("Home water needs a layered far-bank silhouette and watershed hint")
		return
	if horizon.get_meta("interactive", true) or _has_collision_shape(horizon):
		_fail("Far-bank horizon must remain non-interactive dressing")
		return
	var tree_line := horizon.get_node_or_null(HomeWaterPresentation.PINE_TREE_LINE_NAME) as Node3D
	if tree_line == null or tree_line.get_meta("interactive", true) or _has_collision_shape(tree_line):
		_fail("Approved Pine kit tree line must remain non-interactive dressing")
		return
	for variant_name in REQUIRED_PINE_VARIANT_PATHS:
		var variant := tree_line.get_node_or_null(variant_name) as Node3D
		if variant == null or not variant.get_meta("approved_asset", false) or variant.get_meta("asset_path", "") != REQUIRED_PINE_VARIANT_PATHS[variant_name] or variant.get_meta("interactive", true) or _has_collision_shape(variant):
			_fail("Far-bank tree line must use approved non-interactive Pine kit variants")
			return
	var tree_line_view_anchor := tree_line.get_node_or_null(HomeWaterPresentation.PINE_TREE_LINE_VIEW_ANCHOR_NAME) as Marker3D
	if tree_line_view_anchor == null:
		_fail("Far-bank Pine kit needs a composition-level fishing-view anchor")
		return
	var marker := horizon.get_node_or_null(HomeWaterPresentation.WATERSHED_MARKER_NAME) as Node3D
	if marker == null or marker.get_meta("interactive", true):
		_fail("Watershed hint must remain a non-interactive distant landmark")
		return
	if not _has_dawn_fog_contrast(world, horizon):
		return
	var camera := world.get_node_or_null("MMOCameraRig/Camera3D") as Camera3D
	if camera == null:
		_fail("Focused horizon validation needs the player's camera")
		return
	var viewport_size := root.get_viewport().get_visible_rect().size
	for viewpoint in FISHING_VIEWPOINTS:
		camera.global_position = viewpoint
		camera.look_at(HORIZON_LOOK_TARGET, Vector3.UP)
		for silhouette_name in SHORE_SILHOUETTE_NODES:
			var silhouette := horizon.get_node_or_null(silhouette_name) as Node3D
			if silhouette == null or not _is_visible_in_camera(camera, silhouette.global_position, viewport_size):
				_fail("Far-bank silhouette layers must be visible from likely fishing viewpoints")
				return
		if not _is_visible_in_camera(camera, tree_line_view_anchor.global_position, viewport_size):
			_fail("Approved Pine kit tree line must remain visible from likely fishing viewpoints")
			return
		if not _is_visible_in_camera(camera, marker.global_position, viewport_size):
			_fail("Watershed marker must remain a readable but distant horizon detail")
			return

	print("Far-bank horizon validation passed")
	quit(0)


func _has_dawn_fog_contrast(world: Node, horizon: Node3D) -> bool:
	var environment_node := world.get_node_or_null("DawnEnvironment") as WorldEnvironment
	if environment_node == null or environment_node.environment == null or world.get_node_or_null("LakeSurface") == null:
		_fail("Focused horizon validation needs the dawn environment and lake surface")
		return false
	var fog_color := environment_node.environment.fog_light_color
	for silhouette_name in SHORE_SILHOUETTE_NODES:
		var silhouette := horizon.get_node_or_null(silhouette_name) as MeshInstance3D
		var material := silhouette.material_override as StandardMaterial3D if silhouette != null else null
		if material == null:
			_fail("Far-bank silhouette needs readable dawn materials")
			return false
		var silhouette_luminance := _luminance(material.albedo_color)
		if absf(silhouette_luminance - _luminance(DEEP_LAKE_COLOR)) < MIN_WATER_LUMINANCE_SEPARATION or absf(silhouette_luminance - _luminance(fog_color)) < MIN_FOG_LUMINANCE_SEPARATION:
			_fail("Far-bank silhouette must retain contrast against the lake and dawn fog")
			return false
	return true


func _luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722


func _has_collision_shape(node: Node) -> bool:
	if node is CollisionShape3D:
		return true
	for child in node.get_children():
		if _has_collision_shape(child):
			return true
	return false


func _is_visible_in_camera(camera: Camera3D, world_position: Vector3, viewport_size: Vector2) -> bool:
	if camera.is_position_behind(world_position):
		return false
	return Rect2(Vector2.ZERO, viewport_size).grow(-SCREEN_EDGE_MARGIN_PX).has_point(camera.unproject_position(world_position))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

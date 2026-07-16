extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"
const REQUIRED_VARIANT_PATHS := {
	"CottageLandmarkPine": "res://assets/foliage/home_water_pine_landmark.glb",
	"CottageStandardPine": "res://assets/foliage/home_water_pine_standard.glb",
	"CottageLeaningPine": "res://assets/foliage/home_water_pine_leaning.glb",
	"InletLeaningPine": "res://assets/foliage/home_water_pine_leaning.glb",
	"InletStandardPine": "res://assets/foliage/home_water_pine_standard.glb",
	"InletLandmarkPine": "res://assets/foliage/home_water_pine_landmark.glb",
}
const SCREEN_EDGE_MARGIN_PX := 12.0
const COTTAGE_VIEWPOINT := Vector3(-0.65, 1.55, 2.5)
const COTTAGE_LOOK_TARGET := Vector3(5.9, 1.6, -5.7)
const INLET_VIEWPOINT := Vector3(0.0, 1.55, -2.0)
const INLET_LOOK_TARGET := Vector3(8.7, 0.9, 5.4)
const FAR_BANK_VIEWPOINT := Vector3(0.0, 1.55, -2.0)
const FAR_BANK_LOOK_TARGET := Vector3(-8.5, 0.8, 2.4)


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
	if presentation == null:
		_fail("Home water needs its presentation builder")
		return
	var clusters := presentation.get_node_or_null(HomeWaterPresentation.SHORE_TREE_CLUSTERS_NAME) as Node3D
	if clusters == null or clusters.get_meta("interactive", true) or _has_collision_shape(clusters):
		_fail("Shore tree clusters must remain non-interactive scenery")
		return
	for cluster_name in [HomeWaterPresentation.COTTAGE_TREE_CLUSTER_NAME, HomeWaterPresentation.INLET_TREE_CLUSTER_NAME]:
		var cluster := clusters.get_node_or_null(cluster_name) as Node3D
		if cluster == null or cluster.get_meta("interactive", true) or _has_collision_shape(cluster):
			_fail("Shore tree cluster %s must remain visual-only" % cluster_name)
			return
	for pine_name in REQUIRED_VARIANT_PATHS:
		var pine := clusters.find_child(pine_name, true, false) as Node3D
		if pine == null or not pine.get_meta("approved_asset", false) or pine.get_meta("asset_path", "") != REQUIRED_VARIANT_PATHS[pine_name] or pine.get_meta("interactive", true) or _has_collision_shape(pine):
			_fail("Shore tree clusters must use approved non-interactive Pine kit variants")
			return
	if not presentation.has_clear_shore_tree_cluster_clearances():
		_fail("Shore trees must preserve the cottage entry, dock approach, and inlet cue")
		return
	if world.get_node_or_null("HomeWater/VegetatedInlet") == null or world.get_node_or_null("HomeWater/DeepRockyFarBank") == null:
		_fail("Shore trees must preserve named micro-habitat anchors")
		return
	if not _validate_dawn_views(world, clusters):
		return

	print("Shore tree cluster validation passed")
	quit(0)


func _validate_dawn_views(world: Node, clusters: Node3D) -> bool:
	var camera := world.get_node_or_null("MMOCameraRig/Camera3D") as Camera3D
	var cottage_entry := world.get_node_or_null("HomeWater/Presentation/HomeCottageExterior/EntryMarker") as Marker3D
	var inlet := world.get_node_or_null("HomeWater/VegetatedInlet") as Node3D
	var far_bank := world.get_node_or_null("HomeWater/DeepRockyFarBank/RockShelfOne") as Node3D
	var cottage_pine := clusters.get_node_or_null("CottageTreeCluster/CottageLandmarkPine") as Node3D
	var inlet_pine := clusters.get_node_or_null("InletTreeCluster/InletLeaningPine") as Node3D
	if camera == null or cottage_entry == null or inlet == null or far_bank == null or cottage_pine == null or inlet_pine == null:
		_fail("Dawn review needs the camera, shore clusters, and named micro-habitat cues")
		return false
	var viewport_size := root.get_viewport().get_visible_rect().size
	camera.global_position = COTTAGE_VIEWPOINT
	camera.look_at(COTTAGE_LOOK_TARGET, Vector3.UP)
	if not _is_visible_in_camera(camera, cottage_entry.global_position, viewport_size) or not _is_visible_in_camera(camera, cottage_pine.global_position, viewport_size):
		_fail("Cottage entry and its framing tree cluster must remain readable from a normal shore view")
		return false
	camera.global_position = INLET_VIEWPOINT
	camera.look_at(INLET_LOOK_TARGET, Vector3.UP)
	if not _is_visible_in_camera(camera, inlet.global_position + Vector3.UP * 0.8, viewport_size) or not _is_visible_in_camera(camera, inlet_pine.global_position, viewport_size):
		_fail("Vegetated inlet and its framing tree cluster must remain readable from a fishing view")
		return false
	camera.global_position = FAR_BANK_VIEWPOINT
	camera.look_at(FAR_BANK_LOOK_TARGET, Vector3.UP)
	if not _is_visible_in_camera(camera, far_bank.global_position, viewport_size):
		_fail("Deep rocky far bank must remain visually distinguishable from the inlet")
		return false
	return true


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

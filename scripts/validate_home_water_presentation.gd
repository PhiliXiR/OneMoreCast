extends SceneTree

const WORLD_SCENE := "res://scenes/world_prototype.tscn"


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

	var environment_node := world.get_node_or_null("DawnEnvironment") as WorldEnvironment
	if environment_node == null or environment_node.environment == null:
		_fail("Home water needs a configured dawn environment")
		return
	var environment := environment_node.environment
	if environment.background_mode != Environment.BG_SKY or environment.sky == null:
		_fail("Home water needs a procedural dawn sky")
		return
	if environment.ambient_light_energy <= 0.0 or not environment.fog_enabled or environment.fog_density <= 0.0:
		_fail("Dawn presentation needs cool ambient light and restrained distance mist")
		return
	if not _has_edge_free_world_scale(world):
		return
	var sun := world.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun == null or sun.light_energy <= 0.0 or sun.light_color.r <= sun.light_color.b:
		_fail("Dawn presentation needs warm low-angle sunlight")
		return

	var presentation := world.get_node_or_null("HomeWater/Presentation") as Node3D
	if presentation == null:
		_fail("Home water needs its game-owned procedural presentation builder")
		return
	if not presentation.has_natural_shore_collision():
		_fail("Presentation must create natural shore collision")
		return
	var cottage := presentation.get_node_or_null("HomeCottageExterior") as Node3D
	if cottage == null or not cottage.get_meta("approved_asset", false) or cottage.get_node_or_null("EntryMarker") == null or presentation.get_node_or_null("DocksideCottage") != null:
		_fail("Home Cottage exterior must use the approved asset, not the temporary procedural cottage")
		return
	var entry_marker := cottage.get_node("EntryMarker") as Marker3D
	if entry_marker.global_position.z <= cottage.global_position.z:
		_fail("Home Cottage entry must remain on the approved asset's dock-facing porch")
		return
	if presentation.get_node_or_null("ProceduralInletDressing/InletReed00") == null or presentation.get_node_or_null("ProceduralRockyFarBank/FarBankRock00") == null:
		_fail("Inlet and far-bank fishing implications need distinct procedural dressing")
		return
	if not presentation.has_layered_far_horizon():
		_fail("Home water needs the approved Pine kit to compose its far-bank tree line")
		return
	if world.get_node_or_null("HomeWater/VegetatedInlet") == null or world.get_node_or_null("HomeWater/DeepRockyFarBank") == null:
		_fail("Existing named micro-habitat anchors must remain available to fishing conditions")
		return
	if not _validate_fishing_readability(world):
		return

	print("Home-water dawn presentation validation passed")
	quit(0)


func _validate_fishing_readability(world: Node) -> bool:
	var spatial := world.get_node_or_null("SpatialCasting") as Node
	var target := world.get_node_or_null("CastTargetMarker") as Node3D
	var target_disc := world.get_node_or_null("CastTargetMarker/TargetDisc") as MeshInstance3D
	var line := world.get_node_or_null("LineOverlayLayer/FishingLineOverlay") as Line2D
	var hooked_fish := world.get_node_or_null("HookedFishMarker") as Node3D
	var casting_ui := world.get_node_or_null("CastingUILayer/CastingUI") as CanvasItem
	if spatial == null or target == null or target_disc == null or line == null or hooked_fish == null or casting_ui == null:
		_fail("Dawn presentation must preserve the fishing readability seams")
		return false
	spatial.call("refresh_casting_visuals", 0.0)
	var target_material := target_disc.material_override as StandardMaterial3D
	if not target.visible or target_material == null or not target_material.emission_enabled:
		_fail("Cast marker must remain bright and visible under dawn lighting")
		return false
	spatial.call("begin_cast")
	for frame in 11:
		spatial.call("refresh_casting_visuals", 0.08)
	if not (spatial.call("is_cast_landed") as bool) or not line.visible or line.width < 1.0 or not casting_ui.visible:
		_fail("Landed tackle, line overlay, and HUD must remain readable at dawn")
		return false
	if not (spatial.call("trigger_bite_feedback") as bool):
		_fail("Focused validation could not trigger the bite signal")
		return false
	spatial.call("refresh_casting_visuals", 0.08)
	if not (spatial.call("is_bite_feedback_active") as bool) or spatial.call("get_bite_feedback_label") != "bite twitch":
		_fail("Bite signal must remain an explicit readable state")
		return false
	if not (spatial.call("begin_reel_feedback", 1.2) as bool):
		_fail("Focused validation could not enter the hooked-fish presentation")
		return false
	spatial.call("refresh_casting_visuals", 0.08)
	if not hooked_fish.visible or not (spatial.call("is_line_showing_valid_feedback") as bool):
		_fail("Hooked fish and fishing line must remain readable under dawn presentation")
		return false
	return true


func _has_edge_free_world_scale(world: Node) -> bool:
	var lake := world.get_node_or_null("LakeSurface/Mesh") as MeshInstance3D
	var ground := world.get_node_or_null("Ground/MeshInstance3D") as MeshInstance3D
	var spatial := world.get_node_or_null("SpatialCasting") as Node
	if lake == null or ground == null or spatial == null:
		_fail("Home water needs its lake, shore ground, and casting bounds")
		return false
	var lake_mesh := lake.mesh as PlaneMesh
	var ground_mesh := ground.mesh as BoxMesh
	if lake_mesh == null or ground_mesh == null:
		_fail("Home water needs scalable lake and shore meshes")
		return false
	if lake_mesh.size.x < 120.0 or lake_mesh.size.y < 800.0:
		_fail("Lake surface must extend beyond any playable camera view")
		return false
	if ground_mesh.size.x < 120.0 or ground_mesh.size.z < 160.0:
		_fail("Shore ground must extend beyond the visible dockside")
		return false
	var water_size := spatial.get("water_size") as Vector2
	if water_size.x != lake_mesh.size.x or water_size.y != lake_mesh.size.y:
		_fail("Fishing bounds must match the expanded lake surface")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

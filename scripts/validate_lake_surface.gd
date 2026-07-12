extends SceneTree

const LAKE_SURFACE_SCENE := "res://world/lake_surface.tscn"


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load(LAKE_SURFACE_SCENE) as PackedScene
	if packed_scene == null:
		_fail("Could not load reusable lake surface: %s" % LAKE_SURFACE_SCENE)
		return

	var lake_surface := packed_scene.instantiate()
	root.add_child(lake_surface)
	if not lake_surface.has_signal("localized_reaction_requested"):
		_fail("Lake surface is missing its localized reaction boundary")
		return
	if not lake_surface.has_method("request_localized_reaction"):
		_fail("Lake surface cannot receive localized reaction requests")
		return
	if not lake_surface.has_method("request_cast_entry") or not lake_surface.has_method("set_waiting_lure_reaction"):
		_fail("Lake surface is missing semantic cast-entry or waiting-lure reactions")
		return

	var observed_reaction := {}
	lake_surface.localized_reaction_requested.connect(
		func(world_position: Vector3, strength: float, radius: float) -> void:
			observed_reaction["world_position"] = world_position
			observed_reaction["strength"] = strength
			observed_reaction["radius"] = radius
	)
	lake_surface.request_localized_reaction(Vector3(2.0, 0.0, 7.0), 0.75, 1.5)
	if observed_reaction != {
		"world_position": Vector3(2.0, 0.0, 7.0),
		"strength": 0.75,
		"radius": 1.5,
	}:
		_fail("Lake surface did not preserve the semantic localized reaction request")
		return
	var observed_semantic_reactions: Array = []
	lake_surface.reaction_requested.connect(
		func(reaction: LakeSurface.Reaction, world_position: Vector3, strength: float, radius: float) -> void:
			observed_semantic_reactions.append([reaction, world_position, strength, radius])
	)
	lake_surface.request_cast_entry(Vector3(1.0, 0.0, 8.0), 0.8, 1.2)
	lake_surface.set_waiting_lure_reaction(Vector3(1.0, 0.0, 8.0), true)
	if not lake_surface.is_cast_entry_reaction_active() or not lake_surface.is_waiting_lure_reaction_active():
		_fail("Lake surface did not retain active semantic reactions")
		return
	if observed_semantic_reactions.size() != 2 or observed_semantic_reactions[0][0] != LakeSurface.Reaction.CAST_ENTRY or observed_semantic_reactions[1][0] != LakeSurface.Reaction.WAITING_LURE:
		_fail("Lake surface did not expose cast-entry and waiting-lure reactions distinctly")
		return

	var mesh_instance := lake_surface.get_node_or_null("Mesh") as MeshInstance3D
	if mesh_instance == null or mesh_instance.mesh == null:
		_fail("Lake surface is missing its visual mesh")
		return
	var material := mesh_instance.get_active_material(0) as ShaderMaterial
	if material == null or material.shader == null:
		_fail("Lake surface must own a shader material")
		return
	var second_lake_surface := packed_scene.instantiate()
	root.add_child(second_lake_surface)
	var second_material: Material = second_lake_surface.get_node("Mesh").get_active_material(0)
	if material == second_material:
		_fail("Each reusable lake surface must own independent visual state")
		return

	var world_scene := load("res://scenes/world_prototype.tscn") as PackedScene
	var world := world_scene.instantiate()
	root.add_child(world)
	if world.get_node_or_null("LakeSurface") == null:
		_fail("Playable world is missing the reusable LakeSurface")
		return
	if world.get_node_or_null("Water") != null:
		_fail("Playable world still contains the prototype Water mesh")
		return
	if world.get_node_or_null("WaterZone") == null:
		_fail("Playable world lost its fishable-water boundary")
		return
	var spatial_casting := world.get_node("SpatialCasting")
	if spatial_casting.get("lake_surface") != world.get_node("LakeSurface"):
		_fail("Spatial casting must use the lake's public tackle-readability boundary")
		return

	print("Lake surface validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

extends SceneTree

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var preview := load("res://assets/_scratch/issue-67-dock-bluegill-preview/dock_bluegill_review_preview.tscn") as PackedScene
	if preview == null:
		_fail("Dock Bluegill review preview did not load")
		return
	var instance := preview.instantiate()
	root.add_child(instance)
	var player := _find_animation_player(instance)
	if player == null:
		_fail("Dock Bluegill GLB has no AnimationPlayer")
		return
	for clip in [&"calm_swim", &"struggle_surge", &"landed_presentation"]:
		if not player.has_animation(clip):
			_fail("Dock Bluegill is missing animation: %s" % clip)
			return
		var animation := player.get_animation(clip)
		if animation == null or animation.get_track_count() == 0:
			_fail("Dock Bluegill animation has no exported motion tracks: %s" % clip)
			return
		player.play(clip)
	print("Dock Bluegill review preview and all named clips validated")
	quit(0)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

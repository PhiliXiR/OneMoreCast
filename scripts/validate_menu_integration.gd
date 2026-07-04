extends SceneTree

const APP_ROOT_SCENE := "res://scenes/app/AppRoot.tscn"
const MENU_ROOT_SCENE := "res://ui/MenuRoot.tscn"
const DEFAULT_LEVEL_ID := "one_more_cast_dock"
const STATE_MAIN_MENU := 1
const STATE_PLAYING := 4
const STATE_PAUSED := 5


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var failures: Array[String] = []

	if ProjectSettings.get_setting("application/run/main_scene", "") as String != APP_ROOT_SCENE:
		failures.append("AppRoot is not configured as the main scene")

	if ProjectSettings.get_setting("autoload/AppQuitHandler", "") as String != "*res://tools/3DCodexPipeline/game/autoload/app_quit_handler.gd":
		failures.append("AppQuitHandler autoload is not registered from the pipeline")
	if ProjectSettings.get_setting("autoload/LevelRegistry", "") as String != "*res://tools/3DCodexPipeline/game/autoload/level_registry.gd":
		failures.append("LevelRegistry autoload is not registered from the pipeline")
	if ProjectSettings.get_setting("autoload/GameState", "") as String != "*res://tools/3DCodexPipeline/game/autoload/game_state.gd":
		failures.append("GameState autoload is not registered from the pipeline")

	if not ResourceLoader.exists(APP_ROOT_SCENE):
		failures.append("AppRoot scene is missing")
	if not ResourceLoader.exists(MENU_ROOT_SCENE):
		failures.append("MenuRoot scene is missing")

	var game_state := root.get_node_or_null("GameState")
	var level_registry := root.get_node_or_null("LevelRegistry")
	if game_state == null:
		failures.append("GameState autoload node is missing")
	if level_registry == null:
		failures.append("LevelRegistry autoload node is missing")
	if game_state == null or level_registry == null:
		_finish(failures)
		return

	if not (level_registry.call("has_level", DEFAULT_LEVEL_ID) as bool):
		failures.append("OneMoreCast dock level is not registered")
	var level_scene_path := level_registry.call("get_level_scene_path", DEFAULT_LEVEL_ID) as String
	if level_scene_path != "res://scenes/world_prototype.tscn":
		failures.append("Default OneMoreCast level path is incorrect")

	var packed_scene := ResourceLoader.load(APP_ROOT_SCENE)
	if not packed_scene is PackedScene:
		_finish(["Could not load %s" % APP_ROOT_SCENE])
		return

	var app_root: Node = (packed_scene as PackedScene).instantiate()
	root.add_child(app_root)
	await process_frame

	game_state.call("transition_to", STATE_MAIN_MENU)
	if game_state.get("current_state") as int != STATE_MAIN_MENU:
		failures.append("GameState did not enter MAIN_MENU")

	game_state.call("load_level", DEFAULT_LEVEL_ID)
	await process_frame
	if game_state.get("current_state") as int != STATE_PLAYING:
		failures.append("Loading the OneMoreCast level did not enter PLAYING")
	if app_root.get_node("%CurrentLevelRoot").get_child_count() != 1:
		failures.append("AppRoot did not instance the OneMoreCast world level")

	game_state.call("pause_game")
	if game_state.get("current_state") as int != STATE_PAUSED:
		failures.append("pause_game did not enter PAUSED")
	if not paused:
		failures.append("pause_game did not pause the scene tree")

	game_state.call("resume_game")
	if game_state.get("current_state") as int != STATE_PLAYING:
		failures.append("resume_game did not return to PLAYING")
	if paused:
		failures.append("resume_game did not unpause the scene tree")

	app_root.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("OneMoreCast menu integration validation passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)

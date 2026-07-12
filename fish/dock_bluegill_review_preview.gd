extends Node3D
@onready var fish: Node3D = $DockBluegill
@onready var label: Label = $CanvasLayer/Label
var clips := [&"calm_swim", &"struggle_surge", &"landed_presentation"]
var index := 0
var elapsed := 0.0
func _ready() -> void: _play_current()
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > 3.0: index = (index + 1) % clips.size(); elapsed = 0.0; _play_current()
func _play_current() -> void:
	var player := _find_animation_player(fish)
	if player != null: player.play(clips[index])
	label.text = "Dock Bluegill review  •  %s" % clips[index]
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null: return found
	return null

extends Control

signal action_requested(action: String)

const UITheme = preload("res://ui/scripts/one_more_cast_theme.gd")

const LABELS := {
	"start": "Start Fishing",
	"level_select": "Fishing Spots",
	"settings": "Settings",
	"dev_menu": "Dev Tools",
	"quit": "Quit",
	"quit_yes": "Quit",
	"quit_no": "Stay",
	"back": "Back",
	"resume": "Resume Fishing",
	"restart_level": "Restart Spot",
	"reload_current_level": "Reload Spot",
	"retry": "Try Again",
	"replay": "Fish Again",
	"main_menu": "Main Menu",
	"return_to_main_menu": "Main Menu",
	"return_to_game": "Return To Water",
	"complete_level": "Record Catch",
	"next_level": "Next Spot",
	"level:one_more_cast_dock": "Dock Fishing",
}

@export var title: String = "One More Cast"
@export var actions: PackedStringArray = []

var _panel_style := StyleBoxFlat.new()
var _button_style := StyleBoxFlat.new()
var _button_hover_style := StyleBoxFlat.new()
var _button_pressed_style := StyleBoxFlat.new()
var _title_settings := LabelSettings.new()
var _caption_settings := LabelSettings.new()


func _ready() -> void:
	_build_styles()
	_build()


func configure(new_title: String, new_actions: PackedStringArray) -> void:
	title = _format_title(new_title)
	actions = new_actions
	if is_inside_tree():
		_build()


func _build_styles() -> void:
	_panel_style = UITheme.paper_panel()
	_button_style = UITheme.action_button(UITheme.PAPER_SHADOW, Color(UITheme.INK.r, UITheme.INK.g, UITheme.INK.b, 0.32))
	_button_hover_style = UITheme.action_button(UITheme.PAPER_SHADOW.lightened(0.11), UITheme.BRASS)
	_button_pressed_style = UITheme.action_button(UITheme.PAPER_SHADOW.darkened(0.16), UITheme.INK)

	_title_settings.font = UITheme.DISPLAY_FONT
	_title_settings.font_size = 42
	_title_settings.font_color = UITheme.INK

	_caption_settings.font = UITheme.BODY_FONT
	_caption_settings.font_size = 14
	_caption_settings.font_color = UITheme.QUIET_INK


func _build() -> void:
	for child in get_children():
		child.queue_free()

	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.color = Color(UITheme.LAKE_INK_DEEP.r, UITheme.LAKE_INK_DEEP.g, UITheme.LAKE_INK_DEEP.b, 0.66)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _panel_style)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var caption := Label.new()
	caption.text = "quiet water, one clean cast"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.label_settings = _caption_settings
	layout.add_child(caption)

	var title_label := Label.new()
	title_label.text = _format_title(title)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.label_settings = _title_settings
	layout.add_child(title_label)

	var rule := HSeparator.new()
	layout.add_child(rule)

	for action in actions:
		var button := Button.new()
		button.text = _format_action_label(action)
		button.custom_minimum_size = Vector2(380.0, 44.0)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", _button_style)
		button.add_theme_stylebox_override("hover", _button_hover_style)
		button.add_theme_stylebox_override("pressed", _button_pressed_style)
		button.add_theme_font_override("font", UITheme.BODY_FONT)
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", UITheme.INK)
		button.pressed.connect(func() -> void:
			action_requested.emit(action)
		)
		layout.add_child(button)


func _format_title(raw_title: String) -> String:
	match raw_title:
		"Level Select":
			return "Fishing Spots"
		"Level Complete":
			return "Catch Recorded"
		"Level Failed":
			return "Cast Failed"
		"Dev Menu":
			return "Dev Tools"
		_:
			return raw_title


func _format_action_label(action: String) -> String:
	if LABELS.has(action):
		return LABELS[action]
	if action.begins_with("level:"):
		return action.trim_prefix("level:").replace("_", " ").capitalize()
	return action.replace("_", " ").capitalize()

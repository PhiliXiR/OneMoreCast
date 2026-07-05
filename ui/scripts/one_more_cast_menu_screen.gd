extends Control

signal action_requested(action: String)

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
	_panel_style.bg_color = Color(0.055, 0.075, 0.07, 0.92)
	_panel_style.border_color = Color(0.52, 0.74, 0.64, 0.75)
	_panel_style.border_width_left = 2
	_panel_style.border_width_top = 2
	_panel_style.border_width_right = 2
	_panel_style.border_width_bottom = 2
	_panel_style.corner_radius_top_left = 8
	_panel_style.corner_radius_top_right = 8
	_panel_style.corner_radius_bottom_left = 8
	_panel_style.corner_radius_bottom_right = 8
	_panel_style.content_margin_left = 28
	_panel_style.content_margin_top = 24
	_panel_style.content_margin_right = 28
	_panel_style.content_margin_bottom = 28

	_button_style.bg_color = Color(0.14, 0.22, 0.19, 0.96)
	_button_style.border_color = Color(0.38, 0.55, 0.48, 0.72)
	_button_style.border_width_left = 1
	_button_style.border_width_top = 1
	_button_style.border_width_right = 1
	_button_style.border_width_bottom = 1
	_button_style.corner_radius_top_left = 5
	_button_style.corner_radius_top_right = 5
	_button_style.corner_radius_bottom_left = 5
	_button_style.corner_radius_bottom_right = 5

	_button_hover_style = _button_style.duplicate() as StyleBoxFlat
	_button_hover_style.bg_color = Color(0.22, 0.35, 0.29, 0.98)
	_button_hover_style.border_color = Color(0.75, 0.93, 0.78, 0.9)

	_button_pressed_style = _button_style.duplicate() as StyleBoxFlat
	_button_pressed_style.bg_color = Color(0.08, 0.14, 0.13, 1.0)

	_title_settings.font_size = 32
	_title_settings.font_color = Color(0.92, 0.98, 0.9, 1.0)

	_caption_settings.font_size = 14
	_caption_settings.font_color = Color(0.67, 0.82, 0.75, 1.0)


func _build() -> void:
	for child in get_children():
		child.queue_free()

	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.032, 0.035, 0.64)
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style)
	add_child(panel)

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

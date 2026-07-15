class_name OneMoreCastTheme
extends RefCounted

static var BODY_FONT: FontFile = _load_font("res://ui/fonts/AtkinsonHyperlegible-Regular.ttf")
static var DISPLAY_FONT: FontFile = _load_font("res://ui/fonts/CormorantGaramond-Variable.ttf")

const LAKE_INK := Color("102b32")
const LAKE_INK_DEEP := Color("09191e")
const PAPER_WARMTH := Color("f1e7cf")
const PAPER_SHADOW := Color("cbbd9c")
const MOSS := Color("5f8f69")
const BRASS := Color("c99741")
const ROWAN_RED := Color("b84f45")
const INK := Color("1c2928")
const QUIET_INK := Color("50615c")


static func _load_font(path: String) -> FontFile:
	var font := FontFile.new()
	if font.load_dynamic_font(path) != OK:
		push_error("Unable to load UI font: %s" % path)
	return font


static func apply_body_font(root: Node) -> void:
	for node in root.find_children("*", "Control", true, false):
		if node is Label or node is Button or node is ProgressBar:
			(node as Control).add_theme_font_override("font", BODY_FONT)


static func apply_heading(label: Label, font_size: int, color := INK) -> void:
	label.add_theme_font_override("font", DISPLAY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


static func apply_caption(label: Label, color := QUIET_INK) -> void:
	label.add_theme_font_override("font", BODY_FONT)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)


static func paper_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER_WARMTH
	style.border_color = PAPER_SHADOW
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.02, 0.07, 0.08, 0.3)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	return style


static func ink_panel() -> StyleBoxFlat:
	var style := paper_panel()
	style.bg_color = Color(LAKE_INK.r, LAKE_INK.g, LAKE_INK.b, 0.94)
	style.border_color = Color(BRASS.r, BRASS.g, BRASS.b, 0.75)
	return style


static func action_button(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style


static func style_button(button: Button, emphasis := false, destructive := false) -> void:
	var base := PAPER_SHADOW
	var border := Color(INK.r, INK.g, INK.b, 0.32)
	var text := INK
	if emphasis:
		base = BRASS
		border = Color("765223")
		text = Color("fff8e9")
	elif destructive:
		base = ROWAN_RED
		border = Color("6f2928")
		text = Color("fff4e8")
	button.add_theme_stylebox_override("normal", action_button(base, border))
	button.add_theme_stylebox_override("hover", action_button(base.lightened(0.11), border.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", action_button(base.darkened(0.16), border.darkened(0.1)))
	button.add_theme_color_override("font_color", text)
	button.add_theme_color_override("font_hover_color", text)
	button.add_theme_color_override("font_pressed_color", text)
	button.add_theme_font_override("font", BODY_FONT)
	button.add_theme_font_size_override("font_size", 16)


static func style_tension_gauge(gauge: ProgressBar) -> void:
	var background := action_button(Color("d7c9ab"), PAPER_SHADOW)
	var fill := action_button(MOSS, Color("36593f"))
	gauge.add_theme_stylebox_override("background", background)
	gauge.add_theme_stylebox_override("fill", fill)

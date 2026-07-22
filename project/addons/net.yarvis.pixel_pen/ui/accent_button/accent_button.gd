@tool
class_name PixelPenAccentButton
extends Button


const VARIATION : StringName = &"AccentButton"
const FONT_STATES : Array[String] = [
	"font_color", "font_hover_color", "font_pressed_color",
	"font_hover_pressed_color", "font_focus_color", "font_disabled_color"]

var accent : Color:
	set(value):
		accent = value
		_accent_set = true
		if is_node_ready():
			_apply_accent()

var _accent_set : bool = false


func _init(p_text : String = ""):
	if not p_text.is_empty():
		text = p_text
	theme_type_variation = VARIATION
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready():
	var font_color := get_theme_color("font_color", VARIATION)
	for state in FONT_STATES:
		add_theme_color_override(state, font_color)
	_apply_accent()


func _apply_accent():
	if not _accent_set:
		return
	var base := get_theme_stylebox("normal", VARIATION)
	var theme_accent : Color = base.bg_color if base is StyleBoxFlat else accent
	if accent.is_equal_approx(theme_accent):
		for style_name in ["normal", "focus", "hover", "pressed"]:
			remove_theme_stylebox_override(style_name)
		return
	_override("normal", accent)
	_override("focus", accent)
	_override("hover", accent.lightened(0.18))
	_override("pressed", accent.darkened(0.2))


func _override(style_name : String, color : Color):
	var base := get_theme_stylebox(style_name, VARIATION)
	if base is StyleBoxFlat:
		var style : StyleBoxFlat = base.duplicate()
		style.bg_color = color
		add_theme_stylebox_override(style_name, style)

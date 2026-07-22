@tool
class_name PixelPenIconButton
extends TextureButton


const VARIATION : StringName = &"IconButton"

var active : bool = false:
	set(value):
		active = value
		if is_node_ready():
			_refresh_tint()

var _tint_material : ShaderMaterial


func _init(p_icon : Texture2D = null, p_tooltip : String = ""):
	texture_normal = p_icon
	texture_pressed = p_icon
	texture_hover = p_icon
	tooltip_text = p_tooltip
	theme_type_variation = VARIATION
	custom_minimum_size = Vector2(30, 30)
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_tint_material = ShaderMaterial.new()
	_tint_material.shader = load("res://addons/net.yarvis.pixel_pen/resources/tint_color.gdshader")
	material = _tint_material

	mouse_entered.connect(func():
			_tint_material.set_shader_parameter("tint", get_theme_color("hover_tint", VARIATION))
			)
	mouse_exited.connect(_refresh_tint)


func _ready():
	_refresh_tint()


func set_icon(p_icon : Texture2D):
	texture_normal = p_icon
	texture_pressed = p_icon
	texture_hover = p_icon


func _refresh_tint():
	if _tint_material == null:
		return
	var color : Color = PixelPen.state.userconfig.accent_color if active else get_theme_color(&"default_tint", VARIATION)
	_tint_material.set_shader_parameter("tint", color)

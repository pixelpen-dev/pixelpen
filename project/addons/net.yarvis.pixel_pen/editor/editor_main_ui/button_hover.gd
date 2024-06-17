@tool
extends Node


const disable_color : Color = Color.DIM_GRAY
const default_color : Color = Color.GRAY
const hover_color : Color = Color.WHITE

@onready var active_color : Color = PixelPen.state.userconfig.accent_color

var is_hover : bool = false

@export var can_active : bool = true
@onready var is_active : bool = false:
	set(v):
		v = can_active and v
		is_active = v
		var parent : TextureButton = get_parent()
		if v:
			parent.material.set_shader_parameter("tint", active_color if not parent.disabled else disable_color)
		else:
			parent.material.set_shader_parameter("tint", default_color if not parent.disabled else disable_color)

@export var tool_grup : PixelPenEnum.ToolBoxGrup = PixelPenEnum.ToolBoxGrup.TOOL_GRUP_UNKNOWN
@export var tool_type : PixelPenEnum.ToolBox = PixelPenEnum.ToolBox.TOOL_UNKNOWN
@export var visible_callback : Callable
@export var disable_callback : Callable


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	var parent : TextureButton = get_parent()
	parent.focus_mode = Control.FOCUS_NONE
	if parent.tooltip_text == "":
		parent.tooltip_text = create_tooltip(parent.name)
	var mat : ShaderMaterial = parent.material.duplicate(true)
	parent.material = mat
	parent.mouse_entered.connect(func():
			parent.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			if not is_active:
				is_hover = true
				parent.material.set_shader_parameter("tint", hover_color if not parent.disabled else disable_color)
			)
			
	parent.mouse_exited.connect(func():
			if not is_active:
				is_hover = false
				parent.material.set_shader_parameter("tint", default_color if not parent.disabled else disable_color)
			)
	PixelPen.state.tool_changed.connect(func(active_tool_grup, active_tool_type, grab_active):
			if active_tool_grup == tool_grup and grab_active:
				is_active = tool_type == active_tool_type
			)
	is_active = false
	_process(0)


func _process(_delta):
	var btn : TextureButton = get_parent()
	if visible_callback.is_valid():
		btn.visible = visible_callback.call()
	if disable_callback.is_valid():
		if btn.disabled != disable_callback.call():
			btn.disabled = disable_callback.call()
			is_active = is_active # Force update shader
	if btn.toggle_mode and btn.texture_pressed == btn.texture_normal:
		btn.material.set_shader_parameter("tint", active_color if btn.button_pressed else default_color)


func create_tooltip(text : String) -> String:
	var snake = text.to_snake_case()
	var arr = snake.split("_")
	var tooltip = ""
	for word in arr:
		tooltip += word.to_pascal_case() if tooltip == "" else " " + word.to_pascal_case()
	return tooltip

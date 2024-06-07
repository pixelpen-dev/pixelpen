@tool
extends Control


const shorcut : EditorShorcut = preload("../../resources/editor_shorcut.tres")
const shader_tint = preload("../../resources/tint_color.gdshader")

const select := preload("res://addons/net.yarvis.pixel_pen/resources/icon/arrow_selector_24.svg")
const move := preload("res://addons/net.yarvis.pixel_pen/resources/icon/move_24.svg")
const pan := preload("res://addons/net.yarvis.pixel_pen/resources/icon/pan_24.svg")
const selection := preload("res://addons/net.yarvis.pixel_pen/resources/icon/selection_24.svg")
const pen := preload("res://addons/net.yarvis.pixel_pen/resources/icon/pen.svg")
const brush := preload("res://addons/net.yarvis.pixel_pen/resources/icon/brush_24.svg")
const stamp := preload("res://addons/net.yarvis.pixel_pen/resources/icon/stamp.svg")
const eraser := preload("res://addons/net.yarvis.pixel_pen/resources/icon/ink_eraser_24.svg")
const magnet := preload("res://addons/net.yarvis.pixel_pen/resources/icon/magnet.svg")
const line := preload("res://addons/net.yarvis.pixel_pen/resources/icon/line_24.svg")
const oval := preload("res://addons/net.yarvis.pixel_pen/resources/icon/circle-outline.svg")
const rectangle := preload("res://addons/net.yarvis.pixel_pen/resources/icon/rect_24.svg")
const fill := preload("res://addons/net.yarvis.pixel_pen/resources/icon/ink_24.svg")
const color_picker := preload("res://addons/net.yarvis.pixel_pen/resources/icon/color_picker_24.svg")
const zoom := preload("res://addons/net.yarvis.pixel_pen/resources/icon/zoom_in_24.svg")

@export var toolbox_list : Control

var _arr_prev_toolbox : Array[int]
var prev_toolbox : PixelPen.ToolBox:
	get:
		if _arr_prev_toolbox.is_empty():
			return PixelPen.ToolBox.TOOL_UNKNOWN
		return _arr_prev_toolbox[0]
var current_toolbox : PixelPen.ToolBox


func create_toolbox():
	_clean_up()
	_build_button("Select", select, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_SELECT, false, shorcut.tool_select)
	_build_button("Move", move, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_MOVE, false, shorcut.tool_move)
	_build_button("Pan", pan, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_PAN, false, shorcut.tool_pan)
	_build_button("Selection", selection, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_SELECTION, false, shorcut.tool_selection)
	_build_button("Pen", pen, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_PEN, true, shorcut.tool_pen)
	_build_button("Brush", brush, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_BRUSH, false, shorcut.tool_brush)
	_build_button("Stamp", stamp, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_STAMP, false, shorcut.tool_stamp)
	_build_button("Eraser", eraser, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_ERASER, false, shorcut.tool_eraser)
	_build_button("Magnet", magnet, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_MAGNET, false, shorcut.tool_magnet)
	_build_button("Line", line, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_LINE, false, shorcut.tool_line)
	_build_button("Ellipse", oval, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_ELLIPSE, false, shorcut.tool_ellipse)
	_build_button("Rectangle", rectangle, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_RECTANGLE, false, shorcut.tool_rectangle)
	_build_button("Fill", fill, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_FILL, false, shorcut.tool_fill)
	_build_button("Color Picker", color_picker, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_COLOR_PICKER, false, shorcut.tool_color_picker)
	_build_button("Zoom", zoom, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_ZOOM, false, shorcut.tool_zoom)


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	create_toolbox()
	PixelPen.project_file_changed.connect(func ():
			if PixelPen.current_project != null:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_PEN, true)
			)
	PixelPen.toolbox_just_changed.connect(func (type : PixelPen.ToolBox):
			if type != current_toolbox and type != PixelPen.ToolBox.TOOL_UNKNOWN:
				_arr_prev_toolbox.push_back(type)
				_arr_prev_toolbox = _arr_prev_toolbox.slice(-2)
				current_toolbox = type
			)


func _build_button(name : String, texture : Texture2D, grup : int, type: int, default_active : bool, shorcut : Shortcut = null):
	var btn = TextureButton.new()
	btn.name = name
	btn.texture_normal = texture
	btn.custom_minimum_size = Vector2i(40, 40)
	btn.pressed.connect(func ():
			if PixelPen.current_project == null:
				return
			PixelPen.tool_changed.emit(grup, type, true)
			)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	btn.shortcut = shorcut
	
	var mat = ShaderMaterial.new()
	mat.shader = shader_tint
	btn.material = mat
	
	var hover = Node.new()
	hover.set_script(preload("button_hover.gd"))
	hover.tool_grup = grup
	hover.tool_type = type
	hover.can_active = true
	btn.add_child(hover)
	
	toolbox_list.add_child(btn)
	#btn.owner = toolbox_list.owner
	hover.is_active = default_active


func _clean_up():
	for child in toolbox_list.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()

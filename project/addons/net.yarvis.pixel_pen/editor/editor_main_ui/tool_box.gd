@tool
extends Control


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
var prev_toolbox : PixelPenEnum.ToolBox:
	get:
		if _arr_prev_toolbox.is_empty():
			return PixelPenEnum.ToolBox.TOOL_UNKNOWN
		return _arr_prev_toolbox[0]
var current_toolbox : PixelPenEnum.ToolBox


func create_toolbox():
	_clean_up()
	await get_tree().process_frame
	_build_button("Select", select, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_SELECT, false, PixelPen.singleton.userconfig.shorcuts.tool_select)
	_build_button("Move", move, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_MOVE, false, PixelPen.singleton.userconfig.shorcuts.tool_move)
	_build_button("Pan", pan, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_PAN, false, PixelPen.singleton.userconfig.shorcuts.tool_pan)
	_build_button("Selection", selection, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_SELECTION, false, PixelPen.singleton.userconfig.shorcuts.tool_selection)
	_build_button("Pen", pen, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_PEN, true, PixelPen.singleton.userconfig.shorcuts.tool_pen)
	_build_button("Brush", brush, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_BRUSH, false, PixelPen.singleton.userconfig.shorcuts.tool_brush)
	_build_button("Stamp", stamp, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_STAMP, false, PixelPen.singleton.userconfig.shorcuts.tool_stamp)
	_build_button("Eraser", eraser, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_ERASER, false, PixelPen.singleton.userconfig.shorcuts.tool_eraser)
	_build_button("Magnet", magnet, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_MAGNET, false, PixelPen.singleton.userconfig.shorcuts.tool_magnet)
	_build_button("Line", line, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_LINE, false, PixelPen.singleton.userconfig.shorcuts.tool_line)
	_build_button("Ellipse", oval, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_ELLIPSE, false, PixelPen.singleton.userconfig.shorcuts.tool_ellipse)
	_build_button("Rectangle", rectangle, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_RECTANGLE, false, PixelPen.singleton.userconfig.shorcuts.tool_rectangle)
	_build_button("Fill", fill, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_FILL, false, PixelPen.singleton.userconfig.shorcuts.tool_fill)
	_build_button("Color Picker", color_picker, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_COLOR_PICKER, false, PixelPen.singleton.userconfig.shorcuts.tool_color_picker)
	_build_button("Zoom", zoom, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_ZOOM, false, PixelPen.singleton.userconfig.shorcuts.tool_zoom)


func _ready():
	if not PixelPen.singleton.need_connection(get_window()):
		return
	PixelPen.singleton.shorcut_changed.connect(create_toolbox)
	create_toolbox()
	PixelPen.singleton.project_file_changed.connect(func ():
			if PixelPen.singleton.current_project != null:
				PixelPen.singleton.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPenEnum.ToolBox.TOOL_PEN, true)
				PixelPen.singleton.toolbox_just_changed.emit(PixelPenEnum.ToolBox.TOOL_PEN)
			)
	PixelPen.singleton.toolbox_just_changed.connect(func (type : PixelPenEnum.ToolBox):
			if type != current_toolbox and type != PixelPenEnum.ToolBox.TOOL_UNKNOWN:
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
			if PixelPen.singleton.current_project == null:
				return
			PixelPen.singleton.tool_changed.emit(grup, type, true)
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

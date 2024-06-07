@tool
extends RefCounted


const Tool := preload("tool.gd")
const SelectTool := preload("select_tool.gd")
const MoveTool := preload("move_tool.gd")
const PanTool := preload("pan_tool.gd")
const PenTool := preload("pen_tool.gd")
const BrushTool := preload("brush_tool.gd")
const StampTool := preload("stamp_tool.gd")
const SelectionTool := preload("selection_tool.gd")
const EllipseTool := preload("ellipse_tool.gd")
const RectangleTool := preload("rectangle_tool.gd")
const MagnetTool := preload("magnet_tool.gd")
const LineTool := preload("line_tool.gd")
const FillTool := preload("fill_tool.gd")
const ColorPickerTool := preload("color_picker_tool.gd")
const ZoomTool := preload("zoom_tool.gd")

var tool : Tool = Tool.new():
	get:
		match tool.active_tool_type:
			PixelPen.ToolBox.TOOL_SELECT:
				if tool.tool_type != PixelPen.ToolBox.TOOL_SELECT:
					tool = SelectTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_MOVE:
				if tool.tool_type != PixelPen.ToolBox.TOOL_MOVE:
					tool = MoveTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_PAN:
				if tool.tool_type != PixelPen.ToolBox.TOOL_PAN:
					tool = PanTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_PEN:
				if tool.tool_type != PixelPen.ToolBox.TOOL_PEN:
					tool = PenTool.new(PixelPen.ToolBox.TOOL_PEN)
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_BRUSH:
				if tool.tool_type != PixelPen.ToolBox.TOOL_BRUSH:
					tool = BrushTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_STAMP:
				if tool.tool_type != PixelPen.ToolBox.TOOL_STAMP:
					tool = StampTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_ERASER:
				if tool.tool_type != PixelPen.ToolBox.TOOL_ERASER:
					tool = PenTool.new(PixelPen.ToolBox.TOOL_ERASER)
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_MAGNET:
				if tool.tool_type != PixelPen.ToolBox.TOOL_MAGNET:
					tool = MagnetTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_SELECTION:
				if tool.tool_type != PixelPen.ToolBox.TOOL_SELECTION:
					tool = SelectionTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_LINE:
				if tool.tool_type != PixelPen.ToolBox.TOOL_LINE:
					tool = LineTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_ELLIPSE:
				if tool.tool_type != PixelPen.ToolBox.TOOL_ELLIPSE:
					tool = EllipseTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_RECTANGLE:
				if tool.tool_type != PixelPen.ToolBox.TOOL_RECTANGLE:
					tool = RectangleTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_FILL:
				if tool.tool_type != PixelPen.ToolBox.TOOL_FILL:
					tool = FillTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_COLOR_PICKER:
				if tool.tool_type != PixelPen.ToolBox.TOOL_COLOR_PICKER:
					tool = ColorPickerTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			PixelPen.ToolBox.TOOL_ZOOM:
				if tool.tool_type != PixelPen.ToolBox.TOOL_ZOOM:
					tool = ZoomTool.new()
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
			_:
				if tool.active_tool_type != tool.tool_type:
					tool = Tool.new()
					tool.tool_type = tool.active_tool_type
					PixelPen.toolbox_just_changed.emit(tool.active_tool_type)
		return tool


func _init(node : Node2D):
	tool.node = node


func on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if tool._can_draw or _can_draw_exeption():
		if not tool.node.virtual_mouse:
			tool._on_mouse_pressed(mouse_position, callback)
			return
		
		if tool.node.is_hover_virtual_mouse_body(mouse_position, 2):
			if tool.node.is_hover_virtual_mouse_body(mouse_position, -1): # body
				tool.node.start_drag_virtual_mouse_from(mouse_position)

			if tool.node.is_hover_virtual_mouse_body(mouse_position, 0): # LMB
				tool.node.start_drag_virtual_mouse_from(mouse_position)
				tool._on_mouse_pressed(tool.node.virtual_mouse_origin, callback)

			if tool.node.is_hover_virtual_mouse_body(mouse_position, 1): # RMB
				tool.node.start_drag_virtual_mouse_from(mouse_position)
				var rmb = InputEventMouseButton.new()
				rmb.pressed = true
				rmb.button_index = MOUSE_BUTTON_RIGHT
				tool.node.rmb_inject_mode = true
				tool.node._input(rmb)

		else:
			tool.node.reset_virtual_mouse_position(mouse_position)

		tool.node.virtual_pressed = 1


func on_mouse_released(mouse_position : Vector2, callback : Callable):
	if tool._can_draw or _can_draw_exeption():
		if tool.node.virtual_pressed == 1:
			tool.node.virtual_pressed = 0
			if tool.node._on_pan_shorcut_mode:
				var rmb = InputEventMouseButton.new()
				rmb.pressed = false
				rmb.button_index = MOUSE_BUTTON_RIGHT
				tool.node._input(rmb)
				tool.node.rmb_inject_mode = false
			else:
				tool._on_mouse_released(tool.node.virtual_mouse_origin, callback)
			return
		tool._on_mouse_released(mouse_position, callback)


func on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if tool._can_draw or _can_draw_exeption():
		if not tool.node.virtual_mouse:
			tool._on_mouse_motion(mouse_position, event_relative, callback)
			return
		
		if tool.node.virtual_pressed == 1:
			tool.node.drag_virtual_mouse(mouse_position)
			tool._on_mouse_motion(tool.node.virtual_mouse_origin, event_relative, callback)


func on_force_cancel():
	if tool._can_draw or _can_draw_exeption():
		tool._on_force_cancel()


func on_shift_pressed(pressed : bool):
	if tool._can_draw or _can_draw_exeption():
		tool._on_shift_pressed(pressed)


func on_draw_cursor(mouse_position : Vector2):
	if tool._can_draw or _can_draw_exeption():
		if tool.node.virtual_mouse:
			tool._on_draw_cursor(tool.node.virtual_mouse_origin)
		else:
			tool._on_draw_cursor(mouse_position)
	else:
		# Draw cannot draw hint shape
		tool.draw_invalid_cursor(mouse_position)


func on_draw_hint(mouse_position : Vector2):
	if tool.node.virtual_mouse:
		tool._on_draw_hint(tool.node.virtual_mouse_origin)
	else:
		tool._on_draw_hint(mouse_position)


func _can_draw_exeption():
	var exeption : bool = tool.tool_type == PixelPen.ToolBox.TOOL_PAN
	exeption = exeption or tool.tool_type == PixelPen.ToolBox.TOOL_SELECTION
	exeption = exeption or tool.tool_type == PixelPen.ToolBox.TOOL_COLOR_PICKER
	exeption = exeption or tool.tool_type == PixelPen.ToolBox.TOOL_ZOOM
	return exeption

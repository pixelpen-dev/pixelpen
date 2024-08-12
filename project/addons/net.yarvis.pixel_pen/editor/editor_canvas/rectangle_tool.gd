@tool
extends "tool.gd"


var texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/rect_24.svg")

static var filled : bool = false

var start_pressed_position : Vector2
var end_pressed_position : Vector2

var _draw_rect_hint : bool = false
var shift_mode : bool = false


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_RECTANGLE
	has_shift_mode = true
	is_pressed = false


func _on_request_switch_tool(tool_box_type : int) -> bool:
	if is_pressed:
		_on_force_cancel()
	return true


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	if type == PixelPenEnum.ToolBoxRectangle.TOOL_RECTANGLE_FILL_YES:
		filled = true
	elif type == PixelPenEnum.ToolBoxRectangle.TOOL_RECTANGLE_FILL_NO:
		filled = false


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		return
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	is_pressed = true
	_draw_rect_hint = false
	start_pressed_position = mouse_position


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if not is_pressed:
		return
	var start := round(start_pressed_position) as Vector2i 
	var end := round(end_pressed_position) as Vector2i
	var rect = Rect2i(start, end - start).abs()
	if filled:
		rect = rect.intersection(Rect2i(0, 0, node.canvas_size.x, node.canvas_size.y))
	
	if _draw_rect_hint and rect.size != Vector2i.ZERO:
		var index_image : IndexedColorImage = PixelPen.state.current_project.active_layer
		var layer_uid : Vector3i = index_image.layer_uid
		(PixelPen.state.current_project as PixelPenProject).create_undo_layer("Rectangle tool", index_image.layer_uid, func ():
				PixelPen.state.layer_image_changed.emit(layer_uid)
				PixelPen.state.project_saved.emit(false)
				)
		var mask_selection : Image
		if node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		paint_rect(rect, _index_color, mask_selection, filled)
		
		var mirror_line : Vector2i
		if PixelPen.state.current_project.show_symetric_vertical:
			mirror_line.x = PixelPen.state.current_project.symetric_guid.x
		if PixelPen.state.current_project.show_symetric_horizontal:
			mirror_line.y = PixelPen.state.current_project.symetric_guid.y
		
		if mirror_line != Vector2i.ZERO and mask_selection == null:
			if PixelPen.state.current_project.show_symetric_vertical:
				var offset_x = PixelPen.state.current_project.symetric_guid.x + PixelPen.state.current_project.symetric_guid.x - rect.end.x
				var v_rect = Rect2i(Vector2i(offset_x, rect.position.y), rect.size)
				if filled:
					v_rect = v_rect.intersection(Rect2i(0, 0, node.canvas_size.x, node.canvas_size.y))
				paint_rect(v_rect, _index_color, mask_selection, filled)
				if PixelPen.state.current_project.show_symetric_horizontal:
					var offset_y = PixelPen.state.current_project.symetric_guid.y + PixelPen.state.current_project.symetric_guid.y - v_rect.end.y
					var h_rect = Rect2i(Vector2i(v_rect.position.x, offset_y), v_rect.size)
					if filled:
						h_rect = h_rect.intersection(Rect2i(0, 0, node.canvas_size.x, node.canvas_size.y))
					paint_rect(h_rect, _index_color, mask_selection, filled)
			if PixelPen.state.current_project.show_symetric_horizontal:
				var offset_y = PixelPen.state.current_project.symetric_guid.y + PixelPen.state.current_project.symetric_guid.y - rect.end.y
				var h_rect = Rect2i(Vector2i(rect.position.x, offset_y), rect.size)
				if filled:
					h_rect = h_rect.intersection(Rect2i(0, 0, node.canvas_size.x, node.canvas_size.y))
				paint_rect(h_rect, _index_color, mask_selection, filled)
		elif mirror_line != Vector2i.ZERO:
			var canvas_with_rect : Image = Image.create(node.canvas_size.x, node.canvas_size.y, false, Image.FORMAT_R8)
			if filled:
				var rect_image : Image = Image.create(node.canvas_size.x, node.canvas_size.y, false, Image.FORMAT_R8)
				rect_image.fill_rect(rect, Color8(_index_color, 0, 0, 0))
				PixelPenCPP.fill_color(mask_selection, canvas_with_rect, Color8(_index_color, 0, 0, 0), rect_image)
			else:
				PixelPenCPP.fill_rect_outline(rect, Color8(_index_color, 0, 0, 0), canvas_with_rect, mask_selection)
			index_image.blit_color_map(get_mirror_image(mirror_line, canvas_with_rect), null, Vector2i.ZERO)
		
		(PixelPen.state.current_project as PixelPenProject).create_redo_layer(index_image.layer_uid, func ():
				PixelPen.state.layer_image_changed.emit(layer_uid)
				PixelPen.state.project_saved.emit(false)
				)
		is_pressed = false
		_draw_rect_hint = false
		PixelPen.state.layer_image_changed.emit(layer_uid)
		PixelPen.state.project_saved.emit(false)
	
	is_pressed = false
	_draw_rect_hint = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if shift_mode or not is_pressed:
		return
	end_pressed_position = mouse_position
	var start = round(start_pressed_position)
	var end = round(end_pressed_position)
	_draw_rect_hint = is_pressed and start != end


func _on_force_cancel():
	_draw_rect_hint = false
	is_pressed = false


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed and not is_pressed
	PixelPen.state.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	if shift_mode:
		return color_picker_texture
	return texture


func _on_draw_hint(mouse_position : Vector2):
	if _draw_rect_hint:
		var start = round(start_pressed_position)
		var end = round(end_pressed_position)
		var rect = Rect2i(start, end - start)
		node.draw_rect(rect, Color.WHITE, false)
		draw_circle_marker(start)
		draw_circle_marker(end)
		draw_circle_marker(Vector2(end.x, start.y))
		draw_circle_marker(Vector2(start.x, end.y))
	elif is_pressed:
		var start = round(start_pressed_position)
		draw_circle_marker(start)

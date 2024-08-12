@tool
extends "tool.gd"


static var brush_index : int = 0
var is_pressed_outside : bool = false
var shift_mode : bool = false
var brush_mask : ImageTexture

var brush_color_index : int


func _init(mode : int):
	tool_type = mode
	has_shift_mode = tool_type == PixelPenEnum.ToolBox.TOOL_BRUSH
	is_pressed = false
	update_brush()
	if tool_type == PixelPenEnum.ToolBox.TOOL_BRUSH:
		brush_color_index = _index_color
	elif tool_type == PixelPenEnum.ToolBox.TOOL_ERASER:
		brush_color_index = 0


func _on_request_switch_tool(tool_box_type : int) -> bool:
	node.overlay_hint.texture = null
	node.overlay_hint.position = Vector2.ZERO
	node.overlay_hint.material.set_shader_parameter("enable", false)
	return true


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	update_brush()


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		return
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	if tool_type == PixelPenEnum.ToolBox.TOOL_BRUSH:
		brush_color_index = _index_color
	elif tool_type == PixelPenEnum.ToolBox.TOOL_ERASER:
		brush_color_index = 0
	_prev_paint_coord_array.clear()
	var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
	if index_image != null:
		PixelPen.state.current_project.paint.set_image(index_image.colormap)
		PixelPen.state.current_project.brush_index = 0
		var coord = floor(mouse_position)
		var mask_selection : Image
		if node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
			PixelPen.state.current_project.paint.set_mask(mask_selection)
		else:
			PixelPen.state.current_project.paint.set_mask(null)
		if index_image.coor_inside_canvas(coord.x, coord.y, mask_selection):
			is_pressed = true
			is_pressed_outside = false
			var action_name : String = "Pen tool" if tool_type == PixelPenEnum.ToolBox.TOOL_PEN else "Brush tool"
			var layer_uid : Vector3i = index_image.layer_uid
			(PixelPen.state.current_project as PixelPenProject).create_undo_layer(action_name, index_image.layer_uid, func ():
					PixelPen.state.layer_image_changed.emit(layer_uid)
					PixelPen.state.project_saved.emit(false))
			paint_pixel(coord, brush_color_index, false, true)
			
			callback.call()
		else:
			is_pressed_outside = true
			_prev_paint_coord = floor(coord) + Vector2(0.5, 0.5)


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		if not _prev_paint_coord_array.is_empty():
			var is_mirrored : bool = false
			if node.selection_tool_hint.texture != null:
				var mirror_line : Vector2i
				if PixelPen.state.current_project.show_symetric_vertical:
					mirror_line.x = PixelPen.state.current_project.symetric_guid.x
				if PixelPen.state.current_project.show_symetric_horizontal:
					mirror_line.y = PixelPen.state.current_project.symetric_guid.y
				if mirror_line != Vector2i.ZERO:
					var mask_selection : Image = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
					mask_selection = get_mirror_image(mirror_line, mask_selection)
					PixelPen.state.current_project.paint.set_mask(mask_selection)
				else:
					PixelPen.state.current_project.paint.set_mask(null)
			for each in _prev_paint_coord_array:
				if PixelPen.state.current_project.show_symetric_vertical:
					var mirror : Vector2 = each
					mirror.x = PixelPen.state.current_project.symetric_guid.x + PixelPen.state.current_project.symetric_guid.x - mirror.x - 1
					paint_pixel(mirror, brush_color_index, false, true)
					if PixelPen.state.current_project.show_symetric_horizontal:
						mirror.y = PixelPen.state.current_project.symetric_guid.y + PixelPen.state.current_project.symetric_guid.y - mirror.y - 1
						paint_pixel(mirror, brush_color_index, false, true)
					is_mirrored = true
				if PixelPen.state.current_project.show_symetric_horizontal:
					var mirror : Vector2 = each
					mirror.y = PixelPen.state.current_project.symetric_guid.y + PixelPen.state.current_project.symetric_guid.y - mirror.y - 1
					paint_pixel(mirror, brush_color_index, false, true)
					is_mirrored = true
			_prev_paint_coord_array.clear()
			if is_mirrored:
				callback.call()
		
		var index_image : IndexedColorImage = PixelPen.state.current_project.active_layer
		var layer_uid : Vector3i = index_image.layer_uid
		(PixelPen.state.current_project as PixelPenProject).create_redo_layer(index_image.layer_uid, func ():
				PixelPen.state.layer_image_changed.emit(layer_uid)
				PixelPen.state.project_saved.emit(false)
				)
		is_pressed = false
		is_pressed_outside = false
		PixelPen.state.layer_image_changed.emit(layer_uid)
		PixelPen.state.project_saved.emit(false)
	is_pressed = false
	is_pressed_outside = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if shift_mode:
		return
	if is_pressed or is_pressed_outside:
		var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
		if index_image == null:
			return
		var mask_selection : Image
		if node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		var coord = floor(mouse_position)
		var inside = index_image.coor_inside_canvas(coord.x, coord.y, mask_selection)
		var to = mouse_position
		var cheat_inside = false
		if not inside and index_image.coor_inside_canvas(_prev_paint_coord.x, _prev_paint_coord.y, mask_selection):
			for i in range(ceil(_prev_paint_coord.distance_to(mouse_position)) ):
				var direction = _prev_paint_coord.direction_to(mouse_position)
				var vcoord = _prev_paint_coord + direction * i
				if index_image.coor_inside_canvas(floor(vcoord).x, floor(vcoord).y, mask_selection):
					to = vcoord
					inside = true
			if inside:
				cheat_inside = true
		if inside:
			if is_pressed_outside:
				var is_clamped : bool = false
				for i in range(ceil(_prev_paint_coord.distance_to(mouse_position)) ):
					var direction = _prev_paint_coord.direction_to(mouse_position)
					var vcoord = _prev_paint_coord + direction * i
					if index_image.coor_inside_canvas(floor(vcoord).x, floor(vcoord).y, mask_selection):
						_prev_paint_coord = floor(vcoord) + Vector2(0.5, 0.5)
						is_clamped = true
						break
				if not is_clamped:
					_prev_paint_coord = floor(to) + Vector2(0.5, 0.5)
				is_pressed = true
				is_pressed_outside = false
				var layer_uid : Vector3i = index_image.layer_uid
				(PixelPen.state.current_project as PixelPenProject).create_undo_layer("Pen tool", index_image.layer_uid, func ():
						PixelPen.state.layer_image_changed.emit(layer_uid)
						PixelPen.state.project_saved.emit(false)
						)
				paint_pixel(to, brush_color_index, false, true)
			paint_line(_prev_paint_coord, to, brush_color_index, false, true)
			callback.call()
			if cheat_inside:
				_prev_paint_coord = floor(mouse_position) + Vector2(0.5, 0.5)
		elif not is_pressed_outside:
			_on_mouse_released(mouse_position, callback)
			is_pressed_outside = true
			_prev_paint_coord =  floor(mouse_position) + Vector2(0.5, 0.5)
		elif is_pressed_outside:
			_prev_paint_coord =  floor(mouse_position) + Vector2(0.5, 0.5)


func _on_force_cancel():
	is_pressed = false


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed and not is_pressed and tool_type == PixelPenEnum.ToolBox.TOOL_BRUSH
	PixelPen.state.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	if shift_mode:
		draw_plus_cursor(mouse_position)
		node.overlay_hint.visible = false
		return
	node.overlay_hint.visible = true
	if brush_mask == null:
		draw_invalid_cursor(mouse_position)
	else:
		node.overlay_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
		node.overlay_hint.material.set_shader_parameter("outline_color", Color(0, 0, 0, 0))
		node.overlay_hint.material.set_shader_parameter("enable", true)
		node.overlay_hint.material.set_shader_parameter("fill", false)
		node.overlay_hint.material.set_shader_parameter("marching_ant", false)
		node.overlay_hint.texture = brush_mask
		node.overlay_hint.position = floor(mouse_position) - (brush_mask.get_size() - Vector2.ONE) * 0.5


func _on_get_tool_texture() -> Texture2D:
	if shift_mode:
		return color_picker_texture
	return null

func update_brush():
	if PixelPen.state.current_project == null:
		return
	PixelPen.state.current_project.paint.clear_brush()
	if PixelPen.state.userconfig.brush.size() > brush_index and brush_index >= 0:
		var brush = PixelPen.state.userconfig.brush[brush_index]
		PixelPen.state.current_project.paint.add_brush(brush)
		var size = brush.get_size()
		var mask = Image.create(size.x + 2, size.y + 2, false, Image.FORMAT_RGBA8)
		for x in range(size.x):
			for y in range(size.y):
				if brush.get_pixel(x, y).r8 > 0:
					mask.set_pixel(x + 1, y + 1, Color.WHITE)
		brush_mask = ImageTexture.create_from_image(mask)

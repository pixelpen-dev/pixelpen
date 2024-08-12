@tool
extends "tool.gd"


static var pixel_perfect : bool = false

var is_pressed_outside : bool = false

var shift_mode : bool = false


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_PEN
	has_shift_mode = true


func _on_request_switch_tool(tool_box_type : int) -> bool:
	if is_pressed:
		return false
	return true


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	if type == PixelPenEnum.ToolBoxPen.TOOL_PEN_PIXEL_PERFECT_YES:
		pixel_perfect = true
	elif type == PixelPenEnum.ToolBoxPen.TOOL_PEN_PIXEL_PERFECT_NO:
		pixel_perfect = false


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		return
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	_prev_paint_coord_array.clear()
	var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
	if index_image != null:
		var coord = floor(mouse_position)
		var mask_selection : Image
		if node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		if index_image.coor_inside_canvas(coord.x, coord.y, mask_selection):
			is_pressed = true
			is_pressed_outside = false
			var action_name : String = "Pen tool" if tool_type == PixelPenEnum.ToolBox.TOOL_PEN else "Brush tool"
			var layer_uid : Vector3i = index_image.layer_uid
			(PixelPen.state.current_project as PixelPenProject).create_undo_layer(action_name, index_image.layer_uid, func ():
					PixelPen.state.layer_image_changed.emit(layer_uid)
					PixelPen.state.project_saved.emit(false))
			_prev_paint_coord3.clear()
			_prev_replaced_color3.clear()
			paint_pixel(coord, _index_color)
			callback.call()
		else:
			is_pressed_outside = true
			_prev_paint_coord = floor(coord) + Vector2(0.5, 0.5)


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		if not _prev_paint_coord_array.is_empty():
			var is_mirrored : bool = false
			var color : int = _index_color
			for each in _prev_paint_coord_array:
				if PixelPen.state.current_project.show_symetric_vertical:
					var mirror : Vector2 = each
					mirror.x = PixelPen.state.current_project.symetric_guid.x + PixelPen.state.current_project.symetric_guid.x - mirror.x - 1
					paint_pixel(mirror, color)
					if PixelPen.state.current_project.show_symetric_horizontal:
						mirror.y = PixelPen.state.current_project.symetric_guid.y + PixelPen.state.current_project.symetric_guid.y - mirror.y - 1
						paint_pixel(mirror, color)
					is_mirrored = true
				if PixelPen.state.current_project.show_symetric_horizontal:
					var mirror : Vector2 = each
					mirror.y = PixelPen.state.current_project.symetric_guid.y + PixelPen.state.current_project.symetric_guid.y - mirror.y - 1
					paint_pixel(mirror, color)
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

				_prev_paint_coord3.clear()
				_prev_replaced_color3.clear()
				paint_pixel(to, _index_color)
			paint_line(_prev_paint_coord, to, _index_color, pixel_perfect)
			
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
	shift_mode = pressed and tool_type == PixelPenEnum.ToolBox.TOOL_PEN and not is_pressed
	PixelPen.state.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	if shift_mode:
		draw_plus_cursor(mouse_position)
		return
	
	var has_zoom : bool = node.get_viewport().get_camera_2d() != null
	if has_zoom and node.get_viewport().get_camera_2d().zoom.length() < 10:
		# Draw on zoom out cursor pos hint
		draw_cross_cursor(mouse_position)
		
	# Draw center cursor
	draw_circle_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	if shift_mode:
		return color_picker_texture
	return null

@tool
extends "tool.gd"


var texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/line_24.svg")

static var pixel_perfect : bool = false
static  var width : int = 1:
	set(v):
		width = maxi(1, v)
var start_pressed_position : Vector2
var end_pressed_position : Vector2

var _cache_line_mask : Image
var shift_mode : bool = false


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_LINE
	has_shift_mode = true
	is_pressed = false
	if is_instance_valid(node):
		node.overlay_hint.material.set_shader_parameter("enable", false)


func _on_request_switch_tool(tool_box_type : int) -> bool:
	if is_pressed:
		_on_force_cancel()
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
	start_pressed_position = mouse_position
	end_pressed_position = mouse_position
	is_pressed = true


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if _cache_line_mask != null:
		var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
		if index_image != null:
			var layer_uid : Vector3i = index_image.layer_uid
			(PixelPen.state.current_project as PixelPenProject).create_undo_layer("Line tool", index_image.layer_uid, func ():
					PixelPen.state.layer_image_changed.emit(layer_uid)
					PixelPen.state.project_saved.emit(false)
					)
			var mask_selection : Image
			if node.selection_tool_hint.texture != null:
				mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
			index_image.blit_index_on_color_map(_index_color, _cache_line_mask, mask_selection)
			
			var mirror_line : Vector2i
			if PixelPen.state.current_project.show_symetric_vertical:
				mirror_line.x = PixelPen.state.current_project.symetric_guid.x
			if PixelPen.state.current_project.show_symetric_horizontal:
				mirror_line.y = PixelPen.state.current_project.symetric_guid.y
			if mirror_line != Vector2i.ZERO and mask_selection == null:
				index_image.blit_index_on_color_map(
						_index_color, 
						get_mirror_image(mirror_line, _cache_line_mask), 
						null)
			elif mirror_line != Vector2i.ZERO:
				var canvas_with_line : Image = index_image.colormap.duplicate()
				canvas_with_line.fill(Color8(0, 0, 0, 0))
				var rect = mask_selection.get_used_rect()
				for x in range(rect.position.x, rect.end.x):
					for y in range(rect.position.y, rect.end.y):
						if mask_selection.get_pixel(x, y).r8 != 0 and _cache_line_mask.get_pixel(x, y).a != 0:
							canvas_with_line.set_pixel(x, y, Color8(_index_color, 0, 0, 0))
				index_image.blit_color_map(get_mirror_image(mirror_line, canvas_with_line), null, Vector2i.ZERO)
							
			callback.call()
			(PixelPen.state.current_project as PixelPenProject).create_redo_layer(index_image.layer_uid, func ():
					PixelPen.state.layer_image_changed.emit(layer_uid)
					PixelPen.state.project_saved.emit(false))
			is_pressed = false
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false)
	is_pressed = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if shift_mode:
		return
	end_pressed_position = mouse_position


func _on_force_cancel():
	_cache_line_mask = null
	node.overlay_hint.texture = null
	is_pressed = false


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed and not is_pressed
	PixelPen.state.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	if shift_mode:
		draw_plus_cursor(mouse_position)
		return
	if is_pressed:
		var rect : Rect2i = Rect2i(Vector2i.ZERO, node.canvas_size)
		var color = get_ink_color()
		var start : Vector2 = floor(start_pressed_position) + Vector2(0.5, 0.5) 
		var end : Vector2 = floor(end_pressed_position) + Vector2(0.5, 0.5)
		
		node.draw_line(start, end, Color.WHITE)
		if rect.has_point(floor(start_pressed_position)):
			node.draw_rect(Rect2(floor(start_pressed_position), Vector2.ONE), Color.WHITE, false)
		if rect.has_point(floor(end_pressed_position)):
			node.draw_rect(Rect2(floor(end_pressed_position), Vector2.ONE), Color.WHITE, false)
		
		_cache_line_mask = Image.create(node.canvas_size.x, node.canvas_size.y, false, Image.FORMAT_RGBAF)
		var direction : Vector2 = start.direction_to(end)
		var length : int = start.distance_to(end)
		var cache_draw : PackedVector2Array = []
		var draw = func(position):
				_cache_line_mask.set_pixel(position.x, position.y, color)
				cache_draw.push_back(position)
				var size = cache_draw.size()
				if  size >= 3 and pixel_perfect:
					var double = cache_draw[size-1].x != cache_draw[size-3].x and cache_draw[size-1].y != cache_draw[size-3].y
					var double2 = cache_draw[size-1].x == cache_draw[size-2].x and cache_draw[size-3].y == cache_draw[size-2].y
					double2 = double2 or (cache_draw[size-1].y == cache_draw[size-2].y and cache_draw[size-3].x == cache_draw[size-2].x)
					if double and double2:
						_cache_line_mask.set_pixel(cache_draw[size-2].x, cache_draw[size-2].y, Color.TRANSPARENT)
						cache_draw.remove_at(size-2)
		for i in range(length * 2):
			var pos : Vector2i = floor(start + i * direction * 0.5) as Vector2i
			if rect.has_point(pos):
				draw.call(pos)
		if rect.has_point(floor(end)):
			draw.call(floor(end))
		node.overlay_hint.position = Vector2.ZERO
		if node.overlay_hint.texture != null:
			node.overlay_hint.texture.update(_cache_line_mask)
		else:
			node.overlay_hint.texture = ImageTexture.create_from_image(_cache_line_mask)
	else:
		node.overlay_hint.texture = null
		_cache_line_mask = null
			
	draw_plus_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	if shift_mode:
		return color_picker_texture
	return texture

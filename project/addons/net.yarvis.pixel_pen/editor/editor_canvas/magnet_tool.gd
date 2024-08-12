@tool
extends "tool.gd"


var magnet_texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/magnet.svg")
var magnet_on_texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/magnet-on.svg")


enum Mode{
	SELECT_PIXEL = 0,
	MOVE_PIXEL
}

static var mode : Mode = Mode.SELECT_PIXEL
var moved_pixel : Array[Vector2i] = []
var start_offset : Vector2
var last_collected_coord : Vector2
var layer : IndexedColorImage
var default_colormap : Image
var prev_state_colormap : Image
var moved_colormap : Image

var shift_mode : bool = false


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_MAGNET
	has_shift_mode = true
	mode = Mode.SELECT_PIXEL
	moved_pixel.clear()
	layer = null
	is_pressed = false
	if PixelPen.state.current_project == null:
		return


func _on_request_switch_tool(tool_box_type : int) -> bool:
	if is_pressed or mode == Mode.MOVE_PIXEL:
		_on_force_cancel()
	return true


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	if type == PixelPenEnum.ToolBoxMagnet.TOOL_MAGNET_CANCEL:
		_on_force_cancel()


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		return
	if layer == null and PixelPen.state.current_project != null:
		layer = PixelPen.state.current_project.active_layer
		default_colormap = layer.colormap.duplicate()
	if layer == null:
		return
	if mode == Mode.SELECT_PIXEL:
		is_pressed = collecte_pixel(mouse_position, mouse_position)
	elif mode == Mode.MOVE_PIXEL:
		is_pressed = true


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		if mode == Mode.MOVE_PIXEL: # Begin commit transform
			node.overlay_hint.texture = null
			var mask : Image = Image.create(layer.size.x, layer.size.y, false, Image.FORMAT_R8)
			for pixel in moved_pixel:
				mask.set_pixelv(pixel, Color8(255, 0, 0, 0))
				
			var offset = node.overlay_hint.position
			layer.blit_color_map(moved_colormap, mask, Vector2i(floor(offset.x), floor(offset.y)))
			
			mode = Mode.SELECT_PIXEL
			var layer_uid : Vector3i = layer.layer_uid
			(PixelPen.state.current_project as PixelPenProject).create_undo_property(
				"Magnet",
				layer,
				"colormap",
				prev_state_colormap,
				func ():
					PixelPen.state.layer_image_changed.emit(layer_uid)
					PixelPen.state.project_saved.emit(false),
				true)
			
			(PixelPen.state.current_project as PixelPenProject).create_redo_layer(layer.layer_uid, func ():
					PixelPen.state.layer_image_changed.emit(layer_uid)
					PixelPen.state.project_saved.emit(false)
					)
			
			is_pressed = false
			layer = null
			moved_pixel.clear()
			node.overlay_hint.position = Vector2.ZERO
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false)
		
		elif shift_mode: # Force to collect pixel
			mode = Mode.SELECT_PIXEL
		
		elif mode == Mode.SELECT_PIXEL:
			start_cut_transform(mouse_position)
		
		elif mode == Mode.MOVE_PIXEL:
			mode = Mode.SELECT_PIXEL
	
	is_pressed = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if is_pressed:
		if mode == Mode.SELECT_PIXEL:
			var to : Vector2 = floor(mouse_position) + Vector2(0.5, 0.5)
			if mouse_position.distance_to(to) < 0.45:
				collecte_pixel(last_collected_coord, mouse_position)
	if mode == Mode.MOVE_PIXEL:
		node.overlay_hint.position = floor(mouse_position) - floor(start_offset)


func _on_shift_pressed(pressed : bool):
	if PixelPen.state.current_project == null:
		return
	var request_release : bool = shift_mode and not (pressed and mode == Mode.SELECT_PIXEL)
	shift_mode = pressed and mode == Mode.SELECT_PIXEL
	if request_release and not shift_mode and not is_pressed:
		start_cut_transform(node.get_local_mouse_position())
		
	PixelPen.state.toolbox_shift_mode.emit(shift_mode)


func _on_force_cancel():
	mode = Mode.SELECT_PIXEL
	is_pressed = false
	node.overlay_hint.texture = null
	node.overlay_hint.position = Vector2.ZERO
	if layer != null:
		layer.colormap = default_colormap
		moved_pixel.clear()
		node._update_layer_image(layer.layer_uid)


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position, 15.0 if is_pressed and mode == Mode.SELECT_PIXEL else 10.0)
	node.overlay_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)


func _on_get_tool_texture() -> Texture2D:
	if mode == Mode.SELECT_PIXEL:
		return magnet_texture
	else:
		return magnet_on_texture
	return null


func collecte_pixel(from : Vector2, to : Vector2) -> bool:
	var rect : Rect2 = Rect2(Vector2.ZERO, node.canvas_size)
	if not rect.has_point(from) or not rect.has_point(to):
		return false
	
	var just_collected : bool = false
	var coord_from = floor(from) + Vector2(0.5, 0.5)
	var coord_to = floor(to) + Vector2(0.5, 0.5)
	
	var coord : Vector2i = floor(to) as Vector2i
	if not moved_pixel.has(coord) and rect.has_point(coord) and layer.get_index_on_color_map(coord.x, coord.y) > 0:
		moved_pixel.push_back(coord)
		last_collected_coord = coord
		just_collected = true
	elif moved_pixel.has(coord):
		last_collected_coord = coord
		just_collected = true
	if from != to:
		var pixel_visited : Vector2 = coord_from
		while pixel_visited != coord_to:
			coord = floor(pixel_visited) as Vector2i
			var distance_v := distance_to_line_segment(coord_from, coord_to, (coord as Vector2) + Vector2(0.5, 0.5))
			if not moved_pixel.has(coord) and distance_v < 0.45 and rect.has_point(coord) and layer.get_index_on_color_map(coord.x, coord.y) > 0:
				moved_pixel.push_back(coord)
				last_collected_coord = coord
				just_collected = true
			pixel_visited = floor(pixel_visited + pixel_visited.direction_to(coord_to)) + Vector2(0.5, 0.5)
	
	if just_collected:
		var mask : Image = Image.create(layer.size.x + 2, layer.size.y + 2, false, Image.FORMAT_RGBA8)
		for pixel in moved_pixel:
			mask.set_pixelv(pixel + Vector2i.ONE, Color8(0, 0, 0, 255))
		node.overlay_hint.position = -Vector2.ONE
		node.overlay_hint.texture = ImageTexture.create_from_image(mask)
		node.overlay_hint.material.set_shader_parameter("outline_color", Color(1, 0, 1, 1))
		node.overlay_hint.material.set_shader_parameter("marching_ant", true)
		node.overlay_hint.material.set_shader_parameter("fill", false)
		node.overlay_hint.material.set_shader_parameter("enable", true)
	return just_collected


func start_cut_transform(mouse_position : Vector2):
	if layer == null or moved_pixel.is_empty():
		return
	var mask : Image = Image.create(layer.size.x, layer.size.y, false, Image.FORMAT_R8)
	for pixel in moved_pixel:
		mask.set_pixelv(pixel, Color8(255, 0, 0, 0))
	node.overlay_hint.position = Vector2.ZERO
	node.overlay_hint.texture = layer.get_mipmap_texture(
		(PixelPen.state.current_project as PixelPenProject).palette,
		mask
	)
	
	node.overlay_hint.material.set_shader_parameter("fill", true)
	
	prev_state_colormap = layer.colormap.duplicate()
	
	moved_colormap = layer.get_color_map_with_mask(mask)
	layer.empty_index_on_color_map(mask)
	node._update_layer_image(layer.layer_uid)
	
	start_offset = floor(mouse_position) 
	mode = Mode.MOVE_PIXEL


func distance_to_line_segment(A: Vector2, B: Vector2, C: Vector2) -> float:
	var AB = B - A
	var AC = C - A

	var ab_dot_ab = AB.dot(AB)
	var ab_dot_ac = AB.dot(AC)

	var t = clamp(ab_dot_ac / ab_dot_ab, 0.0, 1.0)

	var closest_point = A + t * AB
	var distance = (C - closest_point).length()

	return distance

@tool
extends "tool.gd"


var texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/circle-outline.svg")

static var filled : bool = false

var shift_mode : bool = false
var start_press : Vector2
var end_press : Vector2


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_ELLIPSE
	has_shift_mode = true
	is_pressed = false
	if is_instance_valid(node):
		node.overlay_hint.material.set_shader_parameter("enable", true)
		node.overlay_hint.material.set_shader_parameter("outline_color", Color(1, 0, 1, 1))
		node.overlay_hint.material.set_shader_parameter("marching_ant", true)
		node.overlay_hint.material.set_shader_parameter("fill", true)
		node.overlay_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
		node.overlay_hint.position = Vector2.ZERO
		node.overlay_hint.texture = null


func _on_request_switch_tool(tool_box_type : int) -> bool:
	if is_pressed:
		_on_force_cancel()
	return true


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	if type == PixelPenEnum.ToolBoxEllipse.TOOL_ELLIPSE_FILL_YES:
		filled = true
	elif type == PixelPenEnum.ToolBoxEllipse.TOOL_ELLIPSE_FILL_NO:
		filled = false


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		return
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	is_pressed = true
	start_press = floor(mouse_position) + Vector2(0.5, 0.5)
	end_press = start_press
	show_hint(6, true)


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if shift_mode:
		return
	if is_pressed:
		if end_press == floor(mouse_position) + Vector2(0.5, 0.5):
			return
		end_press = floor(mouse_position) + Vector2(0.5, 0.5)
		show_hint(6, true)


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if is_pressed and node.overlay_hint.texture != null:
		end_press = floor(mouse_position) + Vector2(0.5, 0.5)
		show_hint(6)
		var overlay_image : Image = node.overlay_hint.texture.get_image()
		var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
		if index_image != null:
			var layer_uid : Vector3i = index_image.layer_uid
			(PixelPen.state.current_project as PixelPenProject).create_undo_layer("Ellipse tool", index_image.layer_uid, func ():
					PixelPen.state.layer_image_changed.emit(layer_uid)
					PixelPen.state.project_saved.emit(false)
					)
			var mask_selection : Image
			if node.selection_tool_hint.texture != null:
				mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
			index_image.blit_index_on_color_map(_index_color, overlay_image, mask_selection)
			var mirror_line : Vector2i
			if PixelPen.state.current_project.show_symetric_vertical:
				mirror_line.x = PixelPen.state.current_project.symetric_guid.x
			if PixelPen.state.current_project.show_symetric_horizontal:
				mirror_line.y = PixelPen.state.current_project.symetric_guid.y
			if mirror_line != Vector2i.ZERO and mask_selection == null:
				index_image.blit_index_on_color_map(
						_index_color, 
						get_mirror_image(mirror_line, overlay_image), 
						null)
			elif mirror_line != Vector2i.ZERO:
				var canvas_with_line : Image = index_image.colormap.duplicate()
				canvas_with_line.fill(Color8(0, 0, 0, 0))
				var rect = mask_selection.get_used_rect()
				for x in range(rect.position.x, rect.end.x):
					for y in range(rect.position.y, rect.end.y):
						if mask_selection.get_pixel(x, y).r8 != 0 and overlay_image.get_pixel(x, y).a != 0:
							canvas_with_line.set_pixel(x, y, Color8(_index_color, 0, 0, 0))
				index_image.blit_color_map(get_mirror_image(mirror_line, canvas_with_line), null, Vector2i.ZERO)
			(PixelPen.state.current_project as PixelPenProject).create_redo_layer(index_image.layer_uid, func ():
					PixelPen.state.layer_image_changed.emit(layer_uid)
					PixelPen.state.project_saved.emit(false))
			is_pressed = false
			node.overlay_hint.texture = null
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false)
	is_pressed = false
	node.overlay_hint.texture = null


func _on_force_cancel():
	node.overlay_hint.texture = null
	is_pressed = false


func _on_shift_pressed(shift_pressed : bool):
	shift_mode = shift_pressed and not is_pressed
	PixelPen.state.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	if shift_mode:
		return color_picker_texture
	return texture


func show_hint(scale : float, force_outline : bool = false):
	var rect_abs : Rect2 = Rect2(start_press, end_press - start_press).abs()
	var valid_fill = not force_outline and filled and rect_abs.size.x > 1 and rect_abs.size.y > 1
	var image : Image = Image.create(node.canvas_size.x, node.canvas_size.y, false, Image.FORMAT_R8 if valid_fill else Image.FORMAT_RGBAF)
	var color : Color = Color8(_index_color, 0, 0) if valid_fill else get_ink_color()
	var center_mass : Vector2 = get_midpoint_ellipse(rect_abs.position, rect_abs.end, color, image)
	
	if valid_fill:
		var mask : Image = PixelPenCPP.get_image_flood(
					center_mass as Vector2i,
					image,
					Vector2i.ZERO,
					true
				)
		
		var texture_image : Image = Image.create(node.canvas_size.x, node.canvas_size.y, false, Image.FORMAT_RGBAF)
		
		if mask != null and not mask.is_empty():
			PixelPenCPP.fill_color(mask, texture_image, get_ink_color(), null)
		
		get_midpoint_ellipse(rect_abs.position, rect_abs.end, color, texture_image)
		if node.overlay_hint.texture != null and (node.overlay_hint.texture.get_size() as Vector2i) == texture_image.get_size():
			node.overlay_hint.texture.update(texture_image)
		else:
			node.overlay_hint.texture = ImageTexture.create_from_image(texture_image)
	
	else:
		if node.overlay_hint.texture != null and (node.overlay_hint.texture.get_size() as Vector2i) == image.get_size():
			node.overlay_hint.texture.update(image)
		else:
			node.overlay_hint.texture = ImageTexture.create_from_image(image)
	node.overlay_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)

@tool
extends "tool.gd"


var stamp = load("res://addons/net.yarvis.pixel_pen/resources/icon/stamp.svg")

static var stamp_index : int = 0

var stamp_texture : ImageTexture


func _init():
	tool_type =  PixelPenEnum.ToolBox.TOOL_STAMP
	update_stamp()


func _on_request_switch_tool(tool_box_type : int) -> bool:
	node.overlay_hint.texture = null
	node.overlay_hint.position = Vector2.ZERO
	node.overlay_hint.material.set_shader_parameter("enable", false)
	return true


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	update_stamp()


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		return
	is_pressed = true
	
	var index_image : IndexedColorImage = PixelPen.state.current_project.active_layer
	if index_image == null:
		return
	
	if PixelPen.state.userconfig.stamp.size() <= stamp_index or stamp_index < 0:
		return
	var old_palette = PixelPen.state.current_project.palette.color_index.duplicate()
	var stamp : Image = PixelPen.state.userconfig.stamp[stamp_index]
	
	var mask_selection : Image
	var mask_rect : Rect2i
	if node.selection_tool_hint.texture != null:
		mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		mask_rect = mask_selection.get_used_rect()

	var offset : Vector2i = (floor(node.overlay_hint.position) as Vector2i) + Vector2i.ONE
	var stamp_colormap : Image = Image.create(stamp.get_width(), stamp.get_height(), false, Image.FORMAT_R8)
	var new_palette : bool = false
	for y in stamp.get_height():
		for x in stamp.get_width():
			var placement : Vector2i = Vector2i(x, y) + offset
			if mask_selection != null and mask_rect.has_point(placement) and mask_selection.get_pixelv(placement).r8 == 0:
				continue
			var color : Color = stamp.get_pixel(x, y)
			var palette_index : int = PixelPen.state.current_project.palette.color_index.find(color)
			if color.a == 0:
				palette_index = 0
			if palette_index == -1:
				palette_index = PixelPen.state.current_project.palette.find_slot()
				if palette_index == -1:
					return
				PixelPen.state.current_project.palette.color_index[palette_index] = color
				new_palette = true
			stamp_colormap.set_pixel(x, y, Color8(palette_index, 0, 0))
	
	var layer_uid : Vector3i = index_image.layer_uid
	(PixelPen.state.current_project as PixelPenProject).create_undo_layer("Stamp", index_image.layer_uid, func ():
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false))
	if new_palette:
		(PixelPen.state.current_project as PixelPenProject).create_undo_property(
				"palette", PixelPen.state.current_project.palette,
				"color_index",
				old_palette,
				func():
					PixelPen.state.palette_changed.emit(),
				false)

	PixelPenCPP.blit_color_map(stamp_colormap, null, offset, index_image.colormap)

	var mirror_line : Vector2i
	if PixelPen.state.current_project.show_symetric_vertical:
		mirror_line.x = PixelPen.state.current_project.symetric_guid.x
	if PixelPen.state.current_project.show_symetric_horizontal:
		mirror_line.y = PixelPen.state.current_project.symetric_guid.y
	if mirror_line != Vector2i.ZERO and mask_selection == null:
		var canvas_stamp : Image = Image.create(index_image.size.x, index_image.size.y, false, Image.FORMAT_R8)
		PixelPenCPP.blit_color_map(stamp_colormap, null, offset, canvas_stamp)
		PixelPenCPP.blit_color_map(get_mirror_image(mirror_line, canvas_stamp), null, Vector2i.ZERO, index_image.colormap)
	elif mirror_line != Vector2i.ZERO:
		var canvas_stamp : Image = Image.create(index_image.size.x, index_image.size.y, false, Image.FORMAT_R8)
		PixelPenCPP.blit_color_map(stamp_colormap, null, offset, canvas_stamp)
		var masked_stamp = PixelPenCPP.get_color_map_with_mask(mask_selection, canvas_stamp)
		index_image.blit_color_map(get_mirror_image(mirror_line, masked_stamp), null, Vector2i.ZERO)

	if new_palette:
		(PixelPen.state.current_project as PixelPenProject).create_redo_property(
				PixelPen.state.current_project.palette,
				"color_index",
				PixelPen.state.current_project.palette.color_index.duplicate(),
				func():
					PixelPen.state.palette_changed.emit(),
				false)
	
	(PixelPen.state.current_project as PixelPenProject).create_redo_layer(index_image.layer_uid, func ():
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false)
			)
	if new_palette:
		PixelPen.state.palette_changed.emit()
	PixelPen.state.layer_image_changed.emit(index_image.layer_uid)
	PixelPen.state.project_saved.emit(false)


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	is_pressed = false


func _on_draw_cursor(mouse_position : Vector2):
	if stamp_texture == null:
		draw_invalid_cursor(mouse_position)
		node.overlay_hint.visible = false
	else:
		node.overlay_hint.visible = true
		node.overlay_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
		node.overlay_hint.material.set_shader_parameter("outline_color", Color(1, 0, 1, 1))
		node.overlay_hint.material.set_shader_parameter("enable", true)
		node.overlay_hint.material.set_shader_parameter("fill", true)
		node.overlay_hint.material.set_shader_parameter("marching_ant", true)
		node.overlay_hint.texture = stamp_texture
		node.overlay_hint.position = floor(mouse_position - (stamp_texture.get_size() - Vector2.ONE) * 0.5)


func update_stamp():
	if PixelPen.state.current_project == null:
		stamp_texture = null
		return
	if PixelPen.state.userconfig.stamp.size() > stamp_index and stamp_index >= 0:
		var stamp = PixelPen.state.userconfig.stamp[stamp_index]
		var size = stamp.get_size()
		var mask = Image.create(size.x + 2, size.y + 2, false, Image.FORMAT_RGBAF)
		var rect : Rect2i = stamp.get_used_rect()
		mask.blend_rect(stamp, rect, rect.position + Vector2i.ONE)
		stamp_texture = ImageTexture.create_from_image(mask)
	else:
		stamp_texture = null

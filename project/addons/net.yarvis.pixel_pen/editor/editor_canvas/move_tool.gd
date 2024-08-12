@tool
extends "tool.gd"


signal confirm_dialog_closed

var texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/move_24.svg")

enum Mode{
	UNKNOWN = -1,
	CUT,
	COPY
}

static var transformed : bool = false
static var mode : int = Mode.UNKNOWN

var index_image : IndexedColorImage
var default_selection_texture : Image
var default_cache_map : Image
var cut_cache_image_map : Image
var move_cache_image_map : Image
var mask_selection : Image

var _pressed_offset : Vector2
var _prev_offset : Vector2i
var _show_guid : bool = false
var _canvas_anchor_position : Vector2
var _rotate_anchor_offset : Vector2
var _is_rotate_anchor_hovered : bool = false
var _is_move_anchor : bool = false
var _mask_used_rect : Rect2i
var _cache_move_transform_start : Vector2i

var _cache_undo_redo : UndoRedoManager


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_MOVE
	if is_instance_valid(node):
		if node.selection_tool_hint.texture == null:
			default_selection_texture = null
		else:
			default_selection_texture = node.selection_tool_hint.texture.get_image().duplicate()
		node.selection_tool_hint.position = Vector2.ZERO
		node.selection_tool_hint.offset = -Vector2.ONE
		node.overlay_hint.position = Vector2.ZERO
		node.overlay_hint.material.set_shader_parameter("enable", false)

	has_shift_mode = false
	transformed  = false
	is_pressed = false
	mode = Mode.UNKNOWN


func _on_request_switch_tool(tool_box_type : int) -> bool:
	if move_cache_image_map != null:
		var confirm_dialog : Window = ConfirmationDialog.new()
		confirm_dialog.title = PixelPen.state.EDITOR_TITTLE
		confirm_dialog.canceled.connect(func():
				_on_move_cancel()
				confirm_dialog_closed.emit()
				)
		confirm_dialog.confirmed.connect(func():
				_on_move_commit()
				confirm_dialog_closed.emit()
				)
		
		var description := Label.new()
		description.set_anchors_preset(Control.PRESET_FULL_RECT)
		description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.text = "Confirm transformation"
		confirm_dialog.add_child(description)
		
		node.owner.add_child(confirm_dialog)

		confirm_dialog.popup_centered(Vector2i(320, 128))
		await confirm_dialog_closed
		confirm_dialog.queue_free()
	if move_cache_image_map == null:
		node.overlay_hint.texture = null
		mode = Mode.UNKNOWN
	return move_cache_image_map == null


func _on_sub_tool_changed(type : int):
	super._on_sub_tool_changed(type)
	if type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_CUT:
		mode = Mode.CUT
		_show_guid = true
		_init_transform()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_COPY:
		mode = Mode.COPY
		_show_guid = true
		_init_transform()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_ROTATE_LEFT:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.state.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_ROTATE_RIGHT:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.state.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_FLIP_HORIZONTAL:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.state.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_FLIP_VERTICAL:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.state.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_LEFT:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.state.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_UP:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.state.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_RIGHT:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.state.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_DOWN:
		_transform(type)
		## TODO: implement undo redo
		(PixelPen.state.current_project as PixelPenProject).undo_redo.clear_history()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_CANCEL:
		_on_move_cancel()
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_COMMIT:
		_on_move_commit()


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		return
	if index_image == null or mode == Mode.UNKNOWN:
		if mode == Mode.UNKNOWN and node.selection_tool_hint.texture != null:
			_pressed_offset = mouse_position
			is_pressed = true
		return
	
	is_pressed = true
	_cache_move_transform_start = floor(mouse_position) as Vector2i
	_show_guid = true
	_pressed_offset = mouse_position
	if _is_rotate_anchor_hovered:
		_pressed_offset -= _rotate_anchor_offset
		_is_move_anchor = true
		return
	
	if move_cache_image_map == null:
		on_about_to_start_transform()
	
	is_pressed = true
	_prev_offset = Vector2i( floor(node.overlay_hint.position.x), floor( node.overlay_hint.position.y))
	
	var layer_uid : Vector3i = index_image.layer_uid
	(PixelPen.state.current_project as PixelPenProject).create_undo_layer("Move", index_image.layer_uid, func ():
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false)
			)
	create_undo_overlay_position(node)
	
	if move_cache_image_map != null:
		index_image.colormap = cut_cache_image_map.duplicate()
		callback.call()


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	if not is_pressed or index_image == null or mode == Mode.UNKNOWN:
		if mode == Mode.UNKNOWN and node.selection_tool_hint.texture != null:
			var offset : Vector2i = node.selection_tool_hint.offset + Vector2.ONE
			node.selection_tool_hint.texture = ImageTexture.create_from_image(
					MaskSelection.offset_image(node.selection_tool_hint.texture.get_image(), offset, node.canvas_size))
			node.selection_tool_hint.offset = -Vector2.ONE
		is_pressed = false
		return

	if _is_move_anchor:
		_is_move_anchor = false
		is_pressed = false
		return
		
	if move_cache_image_map == null:
		is_pressed = false
		return
	
	index_image.colormap = cut_cache_image_map.duplicate()
	var offset = node.overlay_hint.position
	index_image.blit_color_map(move_cache_image_map, mask_selection, Vector2i(floor(offset.x), floor(offset.y)))
	if mask_selection != null:
		node.selection_tool_hint.offset = -Vector2.ONE
		create_undo_selection_position(node)
		node.selection_tool_hint.position = offset as Vector2
		create_redo_selection_position(node)
	create_redo_overlay_position(node)
	
	var layer_uid : Vector3i = index_image.layer_uid
	(PixelPen.state.current_project as PixelPenProject).create_redo_layer(index_image.layer_uid, func ():
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false)
			)
	is_pressed = false
	transformed = true
	PixelPen.state.layer_image_changed.emit(layer_uid)
	PixelPen.state.project_saved.emit(false)
	callback.call()


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if not is_pressed or index_image == null or mode == Mode.UNKNOWN:
		if is_pressed and mode == Mode.UNKNOWN:
			node.selection_tool_hint.offset = -Vector2.ONE + floor(mouse_position) - floor(_pressed_offset)
		return

	if _is_move_anchor:
		_rotate_anchor_offset = mouse_position - _pressed_offset
		_rotate_anchor_offset.x = snappedf(_rotate_anchor_offset.x, 0.5)
		_rotate_anchor_offset.y = snappedf(_rotate_anchor_offset.y, 0.5)
		return

	if  move_cache_image_map == null:
		return

	node.overlay_hint.position = (_prev_offset as Vector2) + floor(mouse_position) - floor(_pressed_offset)
	node.selection_tool_hint.offset = -Vector2.ONE + floor(mouse_position) - floor(_pressed_offset)


func _on_force_cancel():
	is_pressed = false
	_on_move_cancel()


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	if _is_rotate_anchor_hovered:
		return null
	return texture


func _on_draw_hint(mouse_position : Vector2):
	_draw_hint(mouse_position, true)


func on_about_to_start_transform():
	_cache_undo_redo = PixelPen.state.current_project.undo_redo
	PixelPen.state.current_project.undo_redo = UndoRedoManager.new()


func on_end_transform():
	PixelPen.state.current_project.undo_redo = _cache_undo_redo


func _draw_hint(mouse_position : Vector2, draw_on_canvas : bool = false):
	if _show_guid:
		var offset = node.overlay_hint.position
		if mask_selection == null and node.selection_tool_hint.texture != null:
			mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		var guid_rect := Rect2()
		if mask_selection == null:
			if move_cache_image_map == null:
				guid_rect.size = (node.canvas_size as Vector2) + Vector2.ONE
				guid_rect.position = Vector2(-0.5, -0.5) + (offset as Vector2)
			else:
				guid_rect.size = (move_cache_image_map.get_size() as Vector2) + Vector2.ONE
				guid_rect.position = Vector2(-0.5, -0.5) + (offset as Vector2)
		else:
			if _mask_used_rect == Rect2i():
				_mask_used_rect = MaskSelection.get_mask_used_rect(mask_selection)
			guid_rect.size = (_mask_used_rect.size as Vector2) + Vector2.ONE
			guid_rect.position = (_mask_used_rect.position as Vector2) - Vector2(0.5, 0.5) + (offset as Vector2)
		
		if draw_on_canvas:
			node.draw_rect(guid_rect, Color.WHITE, false)
			draw_circle_marker(guid_rect.position)
			draw_circle_marker(guid_rect.end)
			draw_circle_marker(Vector2(guid_rect.end.x, guid_rect.position.y))
			draw_circle_marker(Vector2(guid_rect.position.x, guid_rect.end.y))
		
		# rotate anchor
		var cal = func():
			_canvas_anchor_position = _rotate_anchor_offset + guid_rect.position + guid_rect.size * 0.5
			_canvas_anchor_position.x = snappedf(_canvas_anchor_position.x, 0.5)
			_canvas_anchor_position.y = snappedf(_canvas_anchor_position.y, 0.5)
		
		cal.call()
		var xx = abs(fmod( snappedf(_canvas_anchor_position.x, 0.5) , 1 )) == 0.5
		var yy = abs(fmod( snappedf(_canvas_anchor_position.y, 0.5) , 1 )) == 0.5
		if xx and not yy:
			_rotate_anchor_offset.x -= 0.5
			cal.call()
		elif yy and not xx:
			_rotate_anchor_offset.y -= 0.5
			cal.call()
		
		_is_rotate_anchor_hovered = _canvas_anchor_position.distance_to(mouse_position) < get_viewport_scale(10)
		if _is_move_anchor:
			var distance = _canvas_anchor_position.distance_to(mouse_position)
			var direction = _canvas_anchor_position.direction_to(mouse_position)
			if draw_on_canvas:
				draw_plus_cursor(_canvas_anchor_position + direction * distance * 0.5, 20)
		elif draw_on_canvas:
			if _is_rotate_anchor_hovered:
				draw_plus_cursor(_canvas_anchor_position, 15)
			else:
				draw_plus_cursor(_canvas_anchor_position, 9)


func _init_transform():
	if move_cache_image_map == null:
		if PixelPen.state.current_project != null and PixelPen.state.current_project.active_layer_is_valid():
			index_image = PixelPen.state.current_project.active_layer
			_transform(PixelPenEnum.ToolBoxMove.TOOL_MOVE_UNKNOWN)
		else:
			index_image = null


func _transform(type : int):
	if mode == Mode.UNKNOWN:
		return
	
	_show_guid = true
	_draw_hint(node.get_local_mouse_position())
		
	if index_image == null:
		return
	
	if node.selection_tool_hint.texture == null:
		mask_selection = null
	elif mask_selection == null:
		mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
	
	if node.overlay_hint.texture == null:
		node.overlay_hint.texture = index_image.get_mipmap_texture(
			(PixelPen.state.current_project as PixelPenProject).palette,
			mask_selection
		)
	
	if move_cache_image_map == null:
		on_about_to_start_transform()
		default_cache_map = index_image.colormap.duplicate()
		move_cache_image_map = index_image.get_color_map_with_mask(mask_selection)
		if mode == Mode.CUT:
			index_image.empty_index_on_color_map(mask_selection)
		cut_cache_image_map = index_image.get_color_map_with_mask().duplicate()
	
	var angle
	var cw : int = - 1
	var origin_offset : Vector2
	var move_image : Image = node.overlay_hint.texture.get_image()
	var move_image_center_pos : Vector2 = _canvas_anchor_position - (move_image.get_size() as Vector2) * 0.5 - node.overlay_hint.position.round()

	move_image_center_pos -= _rotate_anchor_offset
	move_image_center_pos.x = snappedf(move_image_center_pos.x, 0.5)
	move_image_center_pos.y = snappedf(move_image_center_pos.y, 0.5)
	if type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_ROTATE_LEFT:
		angle = PI * -0.5
		cw = COUNTERCLOCKWISE
		var vector_tl_pos = Vector2(move_image.get_width() * -0.5, move_image.get_height() * -0.5)
		var vector_tr_pos = Vector2(move_image.get_width() * 0.5, move_image.get_height() * -0.5)
		var vector_rotated_tl_pos = vector_tr_pos.rotated(angle)
		move_image_center_pos = move_image_center_pos.rotated(angle) - move_image_center_pos
		origin_offset = vector_rotated_tl_pos - vector_tl_pos - move_image_center_pos

	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_ROTATE_RIGHT:
		angle = PI * 0.5
		cw = CLOCKWISE
		var vector_tl_pos = Vector2(move_image.get_width() * -0.5, move_image.get_height() * -0.5)
		var vector_bl_pos = Vector2(move_image.get_width() * -0.5, move_image.get_height() * 0.5)
		var vector_rotated_tl_pos = vector_bl_pos.rotated(angle)
		move_image_center_pos = move_image_center_pos.rotated(angle) - move_image_center_pos
		origin_offset = vector_rotated_tl_pos - vector_tl_pos - move_image_center_pos
		
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_FLIP_HORIZONTAL:
		move_image.flip_x()
		move_cache_image_map.flip_x()
		
		move_image_center_pos.y = 0
		origin_offset = move_image_center_pos - move_image_center_pos * Vector2(-1, 0)
		var anchor : Vector2 = _rotate_anchor_offset * Vector2(-1, 1) - _rotate_anchor_offset
		origin_offset -= anchor
		
		_rotate_anchor_offset.x *= -1
		
	elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_FLIP_VERTICAL:
		move_image.flip_y()
		move_cache_image_map.flip_y()
		
		move_image_center_pos.x = 0
		origin_offset = move_image_center_pos - move_image_center_pos * Vector2(0, -1)
		var anchor : Vector2 = _rotate_anchor_offset * Vector2(1, -1) - _rotate_anchor_offset
		origin_offset -= anchor
		
		_rotate_anchor_offset.y *= -1
	
	elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_LEFT:
		PixelPenCPP.move_shift(Vector2i(-1, 0), move_image)
		PixelPenCPP.move_shift(Vector2i(-1, 0), move_cache_image_map)
	
	elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_UP:
		PixelPenCPP.move_shift(Vector2i(0, -1), move_image)
		PixelPenCPP.move_shift(Vector2i(0, -1), move_cache_image_map)
	
	elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_RIGHT:
		PixelPenCPP.move_shift(Vector2i(1, 0), move_image)
		PixelPenCPP.move_shift(Vector2i(1, 0), move_cache_image_map)
		
	elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_DOWN:
		PixelPenCPP.move_shift(Vector2i(0, 1), move_image)
		PixelPenCPP.move_shift(Vector2i(0, 1), move_cache_image_map)
	
	if cw != -1:
		var anchor : Vector2 = _rotate_anchor_offset.rotated(angle) - _rotate_anchor_offset
		anchor.x = snappedf(anchor.x, 0.5)
		anchor.y = snappedf(anchor.y, 0.5)

		origin_offset -= anchor
	
		_rotate_anchor_offset = _rotate_anchor_offset.rotated(angle)
		_rotate_anchor_offset.x = snappedf(_rotate_anchor_offset.x, 0.5)
		_rotate_anchor_offset.y = snappedf(_rotate_anchor_offset.y, 0.5)
	
		move_image.rotate_90(cw)
		move_cache_image_map.rotate_90(cw)
	
	if PixelPen.state.current_project.multilayer_selected.is_empty():
		node.overlay_hint.texture = ImageTexture.create_from_image(move_image)
	else:
		var base_image : Image = Image.create(node.canvas_size.x, node.canvas_size.y, false, Image.FORMAT_RGBAF)
		var rect : Rect2i = Rect2i(Vector2i.ZERO, node.canvas_size)
		for layer in PixelPen.state.current_project.active_frame.layers:
			if PixelPen.state.current_project.multilayer_selected.has(layer.layer_uid) or layer.layer_uid == index_image.layer_uid:
				var colormap : Image = layer.colormap
				if layer.layer_uid == index_image.layer_uid:
					colormap = default_cache_map
				if mask_selection == null:
					base_image.blend_rect(
							PixelPenCPP.get_image(PixelPen.state.current_project.palette.color_index, colormap, false),
							rect, Vector2i.ZERO)
					
				else:
					base_image.blend_rect(
							PixelPenCPP.get_image_with_mask(PixelPen.state.current_project.palette.color_index, colormap, mask_selection, false),
							rect, Vector2i.ZERO)
				if layer.layer_uid != index_image.layer_uid and mode == Mode.CUT:
					layer._cache_colormap = layer.colormap.duplicate()
					if mask_selection == null:
						layer.colormap.fill(Color.TRANSPARENT)
					else:
						PixelPenCPP.empty_index_on_color_map(mask_selection, layer.colormap)
					
		node.overlay_hint.texture = ImageTexture.create_from_image(base_image)
	
	node.overlay_hint.position += origin_offset
	node.overlay_hint.position = node.overlay_hint.position.round()
	
	if node.selection_tool_hint.texture != null:
		var mask_img = node.selection_tool_hint.texture.get_image()
		if cw != -1:
			mask_img.rotate_90(cw)
		elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_FLIP_HORIZONTAL:
			mask_img.flip_x()
		elif type == PixelPenEnum.ToolBoxMove.TOOL_MOVE_FLIP_VERTICAL:
			mask_img.flip_y()
		elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_LEFT:
			PixelPenCPP.move_shift(Vector2i(-1, 0), mask_img)
			mask_img = MaskSelection.get_image_no_margin(mask_img)
			var img = MaskSelection.create_empty(mask_img.get_size())
			img.blend_rect(mask_img, Rect2i(Vector2i(), mask_img.get_size()), Vector2i.ONE)
			mask_img = img
		elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_UP:
			PixelPenCPP.move_shift(Vector2i(0, -1), mask_img)
			mask_img = MaskSelection.get_image_no_margin(mask_img)
			var img = MaskSelection.create_empty(mask_img.get_size())
			img.blend_rect(mask_img, Rect2i(Vector2i(), mask_img.get_size()), Vector2i.ONE)
			mask_img = img
		elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_RIGHT:
			PixelPenCPP.move_shift(Vector2i(1, 0), mask_img)
			mask_img = MaskSelection.get_image_no_margin(mask_img)
			var img = MaskSelection.create_empty(mask_img.get_size())
			img.blend_rect(mask_img, Rect2i(Vector2i(), mask_img.get_size()), Vector2i.ONE)
			mask_img = img
		elif type == PixelPenEnum.ToolBoxMove.TOOL_SCALE_DOWN:
			PixelPenCPP.move_shift(Vector2i(0, 1), mask_img)
			mask_img = MaskSelection.get_image_no_margin(mask_img)
			var img = MaskSelection.create_empty(mask_img.get_size())
			img.blend_rect(mask_img, Rect2i(Vector2i(), mask_img.get_size()), Vector2i.ONE)
			mask_img = img
		node.selection_tool_hint.texture = ImageTexture.create_from_image(mask_img)
		mask_selection = MaskSelection.get_image_no_margin(node.selection_tool_hint.texture.get_image())
		node.selection_tool_hint.position = node.overlay_hint.position.round()
	
	index_image.colormap = cut_cache_image_map.duplicate()
	var offset : Vector2 = node.overlay_hint.position
	index_image.blit_color_map(move_cache_image_map, mask_selection, Vector2i(round(offset.x), round(offset.y)))
	
	node._update_layer_image(index_image.layer_uid)
	_mask_used_rect = Rect2i()
	_draw_hint(node.get_local_mouse_position())
	transformed = true


func _on_move_cancel():
	_rotate_anchor_offset = Vector2.ZERO
	_show_guid = false
	node.overlay_hint.texture = null
	if index_image == null or move_cache_image_map == null:
		reset()
		mode = Mode.UNKNOWN
		return
	var layer_uid : Vector3i = index_image.layer_uid
	(PixelPen.state.current_project as PixelPenProject).create_undo_layer("Move", index_image.layer_uid, func ():
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false)
			)
	index_image.colormap = default_cache_map.duplicate()
	if not PixelPen.state.current_project.multilayer_selected.is_empty() and mode == Mode.CUT:
		for multilayer_selected_layer_uid in PixelPen.state.current_project.multilayer_selected:
				if multilayer_selected_layer_uid != index_image.layer_uid:
					var multilayer_selected : IndexedColorImage = PixelPen.state.current_project.find_index_image(multilayer_selected_layer_uid)
					if multilayer_selected != null:
						multilayer_selected.colormap = multilayer_selected._cache_colormap.duplicate() 
						PixelPen.state.layer_image_changed.emit(multilayer_selected_layer_uid)
	
	if mask_selection != null:
		create_undo_selection_position(node)
		node.selection_tool_hint.position = Vector2.ZERO
		create_redo_selection_position(node)
	create_undo_overlay_position(node)
	node.overlay_hint.position = Vector2.ZERO
	create_redo_overlay_position(node)
	(PixelPen.state.current_project as PixelPenProject).create_redo_layer(index_image.layer_uid, func ():
			PixelPen.state.layer_image_changed.emit(layer_uid)
			PixelPen.state.project_saved.emit(false)
			)
	PixelPen.state.layer_image_changed.emit(layer_uid)
	PixelPen.state.project_saved.emit(false)
	move_cache_image_map = null
	node.selection_tool_hint.offset = -Vector2.ONE
	if default_selection_texture != null:
		node.selection_tool_hint.texture = ImageTexture.create_from_image(default_selection_texture)
	if index_image != PixelPen.state.current_project.active_layer:
		index_image = PixelPen.state.current_project.active_layer
	reset()
	_draw_hint(node.get_local_mouse_position())
	mode = Mode.UNKNOWN
	transformed = false
	on_end_transform()


func _on_move_commit():
	_rotate_anchor_offset = Vector2.ZERO
	if move_cache_image_map == null:
		_show_guid = false
		mode = Mode.UNKNOWN
		return
	var layer_uid : Vector3i = index_image.layer_uid
	_cache_undo_redo.create_action("Move")
	_cache_undo_redo.add_undo_property(index_image, "colormap", default_cache_map.duplicate())
	if index_image != PixelPen.state.current_project.active_layer and PixelPen.state.current_project.multilayer_selected.is_empty():
		# UNDO
		var active_layer : IndexedColorImage = PixelPen.state.current_project.active_layer
		_cache_undo_redo.add_undo_property(active_layer, "colormap", active_layer.colormap.duplicate())
		if mask_selection != null and node.selection_tool_hint.texture != null:
			_cache_undo_redo.add_undo_property(node.selection_tool_hint, "texture", ImageTexture.create_from_image(default_selection_texture))
		
		var layer_active_uid : Vector3i = active_layer.layer_uid
		_cache_undo_redo.add_undo_method(func ():
				PixelPen.state.layer_image_changed.emit(layer_uid)
				PixelPen.state.layer_image_changed.emit(layer_active_uid)
				PixelPen.state.project_saved.emit(false)
				)
		
		index_image.colormap = cut_cache_image_map.duplicate()
		
		var offset = node.overlay_hint.position
		PixelPen.state.current_project.active_layer.blit_color_map(move_cache_image_map, mask_selection, Vector2i(floor(offset.x), floor(offset.y)))
		
		# REDO
		_cache_undo_redo.add_do_property(index_image, "colormap", index_image.colormap.duplicate())
		_cache_undo_redo.add_do_property(active_layer, "colormap", active_layer.colormap.duplicate())
		if mask_selection != null and node.selection_tool_hint.texture != null:
			node.selection_tool_hint.texture = ImageTexture.create_from_image(
					MaskSelection.offset_image(node.selection_tool_hint.texture.get_image(), offset, node.canvas_size))
			_cache_undo_redo.add_do_property(node.selection_tool_hint, "texture", node.selection_tool_hint.texture)
		_cache_undo_redo.add_do_method(func():
				PixelPen.state.layer_image_changed.emit(layer_uid)
				PixelPen.state.layer_image_changed.emit(layer_active_uid)
				PixelPen.state.project_saved.emit(false)
				)
		
	else:
		var offset_ov : Vector2i = Vector2i(floor(node.overlay_hint.position.x), floor(node.overlay_hint.position.y))
		if not PixelPen.state.current_project.multilayer_selected.is_empty():
			for multilayer_selected_layer_uid in PixelPen.state.current_project.multilayer_selected:
				if multilayer_selected_layer_uid != index_image.layer_uid:
					var multilayer_selected : IndexedColorImage = PixelPen.state.current_project.find_index_image(multilayer_selected_layer_uid)
					if multilayer_selected != null:
						if mode == Mode.CUT:
							multilayer_selected.colormap = multilayer_selected._cache_colormap.duplicate()
						_cache_undo_redo.add_undo_property(multilayer_selected, "colormap", multilayer_selected.colormap.duplicate())
						_cache_undo_redo.add_undo_method(func():
								PixelPen.state.layer_image_changed.emit(multilayer_selected_layer_uid))
						
						cmd_move(multilayer_selected.colormap, offset_ov, mode, mask_selection)
						
						_cache_undo_redo.add_do_property(multilayer_selected, "colormap", multilayer_selected.colormap.duplicate())
						_cache_undo_redo.add_do_method(func():
								PixelPen.state.layer_image_changed.emit(multilayer_selected_layer_uid))
						
						PixelPen.state.layer_image_changed.emit(multilayer_selected.layer_uid)
		
		# UNDO
		if mask_selection != null and node.selection_tool_hint.texture != null:
			_cache_undo_redo.add_undo_property(node.selection_tool_hint, "texture", ImageTexture.create_from_image(default_selection_texture))
		_cache_undo_redo.add_undo_method(func ():
				PixelPen.state.layer_image_changed.emit(layer_uid)
				PixelPen.state.project_saved.emit(false)
				)
		
		# REDO
		_cache_undo_redo.add_do_property(index_image, "colormap", index_image.colormap.duplicate())
		if mask_selection != null and node.selection_tool_hint.texture != null:
			var offset = node.selection_tool_hint.position 
			node.selection_tool_hint.texture = ImageTexture.create_from_image(
					MaskSelection.offset_image(node.selection_tool_hint.texture.get_image(), offset, node.canvas_size))
			default_selection_texture = node.selection_tool_hint.texture.get_image().duplicate()
			
			_cache_undo_redo.add_do_property(node.selection_tool_hint, "texture", node.selection_tool_hint.texture)
		_cache_undo_redo.add_do_method(func():
				PixelPen.state.layer_image_changed.emit(layer_uid)
				PixelPen.state.project_saved.emit(false)
				)
	
	_cache_undo_redo.commit_action()
	on_end_transform()
	PixelPen.state.layer_image_changed.emit(layer_uid)
	if index_image != PixelPen.state.current_project.active_layer:
		index_image = PixelPen.state.current_project.active_layer
		
		var layer_active_uid : Vector3i = PixelPen.state.current_project.active_layer.layer_uid
		PixelPen.state.layer_image_changed.emit(layer_active_uid)
	
	PixelPen.state.project_saved.emit(false)
	
	move_cache_image_map = null
	node.selection_tool_hint.position = Vector2.ZERO
	node.selection_tool_hint.offset = -Vector2.ONE
	node.overlay_hint.position = Vector2.ZERO
	node.overlay_hint.texture = null
	mode = Mode.UNKNOWN
	reset()
	_draw_hint(node.get_local_mouse_position())
	_show_guid = false
	transformed = false


func create_undo_selection_position(node : Node2D):
	(PixelPen.state.current_project as PixelPenProject).create_undo_property(
			"Selection",
			node.selection_tool_hint,
			"position",
			node.selection_tool_hint.position,
			func (): pass
			)


func create_redo_selection_position(node : Node2D):
	(PixelPen.state.current_project as PixelPenProject).create_redo_property(
			node.selection_tool_hint,
			"position",
			node.selection_tool_hint.position,
			func ():pass
			)


func create_undo_overlay_position(node : Node2D):
	(PixelPen.state.current_project as PixelPenProject).create_undo_property(
			"Overlay",
			node.overlay_hint,
			"position",
			node.overlay_hint.position,
			func ():pass
			)


func create_redo_overlay_position(node : Node2D):
	(PixelPen.state.current_project as PixelPenProject).create_redo_property(
			node.overlay_hint,
			"position",
			node.overlay_hint.position,
			func ():pass
			)


func reset():
	default_cache_map = null
	cut_cache_image_map = null
	move_cache_image_map = null
	mask_selection = null

	is_pressed = false

	_pressed_offset = Vector2.ZERO
	_prev_offset = Vector2i.ZERO
	_show_guid = false
	_canvas_anchor_position = Vector2.ZERO
	_rotate_anchor_offset = Vector2.ZERO
	_is_rotate_anchor_hovered = false
	_is_move_anchor = false
	_mask_used_rect = Rect2i()


static func cmd_move(image : Image, offset : Vector2i, mode : Mode, mask : Image = null):
	if mask == null:
		var src_image : Image = image.duplicate()
		if mode == Mode.CUT:
			image.fill(Color.TRANSPARENT)
		PixelPenCPP.blit_color_map(src_image, null, offset, image)
	else:
		var cut_image : Image = PixelPenCPP.get_color_map_with_mask(mask, image)
		if mode == Mode.CUT:
			PixelPenCPP.empty_index_on_color_map(mask, image)
		PixelPenCPP.blit_color_map(cut_image, mask, offset, image)

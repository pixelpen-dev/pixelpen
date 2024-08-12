@tool
extends "tool.gd"


var SelectionTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/selection_tool.gd")

var selection_union = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-union.svg")
var selection_difference = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-difference-ba.svg")
var selection_intersection = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-intersection.svg")

var select_layer_texture = load("res://addons/net.yarvis.pixel_pen/resources/icon/layers-search-outline.svg")

static var selection_color_grow_only_axis : bool = true


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_SELECT
	active_sub_tool_type = PixelPenEnum.ToolBoxSelect.TOOL_SELECT_LAYER
	has_shift_mode = false


func _on_sub_tool_changed(type : int):
	if type == PixelPenEnum.ToolBoxSelect.TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_YES:
		selection_color_grow_only_axis = true
	elif type == PixelPenEnum.ToolBoxSelect.TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_NO:
		selection_color_grow_only_axis = false
	else:
		super._on_sub_tool_changed(type)


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if active_sub_tool_type == PixelPenEnum.ToolBoxSelect.TOOL_SELECT_COLOR:
		var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
		if index_image != null:
			var coord : Vector2i = floor(mouse_position)
			if index_image.coor_inside_canvas(coord.x, coord.y):
				var mask : Image = PixelPenCPP.get_image_flood(
					coord,
					index_image.colormap,
					Vector2i.ONE,
					selection_color_grow_only_axis
				)
				if mask != null and not mask.is_empty() and node.selection_tool_hint.texture != null:
					var selection_image = node.selection_tool_hint.texture.get_image().duplicate()
					if SelectionTool.sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION:
						mask = MaskSelection.union_image(selection_image, mask)
					elif SelectionTool.sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE:
						mask = MaskSelection.difference_image(selection_image, mask)
					elif SelectionTool.sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INTERSECTION:
						mask = MaskSelection.intersection_image(selection_image, mask)
				if mask != null and not mask.is_empty():
					create_selection_undo()
					node.selection_tool_hint.texture = ImageTexture.create_from_image(mask)
					create_selection_redo()
					node.selection_tool_hint.position = Vector2.ZERO
					node.selection_tool_hint.offset = -Vector2.ONE
					node.selection_tool_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
	elif active_sub_tool_type == PixelPenEnum.ToolBoxSelect.TOOL_SELECT_LAYER:
		var index_images : Array[IndexedColorImage] = PixelPen.state.current_project.active_frame.layers
		var coord : Vector2 = floor(mouse_position)
		for i in range(index_images.size() - 1, -1, -1):
			var palette_idx : int = index_images[i].get_index_on_color_map(coord.x, coord.y)
			var color : Color = (PixelPen.state.current_project as PixelPenProject).palette.color_index[palette_idx]
			if color.a > 0:
				var layer_uid = index_images[i].layer_uid
				PixelPen.state.layer_active_changed.emit(layer_uid)
				break


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	if active_sub_tool_type == PixelPenEnum.ToolBoxSelect.TOOL_SELECT_COLOR:
		var texture : Texture2D
		match SelectionTool.sub_tool_selection_type:
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION:
				texture = selection_union
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE:
				texture = selection_difference
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INTERSECTION:
				texture = selection_intersection
		if texture != null:
			return texture
	elif active_sub_tool_type == PixelPenEnum.ToolBoxSelect.TOOL_SELECT_LAYER:
		return select_layer_texture
	return null

@tool
extends "tool.gd"


var selection_union = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-union.svg")
var selection_difference = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-difference-ba.svg")
var selection_intersection = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-intersection.svg")

static var sub_tool_selection_type : int:
	get:
		var yes := sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION
		yes = yes or sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE
		yes = yes or sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INTERSECTION
		if not yes:
			sub_tool_selection_type = PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION
		return sub_tool_selection_type
static var can_commit_selection_polygon : bool = false
static var has_point_selection_polygon : bool = false
var pre_selection_polygon : PackedVector2Array

var _selection_image : Image


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_SELECTION
	active_sub_tool_type = sub_tool_selection_type
	has_shift_mode = false
	is_pressed = false
	can_commit_selection_polygon = false
	has_point_selection_polygon = false


func _on_request_switch_tool(tool_box_type : int) -> bool:
	return super._on_request_switch_tool(tool_box_type)


func _on_sub_tool_changed(type: int):
	if type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INVERSE:
		super._on_sub_tool_changed(type)
	elif type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_REMOVE:
		create_selection_undo()

		_selection_image = null
		build_hint_image()

		create_selection_redo()

	elif type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DELETE_SELECTED:
		delete_on_selected()
	
	elif can_commit_selection_polygon and type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_CLOSE_POLYGON:
		pre_selection_polygon.push_back(pre_selection_polygon[0])
		_create_selection()
	
	elif has_point_selection_polygon and type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_CANCEL_POLYGON:
		pre_selection_polygon.clear()
		can_commit_selection_polygon = false
		has_point_selection_polygon = false
	
	else:
		super._on_sub_tool_changed(type)
	
	var yes := active_sub_tool_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION
	yes = yes or active_sub_tool_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE
	yes = yes or active_sub_tool_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INTERSECTION
	if yes:
		sub_tool_selection_type = active_sub_tool_type


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if is_pressed:
		return
	if node.selection_tool_hint.texture != null:
		_selection_image = node.selection_tool_hint.texture.get_image().duplicate()
	else:
		_selection_image = null
	var point : Vector2 = round(mouse_position)
	for pre_point in pre_selection_polygon:
		if is_inside_circle_marker(point, pre_point):
			point = pre_point
			break
	if pre_selection_polygon.has(point):
		if pre_selection_polygon.size() >= 3 and pre_selection_polygon[0] == point:
			pre_selection_polygon.push_back(point)
			_create_selection()
		elif not pre_selection_polygon.is_empty() and pre_selection_polygon[pre_selection_polygon.size()-1] == point:
			pre_selection_polygon.remove_at(pre_selection_polygon.size()-1)
			has_point_selection_polygon = not pre_selection_polygon.is_empty()
	else:
		pre_selection_polygon.push_back(point)
	is_pressed = true and pre_selection_polygon.size() == 1
	can_commit_selection_polygon = pre_selection_polygon.size() >= 3


func _on_mouse_released(mouse_position : Vector2, _callback : Callable):
	if is_pressed:
		has_point_selection_polygon = not pre_selection_polygon.is_empty()
		if pre_selection_polygon.size() == 2:
			var size = pre_selection_polygon[1] - pre_selection_polygon[0]
			pre_selection_polygon.insert(1, pre_selection_polygon[0] + Vector2(size.x, 0))
			pre_selection_polygon.push_back(pre_selection_polygon[0] + Vector2(0, size.y))
			pre_selection_polygon.push_back(pre_selection_polygon[0])
			_create_selection()
		is_pressed = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if is_pressed and round(mouse_position) != pre_selection_polygon[0]:
		if pre_selection_polygon.size() == 2:
			pre_selection_polygon[1] = round(mouse_position)
		if pre_selection_polygon.size() == 1:
			pre_selection_polygon.push_back(round(mouse_position))


func _on_force_cancel():
	can_commit_selection_polygon = false
	has_point_selection_polygon = false
	pre_selection_polygon.clear()
	is_pressed = false


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	var texture : Texture2D
	match sub_tool_selection_type:
		PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION:
			texture = selection_union
		PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE:
			texture = selection_difference
		PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INTERSECTION:
			texture = selection_intersection
	if texture != null:
		return texture
	return null


func _on_draw_hint(mouse_position : Vector2):
	var draw_unclosed = pre_selection_polygon.size() > 0 and pre_selection_polygon[0] != pre_selection_polygon[pre_selection_polygon.size()-1]
	if is_pressed:
		_draw_rect_selection(mouse_position)
	elif (draw_unclosed or pre_selection_polygon.size() == 1):
		_draw_unclosed_selection(mouse_position)


func _draw_unclosed_selection(mouse_position : Vector2):
	for i in range(pre_selection_polygon.size()):
		if i > 0:
			node.draw_line(pre_selection_polygon[i-1], pre_selection_polygon[i], Color.WHITE)
		draw_circle_marker(pre_selection_polygon[i])
		if i == pre_selection_polygon.size() -1:
			node.draw_line(pre_selection_polygon[i], mouse_position, Color.WHITE)


func _draw_rect_selection(mouse_position : Vector2):
	draw_circle_marker(pre_selection_polygon[0])
	if pre_selection_polygon.size() == 2:
		var size = pre_selection_polygon[1] - pre_selection_polygon[0]
		draw_circle_marker(pre_selection_polygon[0] + Vector2(size.x, 0))
		draw_circle_marker(pre_selection_polygon[1])
		draw_circle_marker(pre_selection_polygon[0] + Vector2(0, size.y))
		node.draw_rect(Rect2(pre_selection_polygon[0], size), Color.WHITE, false)


func _create_selection():
	if active_sub_tool_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION:
		if _selection_image == null:
			_selection_image = MaskSelection.create_image(pre_selection_polygon, node.canvas_size)
		else:
			_selection_image = MaskSelection.union_polygon(_selection_image, pre_selection_polygon, node.canvas_size)
		
	elif active_sub_tool_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE:
		if _selection_image != null:
			_selection_image = MaskSelection.difference_polygon(_selection_image, pre_selection_polygon, node.canvas_size)
	elif active_sub_tool_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INTERSECTION:
		if _selection_image != null:
			_selection_image = MaskSelection.intersection_polygon(_selection_image, pre_selection_polygon, node.canvas_size)
	pre_selection_polygon.clear()
	can_commit_selection_polygon = false
	has_point_selection_polygon = false
	create_selection_undo()
	build_hint_image()
	create_selection_redo()


func build_hint_image():
	if _selection_image != null:
		if node.selection_tool_hint.texture == null:
			var img_tex = ImageTexture.create_from_image(_selection_image)
			node.selection_tool_hint.texture = img_tex
		else:
			node.selection_tool_hint.texture.update(_selection_image)
		node.selection_tool_hint.offset = -Vector2.ONE
		node.selection_tool_hint.position = Vector2.ZERO
		node.selection_tool_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
	else:
		node.selection_tool_hint.texture = null

@tool
extends "tool.gd"


var zoom_in_texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/zoom_in_24.svg")
var zoom_out_texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/zoom_out_24.svg")

var pressed_moused_position : Vector2
var shift_mode : bool = false


func _init():
	tool_type =  PixelPenEnum.ToolBox.TOOL_ZOOM
	active_sub_tool_type = PixelPenEnum.ToolBoxZoom.TOOL_ZOOM_IN
	has_shift_mode = true


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	var prev_mouse_offset = node.camera.get_global_transform() * node.camera.get_local_mouse_position()
	var prev_screen_offset : Vector2
	if node.virtual_mouse:
		prev_mouse_offset = mouse_position
		prev_screen_offset = node.viewport_position(mouse_position)
	var zoom_scale : float = 0.0
	if active_sub_tool_type == PixelPenEnum.ToolBoxZoom.TOOL_ZOOM_IN:
		zoom_scale = -0.2 if shift_mode else 0.2
	elif active_sub_tool_type == PixelPenEnum.ToolBoxZoom.TOOL_ZOOM_OUT:
		zoom_scale = 0.2 if shift_mode else -0.2
		
	node.camera.zoom += node.camera.zoom * zoom_scale
	
	var current_mouse_offset = node.camera.get_global_transform() * node.camera.get_local_mouse_position()
	if node.virtual_mouse:
		current_mouse_offset = node.get_global_transform().affine_inverse() * node.get_canvas_transform().affine_inverse() * prev_screen_offset
	node.camera.offset -= current_mouse_offset - prev_mouse_offset
	
	is_pressed = true
	pressed_moused_position = node.to_local(node.get_global_transform() * node.get_global_mouse_position())
	if node.selection_tool_hint.texture != null:
		node.selection_tool_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)
		node.overlay_hint.material.set_shader_parameter("zoom_bias", node.get_viewport().get_camera_2d().zoom)


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	is_pressed = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if is_pressed:
		node.camera.offset -= (node.to_local(node.get_global_transform() * node.get_global_mouse_position()) - pressed_moused_position)


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed
	PixelPen.state.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	if active_sub_tool_type == PixelPenEnum.ToolBoxZoom.TOOL_ZOOM_IN:
		return zoom_out_texture if shift_mode else zoom_in_texture
	elif active_sub_tool_type == PixelPenEnum.ToolBoxZoom.TOOL_ZOOM_OUT:
		return zoom_in_texture if shift_mode else zoom_out_texture
	return null

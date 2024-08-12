@tool
extends "tool.gd"


var pressed_moused_position : Vector2


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_PAN
	has_shift_mode = false


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	is_pressed = true
	pressed_moused_position = node.to_local(node.get_global_transform() * node.get_global_mouse_position())


func _on_mouse_released(mouse_position : Vector2, callback : Callable):
	is_pressed = false


func _on_mouse_motion(mouse_position : Vector2, event_relative : Vector2, callback : Callable):
	if is_pressed:
		node.camera.offset -= node.to_local(node.get_global_transform() * node.get_global_mouse_position()) - pressed_moused_position


func _on_draw_cursor(mouse_position : Vector2):
	draw_pan_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	return pan_texture

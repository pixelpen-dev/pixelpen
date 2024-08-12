@tool
extends Control


@export var tool_texture : Texture2D


func _process(_delta):
	if tool_texture != null:
		queue_redraw()


func _draw():
	if tool_texture != null:
		var rect : Rect2 = Rect2(get_local_mouse_position() + Vector2(8, -24), Vector2(16, 16))
		draw_texture_rect(tool_texture, rect, false)

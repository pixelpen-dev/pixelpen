@tool
extends Node2D


@export var sprite : Sprite2D
@export var camera : Camera2D

var show_grid : bool = true

var hold : bool = false
var pressed_moused_position : Vector2


func _process(_delta):
	queue_redraw()


func _input(event: InputEvent):
	if event and get_viewport_rect().has_point(get_viewport().get_mouse_position()):
		if event and event is InputEventMagnifyGesture:
			zoom(event.factor)
		elif event and event is InputEventPanGesture:
			pan(event.delta)
		elif event and event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
				zoom(0.9)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
				zoom(1.1)
			elif event.is_pressed():
				hold = true
				pressed_moused_position = to_local(get_global_mouse_position())
			elif event.is_released():
				hold = false
		elif event and event is InputEventMouseMotion:
			if hold:
				camera.offset -= to_local(get_global_mouse_position()) - pressed_moused_position


func update_camera_zoom():
	if get_viewport_rect().size != Vector2.ZERO:
		var sprite_size : Vector2 = sprite.texture.get_size() as Vector2
		var camera_scale_factor : Vector2 = get_viewport_rect().size / sprite_size
		if camera_scale_factor.x < camera_scale_factor.y:
			camera.zoom = Vector2.ONE * camera_scale_factor.x * 0.8
		else:
			camera.zoom = Vector2.ONE * camera_scale_factor.y * 0.8
		camera.position = sprite_size * 0.5
		camera.offset = Vector2.ZERO


func zoom(factor : float):
	var prev_mouse_offset = camera.get_local_mouse_position()
			
	var zoom_scale = factor - 1.0
	camera.zoom += camera.zoom * zoom_scale * 0.5
	
	var current_mouse_offset = camera.get_local_mouse_position()
	camera.offset -= current_mouse_offset - prev_mouse_offset
	queue_redraw()


func pan(offset : Vector2):
	var w = clampf(camera.zoom.length(), 1, 30)
	camera.offset += offset * lerpf(10, 1, w / 30)
	queue_redraw()


func _draw():
	if sprite.texture != null and show_grid:
		var img_size : Vector2 = sprite.texture.get_size()
		var rect : Rect2 = Rect2(Vector2.ZERO, img_size)
		draw_rect(rect, Color.MAGENTA, false)
		_draw_grid(1, 0.07, rect)
		_draw_grid(16, 0.1, rect)


func _draw_grid(grid_size : int, alpha : float, rect : Rect2):
	var canvas_size : Vector2 = rect.size
	var color = Color(1, 1, 1, alpha)
	for x in range(1 + canvas_size.x / grid_size):
		draw_line(Vector2(x * grid_size, 0) + rect.position, Vector2(x * grid_size, canvas_size.y) + rect.position, color)
	for y in range(1 + canvas_size.y / grid_size):
		draw_line(Vector2(0, y * grid_size) + rect.position, Vector2(canvas_size.x, y * grid_size) + rect.position, color)

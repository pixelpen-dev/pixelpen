@tool
extends Node2D


@export var checker : Sprite2D
@export var sprite_sheets : Sprite2D
@export var camera : Camera2D

var request_update_camera : bool = false


func update_grid(grid : Vector2i):
	checker.material.set_shader_parameter("tile_size", grid as Vector2)


func update_margin(margin : Vector2i):
	checker.material.set_shader_parameter("origin", margin as Vector2)


func update_camera_zoom():
	if is_inside_tree() and get_viewport_rect().size != Vector2.ZERO:
		var sprite_size : Vector2 = checker.texture.get_size() as Vector2
		var camera_scale_factor : Vector2 = get_viewport_rect().size / sprite_size
		if camera_scale_factor.x < camera_scale_factor.y:
			camera.zoom = Vector2.ONE * camera_scale_factor.x * 0.9
		else:
			camera.zoom = Vector2.ONE * camera_scale_factor.y * 0.9
		camera.position = sprite_size * 0.5
		camera.offset = Vector2.ZERO
		request_update_camera = false
	else:
		request_update_camera = true


func _process(_delta):
	if request_update_camera:
		update_camera_zoom()

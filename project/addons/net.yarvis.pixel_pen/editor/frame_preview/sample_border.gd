@tool
extends Node2D


@export var frame_preview : Control


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	PixelPen.project_file_changed.connect(func ():
			queue_redraw())


func _draw():
	if PixelPen.current_project == null:
		return
	var draw : bool = frame_preview.show_cache_frame and PixelPen.current_project.use_sample
	if draw:
		position = PixelPen.current_project._sample_offset
		var rect := Rect2(Vector2.ZERO, PixelPen.current_project.canvas_size)
		draw_rect(rect, Color.MAGENTA, false)

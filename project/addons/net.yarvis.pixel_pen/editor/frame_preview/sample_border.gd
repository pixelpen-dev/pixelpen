@tool
extends Node2D


@export var frame_preview : Control


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	PixelPen.state.project_file_changed.connect(func ():
			queue_redraw())


func _draw():
	if PixelPen.state.current_project == null:
		return
	var draw : bool = frame_preview.show_cache_frame and PixelPen.state.current_project.use_sample
	if draw:
		position = PixelPen.state.current_project._sample_offset
		var rect := Rect2(Vector2.ZERO, PixelPen.state.current_project.canvas_size)
		draw_rect(rect, Color.MAGENTA, false)

@tool
extends Timer


@export var parent : Control
@export var frame_preview : Control

var index : int
var is_playing : bool:
	get:
		return not is_stopped()


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	PixelPen.state.project_file_changed.connect(func ():
			anim_play(false)
			)
	PixelPen.state.project_saved.connect(func(_s):
			if PixelPen.state.current_project == null or \
					not PixelPen.state.current_project.show_timeline or \
					PixelPen.state.current_project.use_sample:
				anim_play(false)
			)
	parent.visibility_changed.connect(func():
			if not parent.visible and is_playing:
				anim_play(false)
			)
	timeout.connect(_on_frame_play_timer_timeout)


func anim_play(is_play):
	frame_preview.clear_layer()
	if is_play:
		if PixelPen.state.current_project.animation_timeline.size() == 0:
			return
		frame_preview.use_canvas_frame = false
		frame_preview.show_cache_frame = false
		index = maxi(0, PixelPen.state.current_project.animation_frame_index)
		frame_preview.show_frame(PixelPen.state.current_project.animation_timeline[index].frame)
		frame_preview._create_layers()
		var frame_time = 1.0 / PixelPen.state.current_project.animation_fps
		one_shot = false
		start(frame_time)
	else:
		stop()
		frame_preview.use_canvas_frame = true
		frame_preview.show_cache_frame = true
		frame_preview._create_layers()


func _on_frame_play_timer_timeout():
	if PixelPen.state.current_project.animation_timeline.size() == 0:
		anim_play(false)
		return
	index += 1
	if index >= PixelPen.state.current_project.animation_timeline.size():
		index = 0
	frame_preview.show_frame(PixelPen.state.current_project.animation_timeline[index].frame)
	frame_preview._create_layers()

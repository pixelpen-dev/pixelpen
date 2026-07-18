@tool
extends AcceptDialog


@export var tab_container : TabContainer


func _init():
	add_to_group("pixelpen_popup")


func _ready():
	_resize_window()
	tab_container.current_tab = 0
	if not PixelPen.state.ui_scale_changed.is_connected(_resize_window):
		PixelPen.state.ui_scale_changed.connect(_resize_window)


func _exit_tree() -> void:
	if PixelPen.state.ui_scale_changed.is_connected(_resize_window):
		PixelPen.state.ui_scale_changed.disconnect(_resize_window)


func _resize_window():
	var screen_size : Rect2i = DisplayServer.screen_get_usable_rect().grow(-128)
	# screen_get_usable_rect() is in physical pixels, but an embedded dialog's
	# size is in the embedding window's layout units, which get multiplied by
	# its content_scale_factor when rendered. Divide so the dialog still fits
	# on screen when a UI scale above 1 is active. Native (non-embedded)
	# windows are sized in physical pixels, so no correction is needed there.
	var divisor := 1.0
	if is_embedded():
		var embedder := get_parent().get_window()
		if embedder != null:
			divisor = maxf(embedder.content_scale_factor, 0.1)
	var target := Vector2(screen_size.size) / divisor
	size.x = mini(int(target.y * 1.5), int(target.x))
	size.y = int(target.y)

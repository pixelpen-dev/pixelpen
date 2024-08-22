@tool
extends ColorRect


signal hue_changed(hue)
signal double_click


@export_range(0.0, 1.0, 0.001) var hue : float = 0.5

var _pressed : bool = false
var _double_click_t : float
var _first_click_coor : Vector2


func _draw() -> void:
	draw_rect(Rect2(Vector2(hue * size.x - 1, 0.0), Vector2(2, size.y)), Color.WHITE, false, 0.5, true)
	draw_rect(Rect2(Vector2(hue * size.x - 1, 0.0), Vector2(2, size.y)).grow(1.0), Color.BLACK, false, 0.5, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if Time.get_unix_time_from_system() - _double_click_t < 0.5 and _first_click_coor.is_equal_approx(event.position):
				double_click.emit()
			else:
				(PixelPen.state.current_project as PixelPenProject).create_undo_palette("Change palette color", func ():
						PixelPen.state.palette_changed.emit()
						)
				_double_click_t = Time.get_unix_time_from_system()
				_first_click_coor = event.position
				_pressed = true
				pick(event)

	if _pressed and event is InputEventMouseMotion:
		pick(event)
		hue_changed.emit(hue)


func pick(event: InputEvent) -> void:
	hue = event.position.x / size.x
	hue = clampf(hue, 0.0, 1.0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if _pressed:
				hue_changed.emit(hue)
				(PixelPen.state.current_project as PixelPenProject).create_redo_palette(func ():
						PixelPen.state.palette_changed.emit()
						)
			_pressed = false

@tool
extends Control


signal alpha_changed(alpha)
signal double_click


@export var color : Color = Color.WHITE:
	set(v):
		color = v
		if get_node_or_null("ColorRect"):
			$ColorRect.color = v
			$ColorRect.color.a = 1.0

var _pressed : bool = false
var _double_click_t : float
var _first_click_coor : Vector2


func _draw() -> void:
	draw_rect(Rect2(Vector2(color.a * size.x - 1, 0.0), Vector2(2, size.y)), Color.FIREBRICK, false, 0.5, true)
	draw_rect(Rect2(Vector2(color.a * size.x - 1, 0.0), Vector2(2, size.y)).grow(1.0), Color.WHITE, false, 0.5, true)


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
		alpha_changed.emit(color.a)


func pick(event: InputEvent) -> void:
	color.a = event.position.x / size.x
	color.a = clampf(color.a, 0.0, 1.0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if _pressed:
				alpha_changed.emit(color.a)
				(PixelPen.state.current_project as PixelPenProject).create_redo_palette(func ():
						PixelPen.state.palette_changed.emit()
						)
			_pressed = false

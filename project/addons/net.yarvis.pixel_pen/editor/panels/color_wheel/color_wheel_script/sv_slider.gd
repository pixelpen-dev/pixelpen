@tool
extends ColorRect

signal sv_changed(s, v)
signal double_click

@export_range(0.0, 1.0, 0.001) var hue : float = 0.5:
	set(v):
		if v != hue:
			hue = v
			(material as ShaderMaterial).set_shader_parameter("hue", hue)
@export_range(0.0, 1.0, 0.001) var saturation : float = 0.5
@export_range(0.0, 1.0, 0.001) var value : float = 0.5

var _pressed : bool = false
var _double_click_t : float
var _first_click_coor : Vector2


func _draw() -> void:
	draw_arc(Vector2(saturation, 1.0 - value) * size, 3.0, 0, TAU, 100, Color.WHITE, 0.5, true);


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
		sv_changed.emit(saturation, value)


func pick(event: InputEvent) -> void:
	var coordinate = event.position / size
	coordinate.x = clampf(coordinate.x, 0.0, 1.0)
	coordinate.y = clampf(coordinate.y, 0.0, 1.0)
	saturation = coordinate.x
	value = 1.0 - coordinate.y
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if _pressed:
				sv_changed.emit(saturation, value)
				(PixelPen.state.current_project as PixelPenProject).create_redo_palette(func ():
						PixelPen.state.palette_changed.emit()
						)
			_pressed = false

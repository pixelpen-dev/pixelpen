@tool
extends Node


var is_pressed : bool = false
var default_position : Vector2
var mouse_offset_position : Vector2

var timer : float = 0

var on_hold : bool = false


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	
	var parent : Button = get_parent()
	parent.button_down.connect(func():
			timer = 0
			on_hold = true
			default_position = (owner as Control).get_child(0).global_position
			mouse_offset_position = (owner as Control).get_child(0).get_global_mouse_position() - default_position
			(owner as Control)._on_button_pressed()
			)
	parent.button_up.connect(func():
			on_hold = false
			if is_pressed:
				_on_released()
			)


func _on_pressed():
	is_pressed = true
	(owner as Control).get_child(0).top_level = true
	(owner as Control).get_child(0).modulate.a = 0.75
	if (owner as Control).get_parent().has_method("_on_pickable_pressed"):
		var mouse = mouse_offset_position + default_position
		(owner as Control).get_parent()._on_pickable_pressed(mouse, (owner as Control).layer_uid, 0)
		mouse_offset_position.y = 20


func _on_released():
	(owner as Control).get_child(0).top_level = false
	is_pressed = false
	(owner as Control).get_child(0).global_position = default_position
	(owner as Control).get_child(0).modulate.a = 1.0
	if (owner as Control).get_parent().has_method("_on_pickable_pressed"):
		var mouse = (owner as Control).get_global_mouse_position()
		(owner as Control).get_parent()._on_pickable_pressed(mouse, (owner as Control).layer_uid, 2)


func _process(delta):
	if not PixelPen.state.need_connection(get_window()):
		return
	if on_hold:
		timer = min(timer + delta, 0.3) 
		if timer == 0.3:
			_on_pressed()
			timer = 0
			on_hold = false
		if not get_window().has_focus():
			on_hold = false
			is_pressed = false
	if is_pressed:
		var mouse = (owner as Control).get_global_mouse_position()
		(owner as Control).get_child(0).global_position = mouse - mouse_offset_position + Vector2(-20, 5)
		
		if (owner as Control).get_parent().has_method("_on_pickable_pressed"):
			(owner as Control).get_parent()._on_pickable_pressed(mouse, (owner as Control).layer_uid, 1)

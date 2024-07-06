@tool
class_name ToggleButton
extends BaseButton

signal value_changed(value)

var _theme := load("res://addons/net.yarvis.pixel_pen/resources/default_theme.tres")


enum ToggleButtonMode{ TWO, THREE}

@export var label_left : String:
	set(v):
		if label_left != v:
			label_left = v
			left_button.text = label_left
@export var label_mid : String:
	set(v):
		if label_mid != v:
			label_mid = v
			mid_button.text = label_mid
@export var label_right : String:
	set(v):
		if label_right != v:
			label_right = v
			right_button.text = label_right
@export var mode : ToggleButtonMode:
	set(v):
		if mode != v:
			mode = v
			_build()
@export var value : int:
	set(v):
		if v != value:
			value = v
			_build()


var left_button := Button.new()
var mid_button := Button.new()
var right_button := Button.new()


func _init():
	left_button.toggled.connect(func(toggle_on : bool):
			if toggle_on:
				value_changed.emit(0)
			)
	mid_button.toggled.connect(func(toggle_on : bool):
			if toggle_on:
				value_changed.emit(1)
			)
	right_button.toggled.connect(func(toggle_on : bool):
			if toggle_on:
				value_changed.emit(1 if mode == ToggleButtonMode.TWO else 2)
			)
	
	var grub := ButtonGroup.new()
	left_button.button_group = grub
	right_button.button_group = grub
	mid_button.button_group = grub
	_build()
	add_child(mid_button)
	add_child(left_button)
	add_child(right_button)


func _build():
	left_button.theme_type_variation = "ToggleLeft"
	left_button.text = label_left
	left_button.toggle_mode = true
	left_button.set_pressed_no_signal(value == 0)
	left_button.anchor_left= 0.0
	left_button.anchor_top = 0.0
	left_button.anchor_bottom = 1.0
	
	mid_button.visible = mode == ToggleButtonMode.THREE
	
	right_button.theme_type_variation = "ToggleRight"
	right_button.text = label_right
	right_button.toggle_mode = true
	right_button.set_pressed_no_signal((mode == ToggleButtonMode.TWO and value == 1) or (mode == ToggleButtonMode.THREE and value == 2))
	right_button.anchor_top = 0.0
	right_button.anchor_right = 1.0
	right_button.anchor_bottom = 1.0
	
	if mode == ToggleButtonMode.TWO:
		left_button.anchor_right = 0.5
		right_button.anchor_left = 0.5
	else:
		left_button.anchor_right = 0.33
		right_button.anchor_left = 0.66
		
		mid_button.theme_type_variation = "ToggleMid"
		mid_button.text = label_mid
		mid_button.toggle_mode = true
		mid_button.set_pressed_no_signal(value == 1)
		mid_button.anchor_left = 0.33
		mid_button.anchor_top = 0.0
		mid_button.anchor_right = 0.66
		mid_button.anchor_bottom = 1.0

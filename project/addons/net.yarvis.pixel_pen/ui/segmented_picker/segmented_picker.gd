@tool
class_name PixelPenSegmentedPicker
extends HBoxContainer


signal picked(value)

const VALUE_META : StringName = &"segmented_value"

var _group : ButtonGroup
var _value


func _init():
	add_theme_constant_override("separation", 0)


func set_options(options : Array, selected_value = null):
	for child in get_children():
		child.queue_free()
	_group = ButtonGroup.new()
	_value = null
	var count : int = options.size()
	var buttons : Array[Button] = []
	for i in range(count):
		var option = options[i]
		var label : String = option["label"] if option is Dictionary else str(option)
		var value = option["value"] if option is Dictionary else option
		if i > 0:
			add_child(VSeparator.new())
		var btn := Button.new()
		btn.text = label
		btn.toggle_mode = true
		btn.button_group = _group
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.theme_type_variation = _variation_for(i, count)
		btn.set_meta(VALUE_META, value)
		if selected_value != null and _same(value, selected_value):
			btn.set_pressed_no_signal(true)
			_value = value
		btn.pressed.connect(func():
				_value = value
				picked.emit(value)
				)
		add_child(btn)
		buttons.push_back(btn)
	_equalize_widths.call_deferred(buttons)


func _equalize_widths(buttons : Array[Button]):
	var widest : float = 0.0
	for btn in buttons:
		if is_instance_valid(btn):
			widest = maxf(widest, btn.get_minimum_size().x)
	for btn in buttons:
		if is_instance_valid(btn):
			btn.custom_minimum_size.x = widest


func get_value():
	return _value


func select(value):
	for child in get_children():
		if child is Button and child.has_meta(VALUE_META) and _same(child.get_meta(VALUE_META), value):
			child.set_pressed_no_signal(true)
			_value = value
			return


func _variation_for(index : int, count : int) -> StringName:
	if count == 1:
		return &"ToggleLeft"
	if index == 0:
		return &"ToggleLeft"
	if index == count - 1:
		return &"ToggleRight"
	return &"ToggleMid"


func _same(a, b) -> bool:
	return typeof(a) == typeof(b) and a == b

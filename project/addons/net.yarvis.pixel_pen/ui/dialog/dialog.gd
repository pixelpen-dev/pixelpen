@tool
class_name PixelPenDialog
extends Window


signal confirmed
signal canceled

var primary_button : PixelPenAccentButton
var cancel_button : Button

var _content : VBoxContainer


func _init(p_title : String = "", p_primary_text : String = "OK", p_size : Vector2i = Vector2i(340, 0)):
	title = p_title
	size = p_size
	min_size = Vector2i(p_size.x, 0)
	wrap_controls = true
	visible = false
	transient = true
	exclusive = true
	theme = load("res://addons/net.yarvis.pixel_pen/resources/default_theme.tres")

	var bg := Panel.new()
	bg.theme_type_variation = &"WindowPanel"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	_content = VBoxContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	column.add_child(_content)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)

	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_cancel)
	actions.add_child(cancel_button)

	primary_button = PixelPenAccentButton.new(p_primary_text)
	primary_button.pressed.connect(confirm)
	actions.add_child(primary_button)

	close_requested.connect(_cancel)


func get_content() -> VBoxContainer:
	return _content


func add_field(item : PixelPenPropertyItem) -> PixelPenPropertyField:
	var field := PixelPenPropertyField.new(item)
	_content.add_child(field)
	return field


func confirm():
	hide()
	confirmed.emit()


func _cancel():
	hide()
	canceled.emit()


func _process(_delta):
	if visible and Input.is_key_pressed(KEY_ESCAPE):
		_cancel()


func _unhandled_key_input(event : InputEvent):
	if not visible:
		return
	var key := event as InputEventKey
	if key != null and key.pressed and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
		confirm()

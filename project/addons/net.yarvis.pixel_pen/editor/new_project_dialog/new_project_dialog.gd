@tool
extends Window


signal confirmed
signal canceled


@export var name_node : LineEdit
@export var width_node : LineEdit
@export var height_node : LineEdit
@export var preview_aspect_ratio : AspectRatioContainer
@export var canvas : ColorRect
@export var cancel_button : Button
@export var confirm_button : PixelPenAccentButton

var _width : float:
	get:
		return max(1, width_node.text as float)
var _height : float:
	get:
		return max(1, height_node.text as float)


func _init():
	visible = false
	add_to_group("pixelpen_popup")


func _ready():
	confirm_button.accent = PixelPen.state.userconfig.accent_color
	confirm_button.pressed.connect(_confirm)
	cancel_button.pressed.connect(_cancel)
	close_requested.connect(_cancel)
	width_node.text_changed.connect(func(_t): _update_canvas_aspect_ratio())
	height_node.text_changed.connect(func(_t): _update_canvas_aspect_ratio())
	_update_canvas_aspect_ratio()
	name_node.grab_focus.call_deferred()
	height_node.focus_next = confirm_button.get_path()
	cancel_button.focus_next = name_node.get_path()


func _confirm():
	var current_project = PixelPenProject.new()
	current_project.initialized(
			Vector2i(_width as int,
			_height as int), name_node.text if name_node.text != "" else "Untitled"
	)
	PixelPen.state.current_project = current_project
	hide()
	confirmed.emit()


func _cancel():
	hide()
	canceled.emit()


func _update_canvas_aspect_ratio():
	var ratio = _width / _height
	preview_aspect_ratio.ratio = ratio
	_update_shader_checker.call_deferred()


func _update_shader_checker():
	var tile_total_x = 16
	var tile_size = canvas.size.x / tile_total_x
	canvas.material.set_shader_parameter("tile_size", Vector2.ONE * tile_size)


func _on_size_changed():
	_update_shader_checker()


func _process(_delta):
	if not visible:
		return
	if Input.is_key_pressed(KEY_ESCAPE):
		_cancel()
	elif Input.is_key_pressed(KEY_ENTER) and (width_node.has_focus() or height_node.has_focus() or name_node.has_focus()):
		_confirm()

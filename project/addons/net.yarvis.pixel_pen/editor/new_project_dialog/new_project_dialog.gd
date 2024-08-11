@tool
extends ConfirmationDialog


@export var name_node : LineEdit
@export var width_node : LineEdit
@export var height_node : LineEdit
@export var preview_aspect_ratio : AspectRatioContainer
@export var canvas : ColorRect

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
	_update_canvas_aspect_ratio()
	name_node.grab_focus.call_deferred()
	height_node.focus_next = get_ok_button().get_path()
	get_cancel_button().focus_next = name_node.get_path()


func _update_canvas_aspect_ratio():
	var ratio = _width / _height
	preview_aspect_ratio.ratio = ratio
	_update_shader_checker.call_deferred()


func _update_shader_checker():
	var tile_total_x = 16
	var tile_size = canvas.size.x / tile_total_x
	canvas.material.set_shader_parameter("tile_size", Vector2.ONE * tile_size)


func _on_line_edit_w_text_changed(new_text):
	_update_canvas_aspect_ratio()


func _on_line_edit_h_text_changed(new_text):
	_update_canvas_aspect_ratio()


func _on_line_edit_grid_text_changed(new_text):
	_update_shader_checker.call_deferred()


func _on_line_edit_name_text_changed(new_text):
	pass # Replace with function body.


func _on_size_changed():
	_update_shader_checker()


func _on_confirmed():
	var current_project = PixelPenProject.new()
	current_project.initialized(
			Vector2i(_width as int, 
			_height as int),name_node.text if name_node.text != "" else "Untitled"
	)
	PixelPen.state.current_project = current_project


func _process(_delta):
	if Input.is_key_pressed(KEY_ENTER) and (width_node.has_focus() or height_node.has_focus() or name_node.has_focus()):
		get_ok_button().pressed.emit()

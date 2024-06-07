@tool
extends ConfirmationDialog


@export var name_node : LineEdit
@export var width_node : LineEdit
@export var height_node : LineEdit
@export var checker_node : LineEdit
@export var preview_aspect_ratio : AspectRatioContainer
@export var canvas : ColorRect

var _width : float:
	get:
		return max(1, width_node.text as float)
var _height : float:
	get:
		return max(1, height_node.text as float)
var _checker : float:
	get:
		return max(1, checker_node.text as float)


func _init():
	visible = false
	add_to_group("pixelpen_popup")


func _ready():
	_update_canvas_aspect_ratio()


func _update_canvas_aspect_ratio():
	var ratio = _width / _height
	preview_aspect_ratio.ratio = ratio
	_update_shader_checker.call_deferred()


func _update_shader_checker():
	var tile_total_x = _width / _checker
	var preview_size = canvas.size
	var tile_size = preview_size.x / tile_total_x
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
			_height as int),name_node.text if name_node.text != "" else "Untitled",
			_checker as int
	)
	PixelPen.current_project = current_project

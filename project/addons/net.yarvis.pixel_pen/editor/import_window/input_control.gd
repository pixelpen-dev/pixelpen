@tool
extends SubViewportContainer


@export var node2d_wrapper : Node2D


func _input(event):
	if Engine.is_editor_hint():
		node2d_wrapper._input(event)


func _unhandled_input(event):
	grab_focus()

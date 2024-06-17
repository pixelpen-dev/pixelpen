@tool
extends SubViewportContainer


@export var editor_canvas : Node2D


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return


func _input(event):
	if not PixelPen.state.need_connection(get_window()):
		return
	if Engine.is_editor_hint():
		editor_canvas._input(event)


func _unhandled_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ENTER:
			# grab focus back from line edit
			grab_focus()


func _on_mouse_entered():
	if PixelPen.state.current_project != null and get_window().has_focus():
		if PixelPen.state.userconfig.hide_cursor_in_canvas:
			var has_popup : bool = get_tree().get_first_node_in_group("pixelpen_popup") != null
			if has_popup:
				has_popup = false
				for popup in get_tree().get_nodes_in_group("pixelpen_popup"):
					if popup.visible:
						has_popup = true
						break
			if not editor_canvas.virtual_mouse and not has_popup:
				Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		grab_focus()
	if PixelPen.state.current_project != null and not PixelPen.state.current_project.active_layer_is_valid():
		editor_canvas.canvas_paint.tool._can_draw = false


func _on_mouse_exited():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	release_focus()

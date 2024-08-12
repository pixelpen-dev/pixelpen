@tool
extends "tool.gd"


var texture := load("res://addons/net.yarvis.pixel_pen/resources/icon/color_picker_plus.svg")

var shift_mode : bool = false


func _init():
	tool_type = PixelPenEnum.ToolBox.TOOL_COLOR_PICKER
	has_shift_mode = true


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	var palette_idx : int = pick_color_from_canvas(mouse_position, false)
	if palette_idx != -1:
		(PixelPen.state.current_project as PixelPenProject).create_undo_palette("Palette", func():
				PixelPen.state.palette_changed.emit()
				PixelPen.state.project_saved.emit(false)
				)
		
		PixelPen.state.current_project.palette.color_index[_index_color] = PixelPen.state.current_project.palette.color_index[palette_idx]
		
		(PixelPen.state.current_project as PixelPenProject).create_redo_palette(func():
				PixelPen.state.palette_changed.emit()
				PixelPen.state.project_saved.emit(false)
				)
		
		PixelPen.state.palette_changed.emit()
		PixelPen.state.project_saved.emit(false)


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed
	PixelPen.state.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	draw_plus_cursor(mouse_position)


func _on_get_tool_texture() -> Texture2D:
	if shift_mode:
		return color_picker_texture
	return texture

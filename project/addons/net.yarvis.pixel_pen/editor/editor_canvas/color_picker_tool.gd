@tool
extends "tool.gd"


const texture := preload("../../resources/icon/color_picker_plus.svg")

var shift_mode : bool = false


func _init():
	tool_type = PixelPen.ToolBox.TOOL_COLOR_PICKER
	has_shift_mode = true


func _on_mouse_pressed(mouse_position : Vector2, callback : Callable):
	if shift_mode:
		pick_color_from_canvas(mouse_position)
		return
	var palette_idx : int = pick_color_from_canvas(mouse_position, false)
	if palette_idx != -1:
		(PixelPen.current_project as PixelPenProject).create_undo_palette("Palette", func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				)
		
		PixelPen.current_project.palette.color_index[_index_color] = PixelPen.current_project.palette.color_index[palette_idx]
		
		(PixelPen.current_project as PixelPenProject).create_redo_palette(func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				)
		
		PixelPen.palette_changed.emit()
		PixelPen.project_saved.emit(false)


func _on_shift_pressed(pressed : bool):
	shift_mode = pressed
	PixelPen.toolbox_shift_mode.emit(shift_mode)


func _on_draw_cursor(mouse_position : Vector2):
	if shift_mode:
		draw_color_picker_cursor(mouse_position)
		return
	draw_plus_cursor(mouse_position)
	var cursor_length : float = (node.get_viewport_transform().affine_inverse() * 20.0).x.x
	draw_texture(mouse_position + Vector2(0.5, -1.5) * cursor_length, texture)

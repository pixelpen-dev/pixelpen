@tool
extends Control


@export var parent_window : ConfirmationDialog


func _draw():
	var anchor = parent_window.anchor
	var color = Color.BLACK
	var color_active = PixelPen.state.userconfig.accent_color
	var grid_size : Vector2 = size / 5
	
	draw_line(Vector2(grid_size.x, grid_size.y * 0.5), Vector2(grid_size.x * 2, grid_size.y * 0.5), color)
	draw_line(Vector2(grid_size.x * 3, grid_size.y * 0.5), Vector2(grid_size.x * 4, grid_size.y * 0.5), color)
	
	draw_line(Vector2(grid_size.x * 0.5, grid_size.y), Vector2(grid_size.x * 0.5, grid_size.y * 2), color)
	draw_line(Vector2(grid_size.x * 0.5, grid_size.y * 3), Vector2(grid_size.x * 0.5, grid_size.y * 4), color)
	
	draw_line(Vector2(grid_size.x * 4.5, grid_size.y), Vector2(grid_size.x * 4.5, grid_size.y * 2), color)
	draw_line(Vector2(grid_size.x * 4.5, grid_size.y * 3), Vector2(grid_size.x * 4.5, grid_size.y * 4), color)
	
	draw_line(Vector2(grid_size.x, grid_size.y * 4.5), Vector2(grid_size.x * 2, grid_size.y * 4.5), color)
	draw_line(Vector2(grid_size.x * 3, grid_size.y * 4.5), Vector2(grid_size.x * 4, grid_size.y * 4.5), color)
	
	draw_rect(Rect2(Vector2(0, 0), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.TOP_LEFT else color, false)
	draw_rect(Rect2(Vector2(grid_size.x * 2, 0), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.TOP else color, false)
	draw_rect(Rect2(Vector2(grid_size.x * 4, 0), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.TOP_RIGHT else color, false)
	
	draw_rect(Rect2(Vector2(0, grid_size.y * 2), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.LEFT else color, false)
	draw_rect(Rect2(Vector2(grid_size.x * 2, grid_size.y * 2), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.CENTER else color, false)
	draw_rect(Rect2(Vector2(grid_size.x * 4, grid_size.y * 2), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.RIGHT else color, false)
	
	draw_rect(Rect2(Vector2(0, grid_size.y * 4), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.BOTTOM_LEFT else color, false)
	draw_rect(Rect2(Vector2(grid_size.x * 2, grid_size.y * 4), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.BOTTOM else color, false)
	draw_rect(Rect2(Vector2(grid_size.x * 4, grid_size.y * 4), grid_size), color_active if anchor == PixelPenEnum.ResizeAnchor.BOTTOM_RIGHT else color, false)


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			var grid_size : Vector2 = size / 3
			if Rect2(Vector2.ZERO, grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.TOP_LEFT
				queue_redraw()
			elif Rect2(Vector2(grid_size.x, 0), grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.TOP
				queue_redraw()
			elif Rect2(Vector2(grid_size.x * 2, 0), grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.TOP_RIGHT
				queue_redraw()
			elif Rect2(Vector2(0, grid_size.y), grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.LEFT
				queue_redraw()
			elif Rect2(Vector2(grid_size.x, grid_size.y), grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.CENTER
				queue_redraw()
			elif Rect2(Vector2(grid_size.x * 2, grid_size.y), grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.RIGHT
				queue_redraw()
			elif Rect2(Vector2(0, grid_size.y * 2), grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.BOTTOM_LEFT
				queue_redraw()
			elif Rect2(Vector2(grid_size.x, grid_size.y * 2), grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.BOTTOM
				queue_redraw()
			elif Rect2(Vector2(grid_size.x * 2, grid_size.y * 2), grid_size).has_point(event.position):
				parent_window.anchor = PixelPenEnum.ResizeAnchor.BOTTOM_RIGHT
				queue_redraw()

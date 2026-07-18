@tool
extends Control

## Hosts the pixel canvas SubViewport.
##
## This used to be a SubViewportContainer with stretch enabled, but that sizes
## the SubViewport in window layout units. When the window uses a UI scale
## (Window.content_scale_factor > 1) layout units are fewer than physical
## pixels, so the canvas would render at reduced resolution and get upscaled
## (soft pixels). Instead this plain Control sizes the SubViewport manually:
##   - SubViewport.size             = control size * ui scale  (physical pixels)
##   - SubViewport.size_2d_override = control size             (layout units)
##   - size_2d_override_stretch     = true
## Godot's stretch transform then renders 2D content 1:1 with physical pixels
## while cameras, input and get_viewport_rect() keep working in layout units,
## so pointer-to-pixel mapping is unchanged. A plain Control is used because
## SubViewportContainer with stretch disabled reports the SubViewport pixel
## size as its minimum size, which would balloon the layout at scale > 1.


@export var editor_canvas : Node2D


func _init():
	# Same default as the SubViewportContainer this node replaced, so
	# grab_focus()/release_focus() keep working.
	focus_mode = Control.FOCUS_CLICK


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	resized.connect(_update_render_size)
	if not PixelPen.state.ui_scale_changed.is_connected(_update_render_size):
		PixelPen.state.ui_scale_changed.connect(_update_render_size)
	_update_render_size.call_deferred()


func _get_sub_viewport() -> SubViewport:
	if editor_canvas != null:
		return editor_canvas.get_parent() as SubViewport
	return get_node_or_null("SubViewport") as SubViewport


func _ui_scale() -> float:
	var window := get_window()
	if window == null:
		return 1.0
	return maxf(window.content_scale_factor, 0.1)


func _update_render_size():
	var sub_viewport := _get_sub_viewport()
	if sub_viewport == null:
		return
	var layout_size := Vector2i(size.round())
	layout_size.x = maxi(layout_size.x, 2)
	layout_size.y = maxi(layout_size.y, 2)
	var render_size := Vector2i((size * _ui_scale()).round())
	render_size.x = maxi(render_size.x, 2)
	render_size.y = maxi(render_size.y, 2)
	sub_viewport.size_2d_override_stretch = true
	sub_viewport.size = render_size
	sub_viewport.size_2d_override = layout_size
	queue_redraw()


func _draw():
	var sub_viewport := _get_sub_viewport()
	if sub_viewport == null:
		return
	var texture := sub_viewport.get_texture()
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)


func _gui_input(event):
	if not PixelPen.state.need_connection(get_window()):
		return
	# Forward positional events to the canvas viewport. Event positions are in
	# this control's local coordinates, which equal the SubViewport's 2D
	# override units, so no extra transform is needed.
	if event is InputEventMouse or event is InputEventScreenTouch \
			or event is InputEventScreenDrag or event is InputEventGesture:
		var sub_viewport := _get_sub_viewport()
		if sub_viewport != null:
			sub_viewport.push_input(event, true)


func _input(event):
	if not PixelPen.state.need_connection(get_window()):
		return
	if Engine.is_editor_hint():
		editor_canvas._input(event)
		return
	# Forward non-positional events (keyboard) so canvas shortcuts keep
	# working; positional events are forwarded from _gui_input instead.
	if event is InputEventMouse or event is InputEventScreenTouch \
			or event is InputEventScreenDrag or event is InputEventGesture:
		return
	var sub_viewport := _get_sub_viewport()
	if sub_viewport != null:
		sub_viewport.push_input(event, true)


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

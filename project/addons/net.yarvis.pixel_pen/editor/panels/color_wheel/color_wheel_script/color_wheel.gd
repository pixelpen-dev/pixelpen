@tool
extends Control


signal color_changed(color)


@export var color : Color:
	set(v):
		if v != color:
			color = v
			if sv_slider and hue_slider and alpha_slider:
				sv_slider.hue = color.h if color.s > 0 else hue_slider.hue
				sv_slider.saturation = color.s
				sv_slider.value = color.v
				hue_slider.hue = color.h if color.s > 0 else hue_slider.hue
				alpha_slider.color = color
				sv_slider.queue_redraw()
				hue_slider.queue_redraw()
				alpha_slider.queue_redraw()

@export_category("Node")
@export var sv_slider : Control
@export var hue_slider : Control
@export var alpha_slider : Control


func _ready() -> void:
	sv_slider.hue = color.h
	sv_slider.saturation = color.s
	sv_slider.value = color.v
	hue_slider.hue = color.h
	alpha_slider.color = color
	sv_slider.queue_redraw()
	hue_slider.queue_redraw()
	alpha_slider.queue_redraw()
	if not PixelPen.state.need_connection(get_window()):
		return
	PixelPen.state.project_file_changed.connect(
		func ():
			visible = PixelPen.state.current_project != null)
	visible = PixelPen.state.current_project != null


func _on_double_click() -> void:
	var color_picker := ColorPickerButton.new()
	color_picker.get_picker().can_add_swatches = false
	color_picker.get_picker().presets_visible = false
	color_picker.color = color
	color_picker.popup_closed.connect(func():
			color_picker.queue_free()
			if color_picker.color != color:
				color = color_picker.color
				color_changed.emit(color)
			)
	color_picker.visible = false
	add_child(color_picker)
	color_picker.get_popup().popup_centered()


func _on_sv_slider_sv_changed(s: Variant, v: Variant) -> void:
	color = Color.from_hsv(hue_slider.hue, s, v, alpha_slider.color.a)
	color_changed.emit(color)


func _on_hue_slider_hue_changed(hue: Variant) -> void:
	color = Color.from_hsv(hue, sv_slider.saturation, sv_slider.value, alpha_slider.color.a)
	sv_slider.hue = hue
	sv_slider.queue_redraw()
	color_changed.emit(color)


func _on_alpha_slider_alpha_changed(alpha):
	color.a = alpha
	color_changed.emit(color)

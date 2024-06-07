@tool
extends Control


signal selected(index)


enum Mode{
	BRUSH,
	STAMP,
}

@export var mode : Mode
@export var preview : TextureRect
@export var button : Button
@export var vbox : Control
@export var popup_panel : PopupPanel

var brush_index : int

var _panel_size : Vector2
var _cache_images : Array[Image]


func _ready():
	popup_panel.hide()


func select(index : int):
	if index < _cache_images.size() and index >= 0:
		preview.texture = ImageTexture.create_from_image(_cache_images[index])
		brush_index = index
		vbox.queue_redraw()
	else:
		preview.texture = null


func build_panel(build_mode : Mode):
	mode = build_mode
	if mode == Mode.BRUSH:
		_cache_images.clear()
		for img in PixelPen.userconfig.brush:
			var imga : Image = Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
			PixelPen.utils.fill_color(img, imga, Color8(255, 255, 255, 255), null)
			_cache_images.push_back(imga)
	elif mode == Mode.STAMP:
		_cache_images = PixelPen.userconfig.stamp
	for child in vbox.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	var count : int = 0
	for i in range(_cache_images.size()):
		var margin = MarginContainer.new()
		margin.show_behind_parent = true
		var margin_value = 8
		margin.add_theme_constant_override("margin_top", margin_value)
		margin.add_theme_constant_override("margin_left", margin_value)
		margin.add_theme_constant_override("margin_bottom", margin_value)
		margin.add_theme_constant_override("margin_right", margin_value)
		margin.custom_minimum_size = Vector2(64, 64)

		var texture_rect = TextureRect.new()
		texture_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.texture = ImageTexture.create_from_image(_cache_images[i])
		texture_rect.gui_input.connect(func(event):
				input(vbox.get_children().find(margin), event)
				)
		
		margin.add_child(texture_rect)
		vbox.add_child(margin)
		count += 1
	vbox.custom_minimum_size = Vector2(64 * 5, 64 + (count / 5) * 64)
	_panel_size = vbox.custom_minimum_size + Vector2(24, 32)
	button.text = "---" if _cache_images.is_empty() else ""


func _on_button_pressed():
	popup_panel.popup(Rect2i(global_position + Vector2(size.x, size.x), _panel_size))


func input(index, event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			popup_panel.hide()
			selected.emit(index)
		elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			popup_panel.hide()
			if mode == Mode.BRUSH:
				PixelPen.userconfig.delete_brush(index)
			elif mode == Mode.STAMP:
				PixelPen.userconfig.delete_stamp(index)
			build_panel(mode)
			if brush_index > index:
				selected.emit(brush_index - 1)
			else:
				selected.emit(brush_index)

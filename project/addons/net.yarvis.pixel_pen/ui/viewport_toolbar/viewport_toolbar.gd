@tool
class_name PixelPenViewportToolbar
extends PanelContainer


signal grid_toggled(active : bool)
signal zoom_out_pressed
signal zoom_in_pressed
signal fit_pressed

var show_grid_button : bool = true:
	set(value):
		show_grid_button = value
		if _grid_button != null:
			_grid_button.visible = value
			_grid_separator.visible = value

var _grid_button : PixelPenIconButton
var _grid_separator : VSeparator
var _zoom_label : Label


func _init():
	theme_type_variation = &"PanelFloat"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	add_child(row)

	_grid_button = PixelPenIconButton.new(
			ThemeConfig.ui_icon("res://addons/net.yarvis.pixel_pen/resources/icon/grid_3x3_24.svg"),
			"Toggle grid")
	_grid_button.pressed.connect(func():
			_grid_button.active = not _grid_button.active
			grid_toggled.emit(_grid_button.active)
			)
	row.add_child(_grid_button)

	_grid_separator = VSeparator.new()
	row.add_child(_grid_separator)

	var zoom_out := PixelPenIconButton.new(
			ThemeConfig.ui_icon("res://addons/net.yarvis.pixel_pen/resources/icon/remove_24dp.svg"),
			"Zoom out")
	zoom_out.pressed.connect(func(): zoom_out_pressed.emit())
	row.add_child(zoom_out)

	_zoom_label = Label.new()
	_zoom_label.custom_minimum_size = Vector2(56, 0)
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_label.text = "100%"
	row.add_child(_zoom_label)

	var zoom_in := PixelPenIconButton.new(
			ThemeConfig.ui_icon("res://addons/net.yarvis.pixel_pen/resources/icon/add_24.svg"),
			"Zoom in")
	zoom_in.pressed.connect(func(): zoom_in_pressed.emit())
	row.add_child(zoom_in)

	row.add_child(VSeparator.new())

	var fit := PixelPenIconButton.new(
			ThemeConfig.ui_icon("res://addons/net.yarvis.pixel_pen/resources/icon/fit-to-screen-outline.svg"),
			"Fit to view")
	fit.pressed.connect(func(): fit_pressed.emit())
	row.add_child(fit)


func set_zoom_percent(percent : int):
	_zoom_label.text = str(percent, "%")


func set_grid_active(active : bool):
	_grid_button.active = active


func set_grid_shortcut(shortcut : Shortcut):
	_grid_button.shortcut = shortcut

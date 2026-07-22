@tool
extends Window


const SECTION_COLOR : Color = Color(0.56, 0.56, 0.56)


func _ready():
	var rail : VBoxContainer = %Rail

	_section(rail, "PROPERTY FIELDS")
	var rows : Array[PixelPenPropertyItem] = [
		PixelPenPropertyItem.create_int("Width", 320, 1, 4096),
		PixelPenPropertyItem.create_range("Strength", 0.35, 0.0, 1.0, 0.05),
		PixelPenPropertyItem.create_vector2i("Canvas size", "W", "H", Vector2i(320, 240), Vector2i.ONE, Vector2i(4096, 4096)),
		PixelPenPropertyItem.create_enum("Direction", 0, ["Forward", "Reverse"] as Array[String]),
		PixelPenPropertyItem.create_enum("Export format", 1, ["*.png", "*.jpg", "*.webp", "*.gif"] as Array[String]),
		PixelPenPropertyItem.create_color("Grid color", Color(0.25, 1.0, 0.5), true),
	]
	for row in rows:
		var field : PixelPenPropertyField = PixelPenPropertyField.new(row)
		field.value_changed.connect(func(value):
				print(row.label, " -> ", value)
				)
		rail.add_child(field)

	rail.add_child(HSeparator.new())
	_section(rail, "BUTTONS")
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	rail.add_child(buttons)
	var cancel := Button.new()
	cancel.text = "Cancel"
	buttons.add_child(cancel)
	buttons.add_child(PixelPenAccentButton.new("Import"))
	var grid_icon := PixelPenIconButton.new(
			ThemeConfig.ui_icon("res://addons/net.yarvis.pixel_pen/resources/icon/grid_3x3_24.svg"),
			"Toggle grid")
	grid_icon.active = true
	buttons.add_child(grid_icon)
	buttons.add_child(PixelPenIconButton.new(
			ThemeConfig.ui_icon("res://addons/net.yarvis.pixel_pen/resources/icon/folder_24.svg"),
			"Select file"))

	rail.add_child(HSeparator.new())
	_section(rail, "SEGMENTED PICKER")
	var scale_picker := PixelPenSegmentedPicker.new()
	scale_picker.set_options([
			{"label": "x4", "value": 4}, {"label": "x2", "value": 2},
			{"label": "x1", "value": 1}, {"label": "x1/2", "value": -2},
			{"label": "x1/4", "value": -4},
			], 1)
	scale_picker.picked.connect(func(value): print("scale -> ", value))
	rail.add_child(scale_picker)
	var dither_picker := PixelPenSegmentedPicker.new()
	dither_picker.set_options(["None", "Bayer", "Noise"], "None")
	dither_picker.picked.connect(func(value): print("dither -> ", value))
	rail.add_child(dither_picker)

	rail.add_child(HSeparator.new())
	_section(rail, "PALETTE STRIP")
	var strip := PixelPenPaletteStrip.new()
	rail.add_child(strip)
	strip.set_colors(_ramp())

	rail.add_child(HSeparator.new())
	_section(rail, "VIEWPORT TOOLBAR")
	var toolbar_row := HBoxContainer.new()
	rail.add_child(toolbar_row)
	var toolbar := PixelPenViewportToolbar.new()
	toolbar.set_zoom_percent(96)
	toolbar.set_grid_active(true)
	toolbar_row.add_child(toolbar)

	rail.add_child(HSeparator.new())
	_section(rail, "DIALOG")
	var open_dialog := Button.new()
	open_dialog.text = "Open dialog..."
	open_dialog.tooltip_text = "PixelPenDialog scaffold with property fields"
	open_dialog.pressed.connect(_open_dialog)
	rail.add_child(open_dialog)

	close_requested.connect(hide)


func _open_dialog():
	var dialog := PixelPenDialog.new("Resize Canvas", "Apply")
	dialog.add_field(PixelPenPropertyItem.create_vector2i("Size", "W", "H", Vector2i(320, 240), Vector2i.ONE, Vector2i(4096, 4096)))
	dialog.add_field(PixelPenPropertyItem.create_enum("Anchor", 1, ["Left", "Center", "Right"] as Array[String]))
	dialog.add_field(PixelPenPropertyItem.create_enum("Interpolation", 0, ["Nearest", "Bilinear", "Cubic", "Lanczos"] as Array[String]))
	dialog.confirmed.connect(func():
			print("dialog confirmed")
			dialog.queue_free()
			)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()


func _ramp() -> PackedColorArray:
	var ramp : PackedColorArray = []
	ramp.push_back(Color8(16, 16, 16))
	for i in range(23):
		ramp.push_back(Color.from_hsv(0.08 + 0.5 * (i / 23.0), 0.65, 0.9))
	return ramp


func _section(rail : VBoxContainer, text : String):
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", SECTION_COLOR)
	rail.add_child(label)

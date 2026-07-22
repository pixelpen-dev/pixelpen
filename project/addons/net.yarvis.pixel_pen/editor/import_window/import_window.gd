@tool
extends Window


signal closed
signal confirmed
signal canceled


const SCALE_MAX_EXPONENT : int = 2
const SCALE_MIN_EXPONENT : int = -5
const IMPORT_SIZE_LIMIT : int = 16384


@export var sprite : Sprite2D
@export var scale_seg : PixelPenSegmentedPicker
@export var size_label : Label
@export var toolbar : PixelPenViewportToolbar
@export var grid_view : Node2D
@export var colors_check : PixelPenToggleButton
@export var colors_spin : SpinBox
@export var colors_label : Label
@export var swatch_strip : PixelPenPaletteStrip
@export var cancel_button : Button
@export var import_button : PixelPenAccentButton

var _src_image : Image
var _scaled_image : Image
var _distinct_colors : int = 0
var _scale_exponent : int = 0
var _first : bool = true
var _zoom_percent : int = -1


func _init():
	add_to_group("pixelpen_popup")


func _ready():
	ThemeConfig.upgrade_icons(self)
	import_button.accent = PixelPen.state.userconfig.accent_color
	toolbar.grid_toggled.connect(func(active : bool):
			grid_view.show_grid = active
			)
	toolbar.set_grid_active(grid_view.show_grid)
	toolbar.set_grid_shortcut(PixelPen.state.userconfig.shorcuts.view_show_grid)
	toolbar.zoom_in_pressed.connect(func(): grid_view.zoom_at_center(1.25))
	toolbar.zoom_out_pressed.connect(func(): grid_view.zoom_at_center(0.8))
	toolbar.fit_pressed.connect(func(): grid_view.update_camera_zoom())
	scale_seg.picked.connect(_on_scale_selected)
	import_button.pressed.connect(func():
			hide()
			confirmed.emit()
			)
	cancel_button.pressed.connect(_cancel)
	close_requested.connect(_cancel)
	colors_check.value_changed.connect(func(_value : int):
			_refresh_preview()
			)
	colors_spin.value_changed.connect(func(_value : float):
			if _reduce_enabled():
				_refresh_preview()
			)


func _cancel():
	hide()
	canceled.emit()


func _process(_delta):
	if _first:
		grab_focus()
		_first = false
		grid_view.update_camera_zoom()
	_update_zoom_label()
	if visible and Input.is_key_pressed(KEY_ESCAPE):
		_cancel()


func show_file(path : String):
	_src_image = Image.load_from_file(path)
	_src_image.convert(Image.FORMAT_RGBA8)
	if _src_image.is_empty():
		return
	_scaled_image = _src_image
	_scale_exponent = 0
	_update_scale_range()
	_setup_colors_default()
	_refresh_preview()


func get_image()->Image:
	return sprite.texture.get_image()


func _free_palette_slots() -> int:
	var project : PixelPenProject = PixelPen.state.current_project
	if project == null:
		return IndexedPalette.INDEX_COLOR_SIZE - 2
	var free : int = 0
	for i in range(1, project.palette.color_index.size()):
		if project.palette.color_index[i].a == 0:
			free += 1
	return free


func _setup_colors_default():
	var free_slots : int = maxi(2, _free_palette_slots())
	_distinct_colors = PixelPenCPP.count_distinct_colors(_scaled_image)
	colors_spin.min_value = 2
	colors_spin.max_value = free_slots
	colors_spin.set_value_no_signal(mini(free_slots, maxi(2, _distinct_colors)))
	colors_check.value = 1 if _distinct_colors > free_slots else 0


func _reduce_enabled() -> bool:
	return colors_check.value == 1


func _refresh_preview():
	if _scaled_image == null:
		return
	_distinct_colors = PixelPenCPP.count_distinct_colors(_scaled_image)
	var image : Image = _scaled_image
	if _reduce_enabled() and _distinct_colors > int(colors_spin.value):
		image = PixelPenCPP.quantize_colors(_scaled_image, int(colors_spin.value))
	sprite.texture = ImageTexture.create_from_image(image)
	_update_colors_label()
	_update_swatches(image)
	update_label()


func _update_colors_label():
	var free_slots : int = maxi(2, _free_palette_slots())
	if _reduce_enabled() and _distinct_colors > int(colors_spin.value):
		colors_label.text = str(_fmt(_distinct_colors), " colors → ", int(colors_spin.value), " · ", free_slots, " slots free")
	else:
		colors_label.text = str(_fmt(_distinct_colors), " colors · ", free_slots, " slots free")
	if not _reduce_enabled() and _distinct_colors > free_slots:
		colors_label.text = str(_fmt(_distinct_colors), " colors exceed ", free_slots, " free slots")
		colors_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	else:
		colors_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))


func _update_swatches(image : Image):
	if not _reduce_enabled() and _distinct_colors > IndexedPalette.INDEX_COLOR_SIZE - 1:
		swatch_strip.visible = false
		return
	var pal : PackedColorArray = PackedColorArray()
	pal.resize(IndexedPalette.INDEX_COLOR_SIZE)
	pal.fill(Color.TRANSPARENT)
	var dummy : Image = Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_R8)
	pal = PixelPenCPP.import_image(dummy, image, pal)
	swatch_strip.set_colors(pal)


func _fmt(n : int) -> String:
	var s : String = str(n)
	var out : String = ""
	var count : int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


func _update_scale_range():
	var img_size : Vector2i = _src_image.get_size()
	var smallest : int = mini(img_size.x, img_size.y)
	var largest : int = maxi(img_size.x, img_size.y)
	var min_exponent : int = 0
	while min_exponent > SCALE_MIN_EXPONENT and (smallest >> (abs(min_exponent) + 1)) >= 1:
		min_exponent -= 1
	var max_exponent : int = 0
	while max_exponent < SCALE_MAX_EXPONENT and largest * pow(2, max_exponent + 1) <= IMPORT_SIZE_LIMIT:
		max_exponent += 1
	var options : Array = []
	var exponent : int = max_exponent
	while exponent >= min_exponent:
		options.push_back({"label": _scale_multiplier(exponent), "value": exponent})
		exponent -= 1
	scale_seg.set_options(options, _scale_exponent)


func _scale_multiplier(exponent : int) -> String:
	if exponent >= 0:
		return str("x", pow(2, exponent) as int)
	return str("x1/", pow(2, abs(exponent)) as int)


func _update_zoom_label():
	var percent : int = grid_view.get_zoom_percent()
	if percent != _zoom_percent:
		_zoom_percent = percent
		toolbar.set_zoom_percent(percent)


func _on_scale_selected(exponent : int):
	if _src_image == null:
		return
	_scale_exponent = exponent
	var previous_size : Vector2 = sprite.texture.get_size()
	if exponent == 0:
		_scaled_image = _src_image
	elif exponent > 0:
		scale_up(pow(2, exponent))
	else:
		scale_down(pow(2, abs(exponent)))
	_refresh_preview()
	var new_size : Vector2 = sprite.texture.get_size()
	if previous_size.x > 0:
		grid_view.rescale_view(new_size.x / previous_size.x)


func update_label():
	size_label.text = str(_src_image.get_width(), " × ", _src_image.get_height(), " px  →  ",
			sprite.texture.get_width() , " × ", sprite.texture.get_height(), " px")


func scale_up(factor : int):
	var img_size = _src_image.get_size()
	if img_size.x * factor >= 1 and img_size.y * factor >= 1:
		var new_img : Image = _src_image.duplicate()
		new_img.resize(img_size.x * factor, img_size.y * factor, Image.INTERPOLATE_NEAREST)
		_scaled_image = new_img


func scale_down(factor : int):
	var img_size = _src_image.get_size()
	if img_size.x / factor >= 1 and img_size.y / factor >= 1:
		var new_img : Image = _src_image.duplicate()
		new_img.resize(img_size.x / factor, img_size.y / factor, Image.INTERPOLATE_NEAREST)
		_scaled_image = new_img

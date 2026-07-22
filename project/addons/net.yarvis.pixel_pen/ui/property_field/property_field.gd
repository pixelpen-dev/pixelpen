@tool
class_name PixelPenPropertyField
extends Control


signal value_changed(value)

var tree_row : PixelPenPropertyItem
var column_ratio : float = 0.5
var label_alignment : HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
var list_margin : float = 8

var folder_icon := ThemeConfig.ui_icon("res://addons/net.yarvis.pixel_pen/resources/icon/folder_24.svg")


func _init(p_row : PixelPenPropertyItem = null, p_column_ratio : float = 0.5, p_alignment : HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, p_list_margin : float = 8):
	column_ratio = p_column_ratio
	label_alignment = p_alignment
	list_margin = p_list_margin
	if p_row != null:
		tree_row = p_row
		build()


func build():
	if tree_row == null:
		return
	for child in get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	anchor_left = 0
	anchor_right = 1
	match tree_row.field:
		PixelPenPropertyItem.FieldMode.INT:
			_step_field()
		PixelPenPropertyItem.FieldMode.FLOAT:
			_step_field()
		PixelPenPropertyItem.FieldMode.RANGE:
			_range_field()
		PixelPenPropertyItem.FieldMode.STRING:
			_string_field()
		PixelPenPropertyItem.FieldMode.VECTOR2:
			_vector2_field()
		PixelPenPropertyItem.FieldMode.VECTOR2I:
			_vector2i_field()
		PixelPenPropertyItem.FieldMode.ENUM:
			if tree_row.enum_option.size() == 2 or tree_row.enum_option.size() == 3:
				_toggle_field()
			else:
				_enum_field()
		PixelPenPropertyItem.FieldMode.FILE_PATH:
			_file_field()
		PixelPenPropertyItem.FieldMode.COLOR:
			_color_field()


func _emit(value):
	value_changed.emit(value)


func _main_label() -> Label:
	var label : Label = Label.new()
	label.text = tree_row.label
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = column_ratio
	label.anchor_bottom = 1
	label.offset_right = -list_margin
	label.horizontal_alignment = label_alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	return label


func _step_field():
	var spinner : SpinBox = SpinBox.new()
	spinner.get_line_edit().add_child(SelectLineEdit.new())
	var spinner_wrapper : Panel = Panel.new()
	spinner_wrapper.theme_type_variation = "PanelEdit"

	_main_label()

	spinner.get_line_edit().theme_type_variation = "LineEditClean"
	match tree_row.field:
		PixelPenPropertyItem.FieldMode.INT:
			spinner.min_value = tree_row.int_min
			spinner.max_value = tree_row.int_max
			spinner.step = tree_row.int_step
			spinner.value = tree_row.int_value
			spinner.value_changed.connect(func(new_value : float):
					tree_row.int_value = new_value as int
					_emit(tree_row.int_value)
			)
		PixelPenPropertyItem.FieldMode.FLOAT:
			spinner.min_value = tree_row.float_min
			spinner.max_value = tree_row.float_max
			spinner.step = tree_row.float_step
			spinner.value = tree_row.float_value
			spinner.value_changed.connect(func(new_value : float):
					tree_row.float_value = new_value
					_emit(tree_row.float_value)
			)
	spinner.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner.set_anchors_preset(Control.PRESET_FULL_RECT)
	spinner_wrapper.add_child(spinner)

	spinner_wrapper.anchor_left = column_ratio
	spinner_wrapper.anchor_top = 0
	spinner_wrapper.anchor_right = 1.0
	spinner_wrapper.anchor_bottom = 1

	add_child(spinner_wrapper)
	custom_minimum_size.y = 30

	spinner.get_line_edit().text_submitted.connect(func(_v):
			spinner.get_line_edit().release_focus()
			)


func _range_field():
	var label_value : Label = Label.new()
	var panel : Panel = Panel.new()
	var slider : HSlider = HSlider.new()

	_main_label()

	panel.anchor_left = column_ratio
	panel.anchor_top = 0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1
	add_child(panel)

	label_value.text = str(tree_row.range_value)
	label_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_value.anchor_left = column_ratio
	label_value.anchor_top = 0
	label_value.anchor_right = 1.0
	label_value.anchor_bottom = 1
	label_value.offset_right = -16
	add_child(label_value)

	slider.min_value = tree_row.range_min
	slider.max_value = tree_row.range_max
	slider.step = tree_row.range_step
	slider.value = tree_row.range_value
	slider.anchor_left = column_ratio + 0.01
	slider.anchor_top = 0.65
	slider.anchor_right = 0.99
	slider.anchor_bottom = 0.65
	add_child(slider)
	custom_minimum_size.y = 30

	slider.value_changed.connect(func(new_value : float):
			tree_row.range_value = new_value
			label_value.text = str(new_value)
			_emit(tree_row.range_value)
			)


func _string_field():
	var line_edit : LineEdit = LineEdit.new()
	line_edit.add_child(SelectLineEdit.new())

	_main_label()

	line_edit.text = tree_row.string_value
	line_edit.anchor_left = column_ratio
	line_edit.anchor_top = 0
	line_edit.anchor_right = 1.0
	line_edit.anchor_bottom = 1
	add_child(line_edit)
	custom_minimum_size.y = 30

	line_edit.text_changed.connect(func(new_value : String):
			tree_row.string_value = new_value
			_emit(tree_row.string_value)
			)
	line_edit.text_submitted.connect(func(_v):
			line_edit.release_focus()
			)


func _dual_spinner(label_x : String, label_y : String) -> Array[SpinBox]:
	var label_a : Label = Label.new()
	var label_b : Label = Label.new()
	var spinner_x : SpinBox = SpinBox.new()
	spinner_x.get_line_edit().add_child(SelectLineEdit.new())
	var spinner_y : SpinBox = SpinBox.new()
	spinner_y.get_line_edit().add_child(SelectLineEdit.new())

	var spinner_wrapper_x : Panel = Panel.new()
	spinner_wrapper_x.theme_type_variation = "PanelEdit"
	spinner_x.get_line_edit().theme_type_variation = "LineEditClean"

	var spinner_wrapper_y : Panel = Panel.new()
	spinner_wrapper_y.theme_type_variation = "PanelEdit"
	spinner_y.get_line_edit().theme_type_variation = "LineEditClean"

	if label_alignment == HORIZONTAL_ALIGNMENT_LEFT:
		var label_main : Label = Label.new()
		label_main.text = tree_row.label
		label_main.anchor_left = 0
		label_main.anchor_top = 0
		label_main.anchor_right = column_ratio
		label_main.anchor_bottom = 0.5
		label_main.offset_right = -list_margin
		label_main.horizontal_alignment = label_alignment
		label_main.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label_main.offset_bottom = -1
		add_child(label_main)

	label_a.text = label_x
	if label_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		label_a.text = tree_row.label + " " + label_a.text
	label_a.anchor_left = 0
	label_a.anchor_top = 0
	label_a.anchor_right = column_ratio
	label_a.anchor_bottom = 0.5
	label_a.offset_right = -list_margin
	label_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_a.offset_bottom = -1
	add_child(label_a)

	label_b.text = label_y
	label_b.anchor_left = 0
	label_b.anchor_top = 0.5
	label_b.anchor_right = column_ratio
	label_b.anchor_bottom = 1.0
	label_b.offset_right = -list_margin
	label_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_b.offset_top = 1
	add_child(label_b)

	spinner_x.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner_x.set_anchors_preset(Control.PRESET_FULL_RECT)
	spinner_wrapper_x.anchor_left = column_ratio
	spinner_wrapper_x.anchor_top = 0
	spinner_wrapper_x.anchor_right = 1.0
	spinner_wrapper_x.anchor_bottom = 0.5
	spinner_wrapper_x.offset_bottom = -1
	spinner_wrapper_x.add_child(spinner_x)
	add_child(spinner_wrapper_x)

	spinner_y.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner_y.set_anchors_preset(Control.PRESET_FULL_RECT)
	spinner_wrapper_y.anchor_left = column_ratio
	spinner_wrapper_y.anchor_top = 0.5
	spinner_wrapper_y.anchor_right = 1.0
	spinner_wrapper_y.anchor_bottom = 1
	spinner_wrapper_y.offset_top = 1
	spinner_wrapper_y.add_child(spinner_y)
	add_child(spinner_wrapper_y)

	custom_minimum_size.y = 60 + 2

	spinner_x.get_line_edit().text_submitted.connect(func(_v):
			spinner_x.get_line_edit().release_focus()
			)
	spinner_y.get_line_edit().text_submitted.connect(func(_v):
			spinner_y.get_line_edit().release_focus()
			)
	return [spinner_x, spinner_y]


func _vector2_field():
	var spinners : Array[SpinBox] = _dual_spinner(tree_row.vector2_label_x, tree_row.vector2_label_y)
	var spinner_x : SpinBox = spinners[0]
	var spinner_y : SpinBox = spinners[1]

	spinner_x.min_value = tree_row.vector2_min.x
	spinner_x.max_value = tree_row.vector2_max.x
	spinner_x.step = tree_row.vector2_step.x
	spinner_x.value = tree_row.vector2_value.x

	spinner_y.min_value = tree_row.vector2_min.y
	spinner_y.max_value = tree_row.vector2_max.y
	spinner_y.step = tree_row.vector2_step.y
	spinner_y.value = tree_row.vector2_value.y

	spinner_x.value_changed.connect(func(new_value : float):
			tree_row.vector2_value.x = new_value
			_emit(tree_row.vector2_value)
			)
	spinner_y.value_changed.connect(func(new_value : float):
			tree_row.vector2_value.y = new_value
			_emit(tree_row.vector2_value)
			)


func _vector2i_field():
	var spinners : Array[SpinBox] = _dual_spinner(tree_row.vector2i_label_x, tree_row.vector2i_label_y)
	var spinner_x : SpinBox = spinners[0]
	var spinner_y : SpinBox = spinners[1]

	spinner_x.min_value = tree_row.vector2i_min.x
	spinner_x.max_value = tree_row.vector2i_max.x
	spinner_x.step = tree_row.vector2i_step.x
	spinner_x.value = tree_row.vector2i_value.x

	spinner_y.min_value = tree_row.vector2i_min.y
	spinner_y.max_value = tree_row.vector2i_max.y
	spinner_y.step = tree_row.vector2i_step.y
	spinner_y.value = tree_row.vector2i_value.y

	spinner_x.value_changed.connect(func(new_value : float):
			tree_row.vector2i_value.x = new_value as int
			_emit(tree_row.vector2i_value)
			)
	spinner_y.value_changed.connect(func(new_value : float):
			tree_row.vector2i_value.y = new_value as int
			_emit(tree_row.vector2i_value)
			)


func _toggle_field():
	var toggle : PixelPenToggleButton = PixelPenToggleButton.new()

	_main_label()

	toggle.anchor_left = column_ratio
	toggle.anchor_top = 0
	toggle.anchor_right = 1
	toggle.anchor_bottom = 1

	if tree_row.enum_option.size() == 2:
		toggle.mode = PixelPenToggleButton.ToggleButtonMode.TWO
		toggle.value = tree_row.enum_value
		toggle.label_left = tree_row.enum_option[0]
		toggle.label_right = tree_row.enum_option[1]
	if tree_row.enum_option.size() == 3:
		toggle.mode = PixelPenToggleButton.ToggleButtonMode.THREE
		toggle.value = tree_row.enum_value
		toggle.label_left = tree_row.enum_option[0]
		toggle.label_mid = tree_row.enum_option[1]
		toggle.label_right = tree_row.enum_option[2]
	add_child(toggle)

	toggle.value_changed.connect(func(new_value : int):
			tree_row.enum_value = new_value
			_emit(tree_row.enum_value)
			)

	custom_minimum_size.y = 30


func _enum_field():
	var option : OptionButton = OptionButton.new()

	_main_label()

	for i in range(tree_row.enum_option.size()):
		option.add_item(tree_row.enum_option[i], i)
	# Select after populating: setting `selected` on an empty OptionButton is a
	# no-op and the first added item would stay selected instead.
	if tree_row.enum_option.size() > tree_row.enum_value:
		option.selected = tree_row.enum_value
	option.alignment = HORIZONTAL_ALIGNMENT_CENTER
	option.anchor_left = column_ratio
	option.anchor_top = 0
	option.anchor_right = 1
	option.anchor_bottom = 1
	add_child(option)

	custom_minimum_size.y = 30

	option.item_selected.connect(func(index : int):
			tree_row.enum_value = index
			_emit(tree_row.enum_value)
			option.release_focus()
			)


func _file_field():
	var line_edit : LineEdit = LineEdit.new()
	line_edit.add_child(SelectLineEdit.new())
	var file_button : TextureButton = TextureButton.new()
	var hover = Node.new()
	var mat = ShaderMaterial.new()
	mat.shader = load("res://addons/net.yarvis.pixel_pen/resources/tint_color.gdshader")

	_main_label()

	line_edit.text = tree_row.file_value
	line_edit.anchor_left = column_ratio
	line_edit.anchor_top = 0
	line_edit.anchor_right = 1.0
	line_edit.anchor_bottom = 1
	line_edit.offset_right = -30
	add_child(line_edit)

	file_button.material = mat
	file_button.tooltip_text = "Select file"
	file_button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	file_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	file_button.texture_normal = folder_icon
	file_button.anchor_left = 1
	file_button.anchor_top = 0
	file_button.anchor_right = 1
	file_button.anchor_bottom = 1
	file_button.offset_left = -30
	file_button.pressed.connect(func():
			_select_file(func (file):
					line_edit.text = str(file, " ") ## Add space to fix bug invisible last character
					tree_row.file_value = file
					_emit(tree_row.file_value),
			tree_row.file_dialog_filters,
			tree_row.file_mode
			))
	line_edit.text_changed.connect(func(text : String):
			tree_row.file_value = text
			_emit(tree_row.file_value)
			)
	line_edit.text_submitted.connect(func(_v):
			line_edit.release_focus()
			)

	add_child(file_button)

	hover.set_script(load("res://addons/net.yarvis.pixel_pen/editor/editor_main_ui/button_hover.gd"))
	hover.can_active = false
	mat.set_shader_parameter("tint", hover.default_color)
	file_button.add_child(hover)

	custom_minimum_size.y = 30


func _color_field():
	var color_picker_btn : ColorPickerButton = ColorPickerButton.new()

	_main_label()

	color_picker_btn.edit_alpha = tree_row.color_alpha
	color_picker_btn.color = tree_row.color_value
	color_picker_btn.anchor_left = column_ratio
	color_picker_btn.anchor_top = 0
	color_picker_btn.anchor_right = 1.0
	color_picker_btn.anchor_bottom = 1
	add_child(color_picker_btn)
	custom_minimum_size.y = 30

	color_picker_btn.popup_closed.connect(func():
			tree_row.color_value = color_picker_btn.color
			_emit(tree_row.color_value)
			color_picker_btn.release_focus()
			)


func _select_file(callback : Callable, filter : PackedStringArray, mode : FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE):
	var _file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = not PixelPen.state.is_mobile()
	_file_dialog.file_mode = mode
	_file_dialog.filters = filter

	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.current_dir = PixelPen.state.get_directory()
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			callback.call(file)
			_file_dialog.queue_free()
			)
	_file_dialog.files_selected.connect(func(files):
			_file_dialog.hide()
			callback.call(files)
			_file_dialog.queue_free()
			)
	_file_dialog.dir_selected.connect(func(dir):
			_file_dialog.hide()
			callback.call(dir)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			if mode == FileDialog.FileMode.FILE_MODE_OPEN_FILES:
				callback.call([])
			else:
				callback.call("")
			_file_dialog.queue_free())

	add_child(_file_dialog)
	_file_dialog.popup_centered(PixelPen.state.file_dialog_size(self))
	_file_dialog.grab_focus()

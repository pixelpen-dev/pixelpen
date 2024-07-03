@tool
extends Control


signal value_changed(index, value)

enum FloatAligment{
	FLOAT_LEFT = 0,
	FLOAT_RIGHT = 2
}

var folder_icon := load("res://addons/net.yarvis.pixel_pen/resources/icon/folder_24.svg")

@export var structure : Array[TreeRow]
@export var list_margin : float = 8
@export_range(0.0, 1.0, 0.001) var column_ratio : float = 0.5: 
	set(v):
		if column_ratio != v:
			column_ratio = clampf(v, 0.0, 1.0)
@export var main_label_aligment : FloatAligment = FloatAligment.FLOAT_LEFT

var _aligment : HorizontalAlignment:
	get:
		return HORIZONTAL_ALIGNMENT_LEFT if main_label_aligment == FloatAligment.FLOAT_LEFT else HORIZONTAL_ALIGNMENT_RIGHT

## Call this if strcuture property update manually by code
func build():
	_clean_up()
	
	for row in structure:
		match row.field:
			TreeRow.FieldMode.INT:
				add_child(_step_field(row))
			TreeRow.FieldMode.FLOAT:
				add_child(_step_field(row))
			TreeRow.FieldMode.RANGE:
				add_child(_range_field(row))
			TreeRow.FieldMode.STRING:
				add_child(_string_field(row))
			TreeRow.FieldMode.VECTOR2:
				add_child(_vector2_field(row))
			TreeRow.FieldMode.VECTOR2I:
				add_child(_vector2i_field(row))
			TreeRow.FieldMode.ENUM:
				if row.enum_option.size() == 2 or row.enum_option.size() == 3:
					add_child(_toggle_field(row))
				else:
					add_child(_enum_field(row))
			TreeRow.FieldMode.FILE_PATH:
				add_child(_file_field(row))
			TreeRow.FieldMode.COLOR:
				add_child(_color_field(row))

	if get_child_count() > 0:
		var update_anchor = func():
			var last_y_position: float = 0
			for child in get_children():
				if not child.is_queued_for_deletion():
					child.position.y = last_y_position
					last_y_position += child.custom_minimum_size.y + list_margin
		update_anchor.call_deferred()


func _ready():
	build()


func _clean_up():
	for child in get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()


func _step_field(tree_row : TreeRow) -> Control:
	var wrapper : Control = Control.new()
	var label : Label = Label.new()
	var spinner : SpinBox = SpinBox.new()
	var spinner_wrapper : Panel = Panel.new()
	spinner_wrapper.theme_type_variation = "PanelEdit"
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1

	label.text = tree_row.label
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = column_ratio
	label.anchor_bottom = 1
	label.offset_right = -list_margin
	label.horizontal_alignment = _aligment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrapper.add_child(label)
	
	spinner.get_line_edit().theme_type_variation = "LineEditClean"
	match tree_row.field:
		TreeRow.FieldMode.INT:
			spinner.min_value = tree_row.int_min
			spinner.max_value = tree_row.int_max
			spinner.step = tree_row.int_step
			spinner.value = tree_row.int_value
			spinner.value_changed.connect(func(new_value : float):
					tree_row.int_value = new_value as int
					_on_value_changed(tree_row, tree_row.int_value)
			)
		TreeRow.FieldMode.FLOAT:
			spinner.min_value = tree_row.float_min
			spinner.max_value = tree_row.float_max
			spinner.step = tree_row.float_step
			spinner.value = tree_row.float_value
			spinner.value_changed.connect(func(new_value : float):
					tree_row.float_value = new_value
					_on_value_changed(tree_row, tree_row.float_value)
			)
	spinner.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner.set_anchors_preset(Control.PRESET_FULL_RECT)
	spinner_wrapper.add_child(spinner)
	
	spinner_wrapper.anchor_left = column_ratio
	spinner_wrapper.anchor_top = 0
	spinner_wrapper.anchor_right = 1.0
	spinner_wrapper.anchor_bottom = 1
	
	wrapper.add_child(spinner_wrapper)
	wrapper.custom_minimum_size.y = 30
	
	spinner.get_line_edit().text_submitted.connect(func(_v):
			spinner.get_line_edit().release_focus()
			)
	return wrapper


func _range_field(tree_row : TreeRow) -> Control:
	var wrapper : Control = Control.new()
	var label : Label = Label.new()
	var label_value : Label = Label.new()
	var panel : Panel = Panel.new()
	var slider : HSlider = HSlider.new()
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1

	label.text = tree_row.label
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = column_ratio
	label.anchor_bottom = 1
	label.offset_right = -list_margin
	label.horizontal_alignment = _aligment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrapper.add_child(label)
	
	panel.anchor_left = column_ratio
	panel.anchor_top = 0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1
	wrapper.add_child(panel)
	
	label_value.text = str(tree_row.range_value)
	label_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_value.anchor_left = column_ratio
	label_value.anchor_top = 0
	label_value.anchor_right = 1.0
	label_value.anchor_bottom = 1
	label_value.offset_right = -16
	wrapper.add_child(label_value)
	
	slider.min_value = tree_row.range_min
	slider.max_value = tree_row.range_max
	slider.step = tree_row.range_step
	slider.value = tree_row.range_value
	slider.anchor_left = column_ratio + 0.01
	slider.anchor_top = 0.65
	slider.anchor_right = 0.99
	slider.anchor_bottom = 0.65
	wrapper.add_child(slider)
	wrapper.custom_minimum_size.y = 30
	
	slider.value_changed.connect(func(new_value : float):
			tree_row.range_value = new_value
			label_value.text = str(new_value)
			_on_value_changed(tree_row, tree_row.range_value)
			)
	
	return wrapper


func _string_field(tree_row : TreeRow) -> Control:
	var wrapper : Control = Control.new()
	var label : Label = Label.new()
	var line_edit : LineEdit = LineEdit.new()
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1

	label.text = tree_row.label
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = column_ratio
	label.anchor_bottom = 1
	label.offset_right = -list_margin
	label.horizontal_alignment = _aligment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrapper.add_child(label)
	
	line_edit.text = tree_row.string_value
	line_edit.anchor_left = column_ratio
	line_edit.anchor_top = 0
	line_edit.anchor_right = 1.0
	line_edit.anchor_bottom = 1
	wrapper.add_child(line_edit)
	wrapper.custom_minimum_size.y = 30
	
	line_edit.text_changed.connect(func(new_value : String):
			tree_row.string_value = new_value
			_on_value_changed(tree_row, tree_row.string_value)
			)
	line_edit.text_submitted.connect(func(_v):
			line_edit.release_focus()
			)
	
	return wrapper


func _vector2_field(tree_row : TreeRow) -> Control:
	var wrapper : Control = Control.new()
	var label_a : Label = Label.new()
	var label_b : Label = Label.new()
	var spinner_x : SpinBox = SpinBox.new()
	var spinner_y : SpinBox = SpinBox.new()
	
	var spinner_wrapper_x : Panel = Panel.new()
	spinner_wrapper_x.theme_type_variation = "PanelEdit"
	spinner_x.get_line_edit().theme_type_variation = "LineEditClean"
	
	var spinner_wrapper_y : Panel = Panel.new()
	spinner_wrapper_y.theme_type_variation = "PanelEdit"
	spinner_y.get_line_edit().theme_type_variation = "LineEditClean"
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1
	
	if main_label_aligment == HORIZONTAL_ALIGNMENT_LEFT:
		var label_main : Label = Label.new()
		label_main.text = tree_row.label
		label_main.anchor_left = 0
		label_main.anchor_top = 0
		label_main.anchor_right = column_ratio
		label_main.anchor_bottom = 0.5
		label_main.offset_right = -list_margin
		label_main.horizontal_alignment = _aligment
		label_main.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label_main.offset_bottom = -1
		wrapper.add_child(label_main)

	label_a.text = tree_row.vector2_label_x
	if main_label_aligment == HORIZONTAL_ALIGNMENT_RIGHT:
		label_a.text = tree_row.label + " " + label_a.text
	label_a.anchor_left = 0
	label_a.anchor_top = 0
	label_a.anchor_right = column_ratio
	label_a.anchor_bottom = 0.5
	label_a.offset_right = -list_margin
	label_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_a.offset_bottom = -1
	wrapper.add_child(label_a)
	
	label_b.text = tree_row.vector2_label_y
	label_b.anchor_left = 0
	label_b.anchor_top = 0.5
	label_b.anchor_right = column_ratio
	label_b.anchor_bottom = 1.0
	label_b.offset_right = -list_margin
	label_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_b.offset_top = 1
	wrapper.add_child(label_b)
	
	spinner_x.min_value = tree_row.vector2_min.x
	spinner_x.max_value = tree_row.vector2_max.x
	spinner_x.step = tree_row.vector2_step.x
	spinner_x.value = tree_row.vector2_value.x
	spinner_x.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner_x.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	spinner_wrapper_x.anchor_left = column_ratio
	spinner_wrapper_x.anchor_top = 0
	spinner_wrapper_x.anchor_right = 1.0
	spinner_wrapper_x.anchor_bottom = 0.5
	spinner_wrapper_x.offset_bottom = -1
	
	spinner_wrapper_x.add_child(spinner_x)
	wrapper.add_child(spinner_wrapper_x)
	
	spinner_y.min_value = tree_row.vector2_min.y
	spinner_y.max_value = tree_row.vector2_max.y
	spinner_y.step = tree_row.vector2_step.y
	spinner_y.value = tree_row.vector2_value.y
	spinner_y.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner_y.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	spinner_wrapper_y.anchor_left = column_ratio
	spinner_wrapper_y.anchor_top = 0.5
	spinner_wrapper_y.anchor_right = 1.0
	spinner_wrapper_y.anchor_bottom = 1
	spinner_wrapper_y.offset_top = 1
	
	spinner_wrapper_y.add_child(spinner_y)
	wrapper.add_child(spinner_wrapper_y)
	
	wrapper.custom_minimum_size.y = 60 + 2
	
	spinner_x.value_changed.connect(func(new_value : float):
			tree_row.vector2_value.x = new_value
			_on_value_changed(tree_row, tree_row.vector2_value)
			)
	spinner_y.value_changed.connect(func(new_value : float):
			tree_row.vector2_value.y = new_value
			_on_value_changed(tree_row, tree_row.vector2_value)
			)
	
	spinner_x.get_line_edit().text_submitted.connect(func(_v):
			spinner_x.get_line_edit().release_focus()
			)
	spinner_y.get_line_edit().text_submitted.connect(func(_v):
			spinner_y.get_line_edit().release_focus()
			)
	
	return wrapper


func _vector2i_field(tree_row : TreeRow) -> Control:
	var wrapper : Control = Control.new()
	var label_a : Label = Label.new()
	var label_b : Label = Label.new()
	var spinner_x : SpinBox = SpinBox.new()
	var spinner_y : SpinBox = SpinBox.new()
	
	var spinner_wrapper_x : Panel = Panel.new()
	spinner_wrapper_x.theme_type_variation = "PanelEdit"
	spinner_x.get_line_edit().theme_type_variation = "LineEditClean"
	
	var spinner_wrapper_y : Panel = Panel.new()
	spinner_wrapper_y.theme_type_variation = "PanelEdit"
	spinner_y.get_line_edit().theme_type_variation = "LineEditClean"
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1
	
	if main_label_aligment == HORIZONTAL_ALIGNMENT_LEFT:
		var label_main : Label = Label.new()
		label_main.text = tree_row.label
		label_main.anchor_left = 0
		label_main.anchor_top = 0
		label_main.anchor_right = column_ratio
		label_main.anchor_bottom = 0.5
		label_main.offset_right = -list_margin
		label_main.horizontal_alignment = _aligment
		label_main.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label_main.offset_bottom = -1
		wrapper.add_child(label_main)

	label_a.text = tree_row.vector2i_label_x
	if main_label_aligment == HORIZONTAL_ALIGNMENT_RIGHT:
		label_a.text = tree_row.label + " " + label_a.text
	label_a.anchor_left = 0
	label_a.anchor_top = 0
	label_a.anchor_right = column_ratio
	label_a.anchor_bottom = 0.5
	label_a.offset_right = -list_margin
	label_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_a.offset_bottom = -1
	wrapper.add_child(label_a)
	
	label_b.text = tree_row.vector2i_label_y
	label_b.anchor_left = 0
	label_b.anchor_top = 0.5
	label_b.anchor_right = column_ratio
	label_b.anchor_bottom = 1.0
	label_b.offset_right = -list_margin
	label_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_b.offset_top = 1
	wrapper.add_child(label_b)
	
	spinner_x.min_value = tree_row.vector2i_min.x
	spinner_x.max_value = tree_row.vector2i_max.x
	spinner_x.step = tree_row.vector2i_step.x
	spinner_x.value = tree_row.vector2i_value.x
	spinner_x.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner_x.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	spinner_wrapper_x.anchor_left = column_ratio
	spinner_wrapper_x.anchor_top = 0
	spinner_wrapper_x.anchor_right = 1.0
	spinner_wrapper_x.anchor_bottom = 0.5
	spinner_wrapper_x.offset_bottom = -1
	
	spinner_wrapper_x.add_child(spinner_x)
	wrapper.add_child(spinner_wrapper_x)
	
	spinner_y.min_value = tree_row.vector2i_min.y
	spinner_y.max_value = tree_row.vector2i_max.y
	spinner_y.step = tree_row.vector2i_step.y
	spinner_y.value = tree_row.vector2i_value.y
	spinner_y.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner_y.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	spinner_wrapper_y.anchor_left = column_ratio
	spinner_wrapper_y.anchor_top = 0.5
	spinner_wrapper_y.anchor_right = 1.0
	spinner_wrapper_y.anchor_bottom = 1
	spinner_wrapper_y.offset_top = 1
	
	spinner_wrapper_y.add_child(spinner_y)
	wrapper.add_child(spinner_wrapper_y)
	
	wrapper.custom_minimum_size.y = 60 + 2
	
	spinner_x.value_changed.connect(func(new_value : float):
			tree_row.vector2i_value.x = new_value as int
			_on_value_changed(tree_row, tree_row.vector2i_value)
			)
	spinner_y.value_changed.connect(func(new_value : float):
			tree_row.vector2i_value.y = new_value as int
			_on_value_changed(tree_row, tree_row.vector2i_value)
			)
	
	spinner_x.get_line_edit().text_submitted.connect(func(_v):
			spinner_x.get_line_edit().release_focus()
			)
	spinner_y.get_line_edit().text_submitted.connect(func(_v):
			spinner_y.get_line_edit().release_focus()
			)
	
	return wrapper


func _toggle_field(tree_row : TreeRow):
	var wrapper : Control = Control.new()
	var label : Label = Label.new()
	var toggle : ToggleButton = ToggleButton.new()
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1

	label.text = tree_row.label
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = column_ratio
	label.anchor_bottom = 1
	label.offset_right = -list_margin
	label.horizontal_alignment = _aligment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrapper.add_child(label)
	
	toggle.anchor_left = column_ratio
	toggle.anchor_top = 0
	toggle.anchor_right = 1
	toggle.anchor_bottom = 1
	
	if tree_row.enum_option.size() == 2:
		toggle.mode = ToggleButton.ToggleButtonMode.TWO
		toggle.value = tree_row.enum_value
		toggle.label_left = tree_row.enum_option[0]
		toggle.label_right = tree_row.enum_option[1]
	if tree_row.enum_option.size() == 3:
		toggle.mode = ToggleButton.ToggleButtonMode.THREE
		toggle.value = tree_row.enum_value
		toggle.label_left = tree_row.enum_option[0]
		toggle.label_mid = tree_row.enum_option[1]
		toggle.label_right = tree_row.enum_option[2]
	wrapper.add_child(toggle)
	
	toggle.value_changed.connect(func(new_value : int):
			tree_row.enum_value = new_value
			_on_value_changed(tree_row, tree_row.enum_value)
			)
	
	wrapper.custom_minimum_size.y = 30
	return wrapper


func _enum_field(tree_row : TreeRow):
	var wrapper : Control = Control.new()
	var label : Label = Label.new()
	var option : OptionButton = OptionButton.new()
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1

	label.text = tree_row.label
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = column_ratio
	label.anchor_bottom = 1
	label.offset_right = -list_margin
	label.horizontal_alignment = _aligment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrapper.add_child(label)
	
	if tree_row.enum_option.size() > tree_row.enum_value:
		option.selected = tree_row.enum_value
	for i in range(tree_row.enum_option.size()):
		option.add_item(tree_row.enum_option[i], i)
	option.alignment = HORIZONTAL_ALIGNMENT_CENTER
	option.anchor_left = column_ratio
	option.anchor_top = 0
	option.anchor_right = 1
	option.anchor_bottom = 1
	wrapper.add_child(option)
	
	wrapper.custom_minimum_size.y = 30
	
	option.item_selected.connect(func(index : int):
			tree_row.enum_value = index
			_on_value_changed(tree_row, tree_row.enum_value)
			option.release_focus()
			)
	
	return wrapper


func _file_field(tree_row : TreeRow):
	var wrapper : Control = Control.new()
	var label : Label = Label.new()
	var line_edit : LineEdit = LineEdit.new()
	var file_button : TextureButton = TextureButton.new()
	var hover = Node.new()
	var mat = ShaderMaterial.new()
	mat.shader = load("res://addons/net.yarvis.pixel_pen/resources/tint_color.gdshader")
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1

	label.text = tree_row.label
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = column_ratio
	label.anchor_bottom = 1
	label.offset_right = -list_margin
	label.horizontal_alignment = _aligment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrapper.add_child(label)
	
	line_edit.text = tree_row.file_value
	line_edit.anchor_left = column_ratio
	line_edit.anchor_top = 0
	line_edit.anchor_right = 1.0
	line_edit.anchor_bottom = 1
	line_edit.offset_right = -30
	wrapper.add_child(line_edit)
	
	file_button.material = mat
	file_button.tooltip_text = "Select file"
	file_button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
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
					_on_value_changed(tree_row, tree_row.file_value),
			tree_row.file_dialog_filters,
			tree_row.file_mode
			))
	line_edit.text_changed.connect(func(text : String):
			tree_row.file_value = text
			_on_value_changed(tree_row, tree_row.file_value)
			)
	line_edit.text_submitted.connect(func(_v):
			line_edit.release_focus()
			)
	
	wrapper.add_child(file_button)

	hover.set_script(load("res://addons/net.yarvis.pixel_pen/editor/editor_main_ui/button_hover.gd"))
	hover.can_active = false
	mat.set_shader_parameter("tint", hover.default_color)
	file_button.add_child(hover)
	
	wrapper.custom_minimum_size.y = 30
	return wrapper


func _color_field(tree_row : TreeRow):
	var wrapper : Control = Control.new()
	var label : Label = Label.new()
	var color_picker_btn : ColorPickerButton = ColorPickerButton.new()
	
	wrapper.anchor_left = 0
	wrapper.anchor_right = 1

	label.text = tree_row.label
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = column_ratio
	label.anchor_bottom = 1
	label.offset_right = -list_margin
	label.horizontal_alignment = _aligment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrapper.add_child(label)
	
	color_picker_btn.edit_alpha = tree_row.color_alpha
	color_picker_btn.color = tree_row.color_value
	color_picker_btn.anchor_left = column_ratio
	color_picker_btn.anchor_top = 0
	color_picker_btn.anchor_right = 1.0
	color_picker_btn.anchor_bottom = 1
	wrapper.add_child(color_picker_btn)
	wrapper.custom_minimum_size.y = 30
	
	color_picker_btn.popup_closed.connect(func():
			tree_row.color_value = color_picker_btn.color
			_on_value_changed(tree_row, tree_row.color_value)
			color_picker_btn.release_focus()
			)
	
	return wrapper


func _select_file(callback : Callable, filter : PackedStringArray, mode : FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE):
	var _file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = true
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
	_file_dialog.popup_centered(Vector2i(540, 540))
	_file_dialog.grab_focus()


func _on_value_changed(tree_row : TreeRow, value):
	for i in range(structure.size()):
		if structure[i] == tree_row:
			value_changed.emit(i, value)

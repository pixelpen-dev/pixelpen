@tool
extends Panel


var shader_tint = load("res://addons/net.yarvis.pixel_pen/resources/tint_color.gdshader")

var skip_to_front := load("res://addons/net.yarvis.pixel_pen/resources/icon/skip-backward.svg")
var step_backward := load("res://addons/net.yarvis.pixel_pen/resources/icon/step-backward.svg")
var play := load("res://addons/net.yarvis.pixel_pen/resources/icon/play.svg")
var pause := load("res://addons/net.yarvis.pixel_pen/resources/icon/pause.svg")
var step_forward := load("res://addons/net.yarvis.pixel_pen/resources/icon/step-forward.svg")
var skip_to_end := load("res://addons/net.yarvis.pixel_pen/resources/icon/skip-forward.svg")

var frame_preview := load("res://addons/net.yarvis.pixel_pen/editor/frame_preview.tscn")

@export var animation_menu_list : HBoxContainer
@export var animation_wrapper_frame_list : VBoxContainer
@export var animation_frame_list : HBoxContainer
@export var animation_unused_frame_list : HBoxContainer
@export var playback_timer : Timer
@export var frame_y_size : Control
@export var animation_fps : SpinBox
@export var actual_fps : Label

var _record_prev_time : float
var _record_fps : Array[float] = []


func _ready():
	animation_fps.get_line_edit().theme_type_variation = "LineEditClean"
	if not PixelPen.state.need_connection(get_window()):
		return
	
	PixelPen.state.tool_changed.connect(_on_tool_changed)
	PixelPen.state.project_file_changed.connect(func():
			if PixelPen.state.current_project != null:
				animation_fps.value = PixelPen.state.current_project.animation_fps
			create_frame_list()
			)
	PixelPen.state.layer_items_changed.connect(create_frame_list)
	playback_timer.timeout.connect(_on_timer_timeout)
	animation_fps.value_changed.connect(func(value):
			if PixelPen.state.current_project != null:
				PixelPen.state.current_project.animation_fps = value
			)
	create_animation_menu()


func _exit_tree():
	_clean_up()
	actual_fps.label_settings.font_color = Color.WHITE


func _process(_delta):
	if PixelPen.state.current_project != null and PixelPen.state.current_project.animation_is_play:
		var children := animation_frame_list.get_children()
		for i in range(children.size()):
			var path = children[i].get_meta("label_path")
			if path != null:
				var label : Label = children[i].get_node(path) as Label
				var label_style : StyleBoxFlat= label.get_theme_stylebox("normal") as StyleBoxFlat
				if i == PixelPen.state.current_project.animation_frame_index:
					label_style.bg_color = PixelPen.state.userconfig.accent_color
					label.label_settings.font_color = Color.BLACK
				else:
					label_style.bg_color = PixelPen.state.userconfig.layer_body_color
					label.label_settings.font_color = Color.WHITE


func play_pause():
	PixelPen.state.current_project.animation_is_play = not PixelPen.state.current_project.animation_is_play
	if PixelPen.state.current_project.animation_is_play and playback_timer.is_stopped():
		PixelPen.state.animation_about_to_play.emit()
		if PixelPen.state.current_project.animation_frame_index == -1:
			PixelPen.state.current_project.animation_frame_index = 0
		_refresh_frame()
		var frame_time = 1.0 / PixelPen.state.current_project.animation_fps
		_record_prev_time = Time.get_unix_time_from_system()
		_record_fps.clear()
		playback_timer.start(frame_time)
	elif not PixelPen.state.current_project.animation_is_play:
		playback_timer.stop()
		actual_fps.text = ""
		PixelPen.state.layer_items_changed.emit()
		PixelPen.state.project_saved.emit(false)


func _on_timer_timeout():
	if PixelPen.state.current_project == null:
		playback_timer.stop()
		return
	# calculate actual fps
	_record_fps.push_front(1.0 / (Time.get_unix_time_from_system() - _record_prev_time))
	if _record_fps.size() > 10:
		_record_fps.resize(10)
	var fps : float = 0
	for f in _record_fps:
		fps += f
	fps /= (_record_fps.size() as float)
	fps = roundf(fps)# * 100) / 100.0
	actual_fps.text = str("~", fps, " fps")
	if abs(PixelPen.state.current_project.animation_fps - fps) < 3:
		actual_fps.text = ""
	elif abs(PixelPen.state.current_project.animation_fps - fps) < 5:
		actual_fps.label_settings.font_color = Color.GREEN
	else:
		actual_fps.label_settings.font_color = Color.RED
	_record_prev_time = Time.get_unix_time_from_system()
	
	PixelPen.state.current_project.animation_frame_index += 1
	if PixelPen.state.current_project.animation_timeline.size() == PixelPen.state.current_project.animation_frame_index:
		PixelPen.state.current_project.animation_frame_index = 0
		if not PixelPen.state.current_project.animation_loop:
			play_pause()
			return
	_refresh_frame()


func _refresh_frame():
	var cell = PixelPen.state.current_project.animation_timeline[PixelPen.state.current_project.animation_frame_index]
	var pool_index = PixelPen.state.current_project.get_pool_index(cell.frame.frame_uid)
	PixelPen.state.current_project.canvas_pool_frame_uid = PixelPen.state.current_project.pool_frames[pool_index].frame_uid
	PixelPen.state.layer_items_changed.emit()


func _on_tool_changed(grup : int, type: int, _grab_active : bool):
	if PixelPen.state.current_project == null:
		return
	if grup == PixelPenEnum.ToolBoxGrup.TOOL_GRUP_ANIMATION:
		match type:
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_PLAY_PAUSE:
				if PixelPen.state.current_project.animation_timeline.size() > 0:
					play_pause()
				
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_SKIP_TO_FRONT:
				if PixelPen.state.current_project.animation_frame_index != -1:
					PixelPen.state.current_project.animation_frame_index = 0
					var cell = PixelPen.state.current_project.animation_timeline[PixelPen.state.current_project.animation_frame_index]
					var pool_index = PixelPen.state.current_project.get_pool_index(cell.frame.frame_uid)
					PixelPen.state.current_project.canvas_pool_frame_uid = PixelPen.state.current_project.pool_frames[pool_index].frame_uid
					PixelPen.state.layer_items_changed.emit()
					PixelPen.state.project_saved.emit(false)
				
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_STEP_BACKWARD:
				if PixelPen.state.current_project.animation_frame_index != -1:
					PixelPen.state.current_project.animation_frame_index -= 1
					if PixelPen.state.current_project.animation_frame_index < 0:
						PixelPen.state.current_project.animation_frame_index = PixelPen.state.current_project.animation_timeline.size() -1
					var cell = PixelPen.state.current_project.animation_timeline[PixelPen.state.current_project.animation_frame_index]
					var pool_index = PixelPen.state.current_project.get_pool_index(cell.frame.frame_uid)
					PixelPen.state.current_project.canvas_pool_frame_uid = PixelPen.state.current_project.pool_frames[pool_index].frame_uid
					PixelPen.state.layer_items_changed.emit()
					PixelPen.state.project_saved.emit(false)
				
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_STEP_FORWARD:
				if PixelPen.state.current_project.animation_frame_index != -1:
					PixelPen.state.current_project.animation_frame_index += 1
					if PixelPen.state.current_project.animation_frame_index >= PixelPen.state.current_project.animation_timeline.size():
						PixelPen.state.current_project.animation_frame_index = 0
					var cell = PixelPen.state.current_project.animation_timeline[PixelPen.state.current_project.animation_frame_index]
					var pool_index = PixelPen.state.current_project.get_pool_index(cell.frame.frame_uid)
					PixelPen.state.current_project.canvas_pool_frame_uid = PixelPen.state.current_project.pool_frames[pool_index].frame_uid
					PixelPen.state.layer_items_changed.emit()
					PixelPen.state.project_saved.emit(false)
				
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_SKIP_TO_END:
				if PixelPen.state.current_project.animation_frame_index != -1:
					PixelPen.state.current_project.animation_frame_index = PixelPen.state.current_project.animation_timeline.size() -1
					var cell = PixelPen.state.current_project.animation_timeline[PixelPen.state.current_project.animation_frame_index]
					var pool_index = PixelPen.state.current_project.get_pool_index(cell.frame.frame_uid)
					PixelPen.state.current_project.canvas_pool_frame_uid = PixelPen.state.current_project.pool_frames[pool_index].frame_uid
					PixelPen.state.layer_items_changed.emit()
					PixelPen.state.project_saved.emit(false)


func create_animation_menu():
	_clean_up()
	_build_button("Skip to front",
			skip_to_front,
			PixelPenEnum.ToolBoxGrup.TOOL_GRUP_ANIMATION,
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_SKIP_TO_FRONT,
			false)
	_build_button("Step backward",
			step_backward,
			PixelPenEnum.ToolBoxGrup.TOOL_GRUP_ANIMATION,
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_STEP_BACKWARD,
			false)
	_build_toggle_button(
			"Play",
			"Pause",
			play,
			pause,
			PixelPenEnum.ToolBoxGrup.TOOL_GRUP_ANIMATION,
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_PLAY_PAUSE,
			false,
			false,
			null,
			func():
				if PixelPen.state.current_project == null:
					return false
				return PixelPen.state.current_project.animation_is_play)
	_build_button("Step forward",
			step_forward,
			PixelPenEnum.ToolBoxGrup.TOOL_GRUP_ANIMATION,
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_STEP_FORWARD,
			false)
	_build_button("Skip to end",
			skip_to_end,
			PixelPenEnum.ToolBoxGrup.TOOL_GRUP_ANIMATION,
			PixelPenEnum.ToolAnimation.TOOL_ANIMATION_SKIP_TO_END,
			false)


func create_frame_list():
	if PixelPen.state.current_project != null and PixelPen.state.current_project.animation_is_play:
		return
	var children := animation_frame_list.get_children()
	for child in children:
		if not child.is_queued_for_deletion():
			child.queue_free()
	
	var children_unused := animation_unused_frame_list.get_children()
	for child in children_unused:
		if not child.is_queued_for_deletion():
			child.queue_free()
	
	if PixelPen.state.current_project == null or PixelPen.state.current_project.use_sample:
		return
	var margin : int = 8
	var box_size : Vector2 = Vector2(margin, frame_y_size.size.y - margin * 4)
	var create_cell = func(pool_index : int, frame_index : int , is_active : bool, left_margin : bool = false):
			var linked_l := _is_linked(frame_index - 1, frame_index)
			var linked_r := _is_linked(frame_index, frame_index + 1)
		
			var margin_container := MarginContainer.new()
			margin_container.focus_mode = Control.FOCUS_CLICK
			margin_container.mouse_filter = Control.MOUSE_FILTER_STOP
			margin_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			margin_container.gui_input.connect(func(event):
					if event is InputEventMouseButton:
						if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
							margin_container.grab_focus()
							PixelPen.state.current_project.animation_frame_index = frame_index
							PixelPen.state.current_project.canvas_pool_frame_uid = PixelPen.state.current_project.pool_frames[pool_index].frame_uid
							PixelPen.state.layer_items_changed.emit()
							PixelPen.state.project_saved.emit(false)
							margin_container.release_focus()
					)
			
			if left_margin:
				margin_container.add_theme_constant_override("margin_left", 0 if linked_l else  margin)
				
			margin_container.add_theme_constant_override("margin_right", 0 if linked_r else margin)
			margin_container.add_theme_constant_override("margin_top", margin)
			margin_container.add_theme_constant_override("margin_bottom", margin)
					
			var place_holder := Panel.new()
			place_holder.mouse_filter = Control.MOUSE_FILTER_PASS
			place_holder.custom_minimum_size = Vector2(box_size.y, box_size.y - 2 * margin)
			
			var style := StyleBoxFlat.new()
			style.bg_color = PixelPen.state.userconfig.canvas_base_mode_color
			
			var cell_frame_uid : Vector3i = PixelPen.state.current_project.animation_timeline[frame_index].frame.frame_uid
			var frame_active : bool = PixelPen.state.current_project.active_frame.frame_uid == cell_frame_uid
			if frame_active:
				style.border_color = PixelPen.state.userconfig.accent_color
			else:
				style.border_color = PixelPen.state.current_project.animation_timeline[frame_index].frame.frame_color
			var border_margin = 2 if frame_active else 1
			style.expand_margin_left = 0 if linked_l else border_margin
			style.border_width_left = 0 if linked_l else  border_margin
			
			style.expand_margin_top = border_margin
			style.border_width_top = border_margin
			
			style.expand_margin_right = 0 if linked_r else  border_margin
			style.border_width_right = 0 if linked_r else  border_margin
			
			style.expand_margin_bottom = border_margin
			style.border_width_bottom = border_margin
			
			place_holder.add_theme_stylebox_override("panel", style)
			
			margin_container.add_child(place_holder)
			
			var preview = frame_preview.instantiate()
			preview.stretch_shrink = 2
			if not linked_l:
				preview.show_frame(PixelPen.state.current_project.pool_frames[pool_index])
			preview.front_control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND 
			
			var asr := AspectRatioContainer.new()
			asr.custom_minimum_size = Vector2(24, 24)
			asr.alignment_horizontal = AspectRatioContainer.ALIGNMENT_BEGIN
			asr.alignment_vertical = AspectRatioContainer.ALIGNMENT_BEGIN
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.text = str(frame_index + 1)
			
			var label_style := StyleBoxFlat.new()
			var lable_setting := LabelSettings.new()
			lable_setting.font_size = 12
			if is_active:
				label_style.bg_color = PixelPen.state.userconfig.accent_color
				lable_setting.font_color = Color.BLACK
			else:
				label_style.bg_color = PixelPen.state.userconfig.layer_body_color
				lable_setting.font_color = Color.WHITE
			label_style.corner_radius_bottom_right = 8
			label.add_theme_stylebox_override("normal", label_style)
			label.label_settings = lable_setting
			asr.add_child(label)
			preview.front_control.add_child(asr)
			
			place_holder.add_child(preview)
			
			animation_frame_list.add_child(margin_container)

			margin_container.set_meta("label_path", margin_container.get_path_to(label))
			
			box_size.x += place_holder.custom_minimum_size.x + margin
	
	var used_frame : Array[int] = []
	var first := true
	for cell_i in range(PixelPen.state.current_project.animation_timeline.size()):
		var cell = PixelPen.state.current_project.animation_timeline[cell_i]
		var pool_index = PixelPen.state.current_project.get_pool_index(cell.frame.frame_uid)
		used_frame.push_back(pool_index)
		create_cell.call(pool_index, cell_i, PixelPen.state.current_project.animation_frame_index == cell_i, first)
		first = false
	
	await get_tree().process_frame
	var count : int = animation_frame_list.get_child_count()
	if count == 0:
		box_size.y = 0
	animation_frame_list.custom_minimum_size = box_size
	
	box_size = Vector2(margin, frame_y_size.size.y - margin * 4)
	var create_unused_cell = func(pool_index : int, cell_index : int , left_margin : bool = false):
			var margin_container := MarginContainer.new()
			margin_container.focus_mode = Control.FOCUS_CLICK
			margin_container.mouse_filter = Control.MOUSE_FILTER_STOP
			margin_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			margin_container.gui_input.connect(func(event):
					if event is InputEventMouseButton:
						if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
							margin_container.grab_focus()
							PixelPen.state.current_project.canvas_pool_frame_uid = PixelPen.state.current_project.pool_frames[pool_index].frame_uid
							PixelPen.state.current_project.animation_frame_index = -1
							PixelPen.state.layer_items_changed.emit()
							PixelPen.state.project_saved.emit(false)
							margin_container.release_focus()
					)
			
			if left_margin:
				margin_container.add_theme_constant_override("margin_left", margin)
				
			margin_container.add_theme_constant_override("margin_right", margin)
			margin_container.add_theme_constant_override("margin_top", margin)
			margin_container.add_theme_constant_override("margin_bottom", margin)
			
			var place_holder := Panel.new()
			place_holder.mouse_filter = Control.MOUSE_FILTER_PASS
			place_holder.custom_minimum_size = Vector2(box_size.y, box_size.y - 2 * margin)
			
			var style := StyleBoxFlat.new()
			style.bg_color = PixelPen.state.userconfig.canvas_base_mode_color
			var is_active : bool = PixelPen.state.current_project.active_frame == PixelPen.state.current_project.pool_frames[pool_index]
			var border_margin = 2 if is_active else 1
			style.border_color = PixelPen.state.userconfig.accent_color if is_active else PixelPen.state.current_project.pool_frames[pool_index].frame_color
			style.expand_margin_left = border_margin
			style.expand_margin_top = border_margin
			style.expand_margin_right = border_margin
			style.expand_margin_bottom = border_margin
			style.border_width_left = border_margin
			style.border_width_top = border_margin
			style.border_width_right = border_margin
			style.border_width_bottom = border_margin
			place_holder.add_theme_stylebox_override("panel", style)
			
			margin_container.add_child(place_holder)
			
			var preview = frame_preview.instantiate()
			preview.stretch_shrink = 2
			preview.show_frame(PixelPen.state.current_project.pool_frames[pool_index])
			preview.front_control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND 
			place_holder.add_child(preview)
			
			animation_unused_frame_list.add_child(margin_container)
			
			box_size.x += place_holder.custom_minimum_size.x + margin
	
	first = true
	var cell_i : int = 0
	for pool_i in range(PixelPen.state.current_project.pool_frames.size()):
		if used_frame.has(pool_i):
			continue
		create_unused_cell.call(pool_i, cell_i, first)
		first = false
	
	await get_tree().process_frame
	count = animation_unused_frame_list.get_child_count()
	if count == 0:
		box_size.y = 0
	
	animation_unused_frame_list.custom_minimum_size = box_size
	animation_wrapper_frame_list.custom_minimum_size.x = max(animation_unused_frame_list.custom_minimum_size.x, animation_frame_list.custom_minimum_size.x)
	animation_wrapper_frame_list.custom_minimum_size.y = animation_unused_frame_list.custom_minimum_size.y + animation_frame_list.custom_minimum_size.y


func _build_button(name : String,
		texture : Texture2D,
		grup : int,
		type: int,
		can_active : bool,
		default_active : bool = false,
		shorcut : Shortcut = null,
		visible_callback : Callable = Callable()):
	var btn = TextureButton.new()
	btn.name = name
	btn.texture_normal = texture
	btn.custom_minimum_size.x = animation_menu_list.size.y
	btn.pressed.connect(func ():
			PixelPen.state.tool_changed.emit(grup, type, can_active)
			)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	btn.shortcut = shorcut
	
	var mat = ShaderMaterial.new()
	mat.shader = shader_tint
	btn.material = mat
	
	var hover = Node.new()
	hover.set_script(load("res://addons/net.yarvis.pixel_pen/editor/editor_main_ui/button_hover.gd"))
	hover.tool_grup = grup
	hover.tool_type = type
	hover.can_active = can_active
	hover.visible_callback = visible_callback
	btn.add_child(hover)
	
	animation_menu_list.add_child(btn)
	btn.owner = animation_menu_list.owner
	hover.is_active = default_active


func _build_toggle_button(
		normal_tooltip : String,
		pressed_tooltip : String,
		texture_normal : Texture2D,
		texture_pressed : Texture2D,
		grup : int,
		type: int,
		can_active : bool,
		default_active : bool = false,
		shorcut : Shortcut = null,
		toggle_callback : Callable = Callable()):
	var btn = TextureButton.new()
	btn.name = normal_tooltip
	btn.toggle_mode = true
	btn.texture_normal = texture_normal
	btn.texture_pressed = texture_pressed
	btn.button_pressed = toggle_callback.call()
	btn.custom_minimum_size.x = animation_menu_list.size.y
	btn.pressed.connect(func ():
			PixelPen.state.tool_changed.emit(grup, type, can_active)
			)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	btn.shortcut = shorcut
	
	var mat = ShaderMaterial.new()
	mat.shader = shader_tint
	btn.material = mat
	
	var hover = Node.new()
	hover.set_script(load("res://addons/net.yarvis.pixel_pen/editor/editor_main_ui/button_hover.gd"))
	hover.tool_grup = grup
	hover.tool_type = type
	hover.can_active = can_active
	hover.visible_callback = func():
			btn.button_pressed = toggle_callback.call()
			btn.tooltip_text = pressed_tooltip if toggle_callback.call() else normal_tooltip
			return true
			
	btn.add_child(hover)
	
	animation_menu_list.add_child(btn)
	btn.owner = animation_menu_list.owner
	hover.is_active = default_active


func _is_linked(index_a : int, index_b : int) -> bool:
	assert(index_a != index_b and index_a < index_b, "ERR, _is_linked")
	if index_a < 0 or index_b == PixelPen.state.current_project.animation_timeline.size():
		return false
	
	if PixelPen.state.current_project.animation_timeline[index_a].frame.frame_uid == PixelPen.state.current_project.animation_timeline[index_b].frame.frame_uid:
		return true
	
	return false


func _clean_up():
	for child in animation_menu_list.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()


func _on_animation_frame_resized():
	create_frame_list()

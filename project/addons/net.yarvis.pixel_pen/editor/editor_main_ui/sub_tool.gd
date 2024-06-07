@tool
extends Control


const shorcut : EditorShorcut = preload("../../resources/editor_shorcut.tres")

const SelectTool = preload("../editor_canvas/select_tool.gd")
const MoveTool = preload("../editor_canvas/move_tool.gd")
const PenTool = preload("../editor_canvas/pen_tool.gd")
const BrushTool = preload("../editor_canvas/brush_tool.gd")
const StampTool = preload("../editor_canvas/stamp_tool.gd")
const MagnetTool = preload("../editor_canvas/magnet_tool.gd")
const LineTool = preload("../editor_canvas/line_tool.gd")
const EllipseTool = preload("../editor_canvas/ellipse_tool.gd")
const RectangleTool = preload("../editor_canvas/rectangle_tool.gd")
const SelectionTool = preload("../editor_canvas/selection_tool.gd")
const FillTool = preload("../editor_canvas/fill_tool.gd")

const undo = preload("../../resources/icon/undo.svg")
const redo = preload("../../resources/icon/redo.svg")
const fit_screen = preload("../../resources/icon/fit-to-screen-outline.svg")
const save = preload("../../resources/icon/content-save.svg")
const grid = preload("../../resources/icon/grid_3x3_24.svg")
const tint_black = preload("../../resources/icon/image-filter-black-white.svg")
const save_alert = preload("../../resources/icon/content-save-alert-outline.svg")

const cut = preload("../../resources/icon/content-cut.svg")
const copy = preload("../../resources/icon/content-copy.svg")
const cancel = preload("../../resources/icon/cancel.svg")
const commit = preload("../../resources/icon/check-circle-outline.svg")
const rotate_left = preload("../../resources/icon/rotate-left.svg")
const rotate_right = preload("../../resources/icon/rotate-right.svg")
const flip_horizontal = preload("../../resources/icon/flip-horizontal.svg")
const flip_vertical = preload("../../resources/icon/flip-vertical.svg")
const scale_left = preload("../../resources/icon/arrow-expand-left.svg")
const scale_up = preload("../../resources/icon/arrow-expand-up.svg")
const scale_right = preload("../../resources/icon/arrow-expand-right.svg")
const scale_down = preload("../../resources/icon/arrow-expand-down.svg")

const select_color = preload("../../resources/icon/select-color.svg")
const select_layer = preload("../../resources/icon/layers-search-outline.svg")

const selection_union = preload("../../resources/icon/vector-union.svg")
const selection_difference = preload("../../resources/icon/vector-difference-ba.svg")
const selection_intersection = preload("../../resources/icon/vector-intersection.svg")
const selection_inverse = preload("../../resources/icon/select-inverse.svg")
const selection_remove = preload("../../resources/icon/remove_selection_24.svg")
const delete_in_selection = preload("../../resources/icon/delete_in_selection.svg")

const zoom_in = preload("../../resources/icon/zoom_in_24.svg")
const zoom_out = preload("../../resources/icon/zoom_out_24.svg")

const shader_tint = preload("../../resources/tint_color.gdshader")

const preview_btn := preload("../image_option_btn.tscn")

@export var button_list : Control
@export var toolbar_list : Control
@export var shift_separator : VSeparator
@export var shift_label : Label
@export var canvas : Node2D

var current_toolbox : int


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	PixelPen.project_file_changed.connect(func ():
			if PixelPen.current_project == null:
				_clean_up()
			)
	PixelPen.toolbox_just_changed.connect(func(type):
			shift_label.visible = canvas.canvas_paint.tool.has_shift_mode
			shift_separator.visible = canvas.canvas_paint.tool.has_shift_mode
			current_toolbox = type
			_on_tool_changed(type)
			)
	PixelPen.toolbox_shift_mode.connect(func(active):
			shift_label.label_settings.font_color = PixelPen.userconfig.accent_color if active else PixelPen.userconfig.label_color
			)
	call_deferred("_build_toolbar")


func _process(_delta):
	if not PixelPen.need_connection(get_window()):
		return
	var enable : bool = canvas.get_viewport_rect().has_point(canvas.get_viewport().get_mouse_position())
	shift_label.modulate.a = 1.0 if enable else 0.5


func _exit_tree():
	_clean_up()


func _on_tool_changed(type :int):
	match type:
		PixelPen.ToolBox.TOOL_SELECT:
			_on_select_tool()
		PixelPen.ToolBox.TOOL_MOVE:
			_on_move_tool()
		PixelPen.ToolBox.TOOL_SELECTION:
			_on_selection_tool()
		PixelPen.ToolBox.TOOL_PEN:
			_on_pen_tool()
		PixelPen.ToolBox.TOOL_BRUSH:
			_on_brush_tool()
		PixelPen.ToolBox.TOOL_STAMP:
			_on_stamp_tool()
		PixelPen.ToolBox.TOOL_MAGNET:
			_on_magnet_tool()
		PixelPen.ToolBox.TOOL_LINE:
			_on_line_tool()
		PixelPen.ToolBox.TOOL_ELLIPSE:
			_on_ellipse_tool()
		PixelPen.ToolBox.TOOL_RECTANGLE:
			_on_rectangle_tool()
		PixelPen.ToolBox.TOOL_FILL:
			_on_fill_tool()
		PixelPen.ToolBox.TOOL_ZOOM:
			_on_zoom_tool()
		_:
			_clean_up()


func _build_toolbar():
	for child in toolbar_list.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	_add_separator(func():
			return PixelPen.current_project != null,
			toolbar_list,
			)
	_build_button("Undo", undo, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPen.ToolBar.TOOLBAR_UNDO, false, false, shorcut.undo,
			func ():
				if PixelPen.current_project == null:
					return false
				return true,
			func ():
				if PixelPen.current_project == null:
					return true
				return not PixelPen.current_project.undo_redo.has_undo(),
			toolbar_list,
			)
	_build_button("Redo", redo, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPen.ToolBar.TOOLBAR_REDO, false, false, shorcut.redo,
			func ():
				if PixelPen.current_project == null:
					return false
				return true,
			func ():
				if PixelPen.current_project == null:
					return true
				if not PixelPen.current_project.undo_redo.has_redo():
					return true
				return not PixelPen.current_project.undo_redo.is_commited,
			toolbar_list,
			)
	_build_button("Reset zoom", fit_screen, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPen.ToolBar.TOOLBAR_RESET_ZOOM, false, false, null,
			func ():
				if PixelPen.current_project == null:
					return false
				return true,
			func ():
				return PixelPen.current_project == null,
			toolbar_list,
			)
	_build_toggle_button("Grid", "Grid", grid, grid, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPen.ToolBar.TOOLBAR_SHOW_GRID, true, 
			false, shorcut.view_show_grid,
			func ():
				if PixelPen.current_project == null:
					return false
				return PixelPen.current_project.show_grid,
			func ():
				if PixelPen.current_project == null:
					return true
				return false,
			)
	_build_toggle_button("Tint black", "Tint black", tint_black, tint_black, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPen.ToolBar.TOOLBAR_TOGGLE_TINT_BLACK_LAYER, true,
			false, shorcut.toggle_tint_layer,
			func ():
				if PixelPen.current_project == null:
					return false
				return canvas.silhouette,
			func ():
				if PixelPen.current_project == null:
					return true
				return false,
			)
	_build_toggle_button("Save", "Save", save, save_alert, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPen.ToolBar.TOOLBAR_SAVE, false, false, shorcut.save,
			func ():
				if PixelPen.current_project == null:
					return true
				return not PixelPen.current_project.is_saved,
			func ():
				return PixelPen.current_project == null or PixelPen.current_project.is_saved,
			)


func _on_select_tool():
	_clean_up()
	_build_button("Find Layer", select_layer, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxSelect.TOOL_SELECT_LAYER, true, true)
	_build_button("Select Color", select_color, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxSelect.TOOL_SELECT_COLOR, true)
	_add_separator(func():
			return SelectTool.active_sub_tool_type == PixelPen.ToolBoxSelect.TOOL_SELECT_COLOR)
	_build_check_box(
			"Grow only in axis",
			func(toggle_on):
				var state = PixelPen.ToolBoxSelect.TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_YES if toggle_on else PixelPen.ToolBoxSelect.TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_NO
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
				SelectTool.selection_color_grow_only_axis,
			func():
				return SelectTool.active_sub_tool_type == PixelPen.ToolBoxSelect.TOOL_SELECT_COLOR)
	_add_separator()


func _on_move_tool():
	_clean_up()
	
	_build_button("Cut", cut, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_MOVE_CUT, false, false, shorcut.cut, func():
					return MoveTool.mode == MoveTool.Mode.UNKNOWN
					)
	_build_button("Copy", copy, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_MOVE_COPY, false, false, shorcut.copy, func():
					return MoveTool.mode == MoveTool.Mode.UNKNOWN
					)
	
	_build_button("Rotate Left", rotate_left, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_MOVE_ROTATE_LEFT, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.current_project.multilayer_selected.is_empty())
	_build_button("Rotate Right", rotate_right, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_MOVE_ROTATE_RIGHT, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.current_project.multilayer_selected.is_empty())
	_build_button("Flip Horizontal", flip_horizontal, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_MOVE_FLIP_HORIZONTAL, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.current_project.multilayer_selected.is_empty())
	_build_button("Flip Vertical", flip_vertical, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_MOVE_FLIP_VERTICAL, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.current_project.multilayer_selected.is_empty())
	
	_add_separator(func():
			return MoveTool.mode != MoveTool.Mode.UNKNOWN)
	
	_build_button("Scale Shifted Left", scale_left, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_SCALE_LEFT, false, false, shorcut.arrow_left,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.current_project.multilayer_selected.is_empty())
	_build_button("Scale Shifted Top", scale_up, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_SCALE_UP, false, false, shorcut.arrow_up,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.current_project.multilayer_selected.is_empty())
	_build_button("Scale Shifted Right", scale_right, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_SCALE_RIGHT, false, false, shorcut.arrow_right,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.current_project.multilayer_selected.is_empty())
	_build_button("Scale Shifted Down", scale_down, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_SCALE_DOWN, false, false, shorcut.arrow_down,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.current_project.multilayer_selected.is_empty())
	
	_add_separator(func():
			return MoveTool.mode != MoveTool.Mode.UNKNOWN)
	_build_button("Cancel Transform", cancel, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_MOVE_CANCEL, false, false, null,
			func():
				return MoveTool.mode != MoveTool.Mode.UNKNOWN)
	_build_button("Commit Transform", commit, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMove.TOOL_MOVE_COMMIT, false, false, shorcut.confirm,
			func():
				return MoveTool.transformed and  MoveTool.mode != MoveTool.Mode.UNKNOWN)
	_add_separator()


func _on_selection_tool():
	_clean_up()
	_build_button("Selection Union", selection_union, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION, true, SelectionTool.sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_UNION)
	_build_button("Selection Difference", selection_difference, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE, true, SelectionTool.sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE)
	_build_button("Selection Intersection", selection_intersection, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPen.ToolBoxSelection.TOOL_SELECTION_INTERSECTION, true, SelectionTool.sub_tool_selection_type == PixelPen.ToolBoxSelection.TOOL_SELECTION_INTERSECTION)
	_add_separator()
	_build_button("Inverse Selection", selection_inverse, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPen.ToolBoxSelection.TOOL_SELECTION_INVERSE, false, false, shorcut.tool_inverse_selection,
			func (): return true,
			func (): return canvas.selection_tool_hint.texture == null
			)
	_build_button("Remove Selection", selection_remove, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPen.ToolBoxSelection.TOOL_SELECTION_REMOVE, false, false, shorcut.tool_remove_selection,
			func (): return true,
			func (): return canvas.selection_tool_hint.texture == null
			)
	_build_button("Delete Selected Area", delete_in_selection, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPen.ToolBoxSelection.TOOL_SELECTION_DELETE_SELECTED, false, false, shorcut.tool_delete_selected,
			func (): return true,
			func (): return canvas.selection_tool_hint.texture == null
			)
	_add_separator(func():
			return SelectionTool.has_point_selection_polygon)
	_build_button("Cancel Polygon", cancel, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPen.ToolBoxSelection.TOOL_SELECTION_CANCEL_POLYGON, false, false, null,
			func():
				return SelectionTool.has_point_selection_polygon)
	_build_button("Close Polygon", commit, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPen.ToolBoxSelection.TOOL_SELECTION_CLOSE_POLYGON, false, false, shorcut.confirm,
			func():
				return SelectionTool.can_commit_selection_polygon)
	_add_separator()


func _on_pen_tool():
	_clean_up()
	_build_check_box(
			"Pixel perfect",
			func(toggle_on):
				var state = PixelPen.ToolBoxPen.TOOL_PEN_PIXEL_PERFECT_YES if toggle_on else PixelPen.ToolBoxPen.TOOL_PEN_PIXEL_PERFECT_NO
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
			PenTool.pixel_perfect)
	_add_separator()


func _on_brush_tool():
	_clean_up()
	_build_brush_preview("Brush pattern")
	_add_separator()


func _on_stamp_tool():
	_clean_up()
	_build_stamp_preview("Stamp pattern")
	_add_separator()


func _on_magnet_tool():
	_clean_up()
	_build_button("Cancel", cancel, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxMagnet.TOOL_MAGNET_CANCEL, false, false, null,
			func():
				return MagnetTool.mode == MagnetTool.Mode.MOVE_PIXEL)
	_add_separator(func():
				return MagnetTool.mode == MagnetTool.Mode.MOVE_PIXEL)


func _on_line_tool():
	_clean_up()
	_build_check_box(
			"Pixel perfect",
			func(toggle_on):
				var state = PixelPen.ToolBoxLine.TOOL_LINE_PIXEL_PERFECT_YES if toggle_on else PixelPen.ToolBoxLine.TOOL_LINE_PIXEL_PERFECT_NO
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
			LineTool.pixel_perfect)
	_add_separator()


func _on_ellipse_tool():
	_clean_up()
	_build_check_box(
			"Filled",
			func(toggle_on):
				var state = PixelPen.ToolBoxEllipse.TOOL_ELLIPSE_FILL_YES if toggle_on else PixelPen.ToolBoxEllipse.TOOL_ELLIPSE_FILL_NO
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
			EllipseTool.filled)
	_add_separator()


func _on_rectangle_tool():
	_clean_up()
	_build_check_box(
			"Filled",
			func(toggle_on):
				var state = PixelPen.ToolBoxRectangle.TOOL_RECTANGLE_FILL_YES if toggle_on else PixelPen.ToolBoxRectangle.TOOL_RECTANGLE_FILL_NO
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
			RectangleTool.filled)
	_add_separator()


func _on_fill_tool():
	_clean_up()
	_build_check_box(
			"Grow only in axis",
			func(toggle_on):
				var state = PixelPen.ToolBoxFill.TOOL_FILL_OPTION_ONLY_AXIS_YES if toggle_on else PixelPen.ToolBoxFill.TOOL_FILL_OPTION_ONLY_AXIS_NO
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
				FillTool.fill_grow_only_axis)
	_add_separator()


func _on_zoom_tool():
	_clean_up()
	_build_button("Zoom In", zoom_in, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxZoom.TOOL_ZOOM_IN, true, true)
	_build_button("Zoom Out", zoom_out, PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPen.ToolBoxZoom.TOOL_ZOOM_OUT, true)
	_add_separator()


func _clean_up():
	for child in button_list.get_children():
		child.queue_free()


func _add_separator(visible_callback : Callable = Callable(), target : Control = button_list):
	var vs = VSeparator.new()
	if visible_callback.is_valid():
		vs.set_script(preload("visible_callback.gd"))
		vs.visible_callback = visible_callback
		vs.visible = visible_callback.call()
	target.add_child(vs)


func _build_button(
			name : String,
			texture : Texture2D,
			grup : int,
			type: int,
			can_active : bool,
			default_active : bool = false,
			shorcut : Shortcut = null,
			visible_callback : Callable = Callable(),
			disable_callback : Callable = Callable(),
			target : Control = button_list,
			):
	var btn = TextureButton.new()
	btn.name = name
	btn.tooltip_text = name
	btn.texture_normal = texture
	btn.custom_minimum_size = Vector2(target.size.y, target.size.y)
	btn.pressed.connect(func ():
			PixelPen.tool_changed.emit(grup, type, can_active)
			)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	btn.shortcut = shorcut
	
	var mat = ShaderMaterial.new()
	mat.shader = shader_tint
	btn.material = mat
	
	var hover = Node.new()
	hover.set_script(preload("button_hover.gd"))
	hover.tool_grup = grup
	hover.tool_type = type
	hover.can_active = can_active
	hover.visible_callback = visible_callback
	hover.disable_callback = disable_callback
	btn.add_child(hover)
	
	target.add_child(btn)
	btn.owner = target.owner
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
		toggle_callback : Callable = Callable(),
		disable_callback : Callable = Callable(),
		):
	var btn = TextureButton.new()
	btn.name = normal_tooltip
	btn.tooltip_text = normal_tooltip
	btn.toggle_mode = true
	btn.texture_normal = texture_normal
	btn.texture_pressed = texture_pressed
	btn.button_pressed = toggle_callback.call()
	btn.custom_minimum_size = Vector2(toolbar_list.size.y, toolbar_list.size.y)
	btn.pressed.connect(func ():
			PixelPen.tool_changed.emit(grup, type, can_active)
			)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	btn.shortcut = shorcut
	
	var mat = ShaderMaterial.new()
	mat.shader = shader_tint
	btn.material = mat
	
	var hover = Node.new()
	hover.set_script(preload("button_hover.gd"))
	hover.tool_grup = grup
	hover.tool_type = type
	hover.can_active = can_active
	hover.visible_callback = func():
			btn.button_pressed = toggle_callback.call()
			btn.tooltip_text = pressed_tooltip if toggle_callback.call() else normal_tooltip
			return PixelPen.current_project != null
	hover.disable_callback = disable_callback
	btn.add_child(hover)
	
	toolbar_list.add_child(btn)
	btn.owner = toolbar_list.owner
	hover.is_active = default_active


func _build_check_box(label : String, toggle_callback : Callable, default_toggle : bool, visible_callback : Callable = Callable()):
	var check_box = CheckBox.new()
	check_box.focus_mode = Control.FOCUS_NONE
	check_box.custom_minimum_size.x = button_list.size.y
	check_box.text = label
	check_box.button_pressed = default_toggle
	check_box.toggled.connect(toggle_callback)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_child(check_box)
	
	if visible_callback.is_valid():
		margin.set_script(preload("visible_callback.gd"))
		margin.visible_callback = visible_callback
		margin.visible = visible_callback.call()
	
	button_list.add_child(margin)
	check_box.owner = button_list.owner


func _build_brush_preview(label : String):
	var btn = preview_btn.instantiate()
	btn.vbox.tooltip_text = "(LMB) Select brush \n(RMB) Delete brush"
	if PixelPen.userconfig.brush.size() > 0:
		BrushTool.brush_index = clampi(BrushTool.brush_index, 0, PixelPen.userconfig.brush.size() - 1)
		if current_toolbox == PixelPen.ToolBox.TOOL_BRUSH:
			PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, BrushTool.brush_index, false)
	btn.build_panel(btn.Mode.BRUSH)
	button_list.add_child(btn)
	btn.owner = button_list.owner
	btn.selected.connect(func(index):
		BrushTool.brush_index = clampi(index, 0, PixelPen.userconfig.brush.size() - 1)
		if PixelPen.userconfig.brush.size() > BrushTool.brush_index:
			btn.select(BrushTool.brush_index)
		else:
			btn.preview.texture = null
		PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, BrushTool.brush_index, false)
		)
	if PixelPen.userconfig.brush.size() > BrushTool.brush_index:
		btn.select(BrushTool.brush_index)


func _build_stamp_preview(label : String):
	var btn = preview_btn.instantiate()
	btn.vbox.tooltip_text = "(LMB) Select stamp \n(RMB) Delete stamp"
	if PixelPen.userconfig.stamp.size() > 0:
		StampTool.stamp_index = clampi(StampTool.stamp_index, 0, PixelPen.userconfig.stamp.size() - 1)
		if current_toolbox == PixelPen.ToolBox.TOOL_STAMP:
			PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, StampTool.stamp_index, false)
	btn.build_panel(btn.Mode.STAMP)
	button_list.add_child(btn)
	btn.owner = button_list.owner
	btn.selected.connect(func(index):
		StampTool.stamp_index = clampi(index, 0, PixelPen.userconfig.stamp.size() - 1)
		if PixelPen.userconfig.stamp.size() > StampTool.stamp_index:
			btn.select(StampTool.stamp_index)
		else:
			btn.preview.texture = null
		PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, StampTool.stamp_index, false)
		)
	if PixelPen.userconfig.stamp.size() > StampTool.stamp_index:
		btn.select(StampTool.stamp_index)

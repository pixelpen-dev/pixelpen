@tool
extends Control


var SelectTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/select_tool.gd")
var MoveTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/move_tool.gd")
var PenTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/pen_tool.gd")
var BrushTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/brush_tool.gd")
var StampTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/stamp_tool.gd")
var MagnetTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/magnet_tool.gd")
var LineTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/line_tool.gd")
var EllipseTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/ellipse_tool.gd")
var RectangleTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/rectangle_tool.gd")
var SelectionTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/selection_tool.gd")
var FillTool = load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/fill_tool.gd")

var undo = load("res://addons/net.yarvis.pixel_pen/resources/icon/undo.svg")
var redo = load("res://addons/net.yarvis.pixel_pen/resources/icon/redo.svg")
var fit_screen = load("res://addons/net.yarvis.pixel_pen/resources/icon/fit-to-screen-outline.svg")
var save = load("res://addons/net.yarvis.pixel_pen/resources/icon/content-save.svg")
var grid = load("res://addons/net.yarvis.pixel_pen/resources/icon/grid_3x3_24.svg")
var tint_black = load("res://addons/net.yarvis.pixel_pen/resources/icon/image-filter-black-white.svg")
var save_alert = load("res://addons/net.yarvis.pixel_pen/resources/icon/content-save-alert-outline.svg")

var cut = load("res://addons/net.yarvis.pixel_pen/resources/icon/content-cut.svg")
var copy = load("res://addons/net.yarvis.pixel_pen/resources/icon/content-copy.svg")
var cancel = load("res://addons/net.yarvis.pixel_pen/resources/icon/cancel.svg")
var commit = load("res://addons/net.yarvis.pixel_pen/resources/icon/check-circle-outline.svg")
var rotate_left = load("res://addons/net.yarvis.pixel_pen/resources/icon/rotate-left.svg")
var rotate_right = load("res://addons/net.yarvis.pixel_pen/resources/icon/rotate-right.svg")
var flip_horizontal = load("res://addons/net.yarvis.pixel_pen/resources/icon/flip-horizontal.svg")
var flip_vertical = load("res://addons/net.yarvis.pixel_pen/resources/icon/flip-vertical.svg")
var scale_left = load("res://addons/net.yarvis.pixel_pen/resources/icon/arrow-expand-left.svg")
var scale_up = load("res://addons/net.yarvis.pixel_pen/resources/icon/arrow-expand-up.svg")
var scale_right = load("res://addons/net.yarvis.pixel_pen/resources/icon/arrow-expand-right.svg")
var scale_down = load("res://addons/net.yarvis.pixel_pen/resources/icon/arrow-expand-down.svg")

var select_color = load("res://addons/net.yarvis.pixel_pen/resources/icon/select-color.svg")
var select_layer = load("res://addons/net.yarvis.pixel_pen/resources/icon/layers-search-outline.svg")

var selection_union = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-union.svg")
var selection_difference = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-difference-ba.svg")
var selection_intersection = load("res://addons/net.yarvis.pixel_pen/resources/icon/vector-intersection.svg")
var selection_inverse = load("res://addons/net.yarvis.pixel_pen/resources/icon/select-inverse.svg")
var selection_remove = load("res://addons/net.yarvis.pixel_pen/resources/icon/remove_selection_24.svg")
var delete_in_selection = load("res://addons/net.yarvis.pixel_pen/resources/icon/delete_in_selection.svg")

var zoom_in = load("res://addons/net.yarvis.pixel_pen/resources/icon/zoom_in_24.svg")
var zoom_out = load("res://addons/net.yarvis.pixel_pen/resources/icon/zoom_out_24.svg")

var shader_tint = load("res://addons/net.yarvis.pixel_pen/resources/tint_color.gdshader")

var preview_btn := load("res://addons/net.yarvis.pixel_pen/editor/image_option_btn.tscn")

@export var button_list : Control
@export var toolbar_list : Control
@export var shift_separator : VSeparator
@export var shift_label : Label
@export var canvas : Node2D

var current_toolbox : int


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	PixelPen.state.project_file_changed.connect(func ():
			if PixelPen.state.current_project == null:
				_clean_up()
			)
	PixelPen.state.toolbox_just_changed.connect(func(type):
			shift_label.visible = canvas.canvas_paint.tool.has_shift_mode
			shift_separator.visible = canvas.canvas_paint.tool.has_shift_mode
			current_toolbox = type
			_on_tool_changed(type)
			)
	PixelPen.state.toolbox_shift_mode.connect(func(active):
			shift_label.label_settings.font_color = PixelPen.state.userconfig.accent_color if active else PixelPen.state.userconfig.label_color
			)
	PixelPen.state.shorcut_changed.connect(func():
			_build_toolbar()
			_on_tool_changed(current_toolbox)
			)
	call_deferred("_build_toolbar")


func _process(_delta):
	if not PixelPen.state.need_connection(get_window()):
		return
	var enable : bool = canvas.get_viewport_rect().has_point(canvas.get_viewport().get_mouse_position())
	shift_label.modulate.a = 1.0 if enable else 0.5


func _exit_tree():
	_clean_up()


func _on_tool_changed(type :int):
	match type:
		PixelPenEnum.ToolBox.TOOL_SELECT:
			_on_select_tool()
		PixelPenEnum.ToolBox.TOOL_MOVE:
			_on_move_tool()
		PixelPenEnum.ToolBox.TOOL_SELECTION:
			_on_selection_tool()
		PixelPenEnum.ToolBox.TOOL_PEN:
			_on_pen_tool()
		PixelPenEnum.ToolBox.TOOL_BRUSH:
			_on_brush_tool()
		PixelPenEnum.ToolBox.TOOL_ERASER:
			_on_eraser_tool()
		PixelPenEnum.ToolBox.TOOL_STAMP:
			_on_stamp_tool()
		PixelPenEnum.ToolBox.TOOL_MAGNET:
			_on_magnet_tool()
		PixelPenEnum.ToolBox.TOOL_LINE:
			_on_line_tool()
		PixelPenEnum.ToolBox.TOOL_ELLIPSE:
			_on_ellipse_tool()
		PixelPenEnum.ToolBox.TOOL_RECTANGLE:
			_on_rectangle_tool()
		PixelPenEnum.ToolBox.TOOL_FILL:
			_on_fill_tool()
		PixelPenEnum.ToolBox.TOOL_ZOOM:
			_on_zoom_tool()
		_:
			_clean_up()


func _build_toolbar():
	for child in toolbar_list.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	_add_separator(func():
			return PixelPen.state.current_project != null,
			toolbar_list,
			)
	_build_button("Undo", undo, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPenEnum.ToolBar.TOOLBAR_UNDO, false, false, PixelPen.state.userconfig.shorcuts.undo,
			func ():
				if PixelPen.state.current_project == null:
					return false
				return true,
			func ():
				if PixelPen.state.current_project == null:
					return true
				return not PixelPen.state.current_project.undo_redo.has_undo(),
			toolbar_list,
			)
	_build_button("Redo", redo, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPenEnum.ToolBar.TOOLBAR_REDO, false, false, PixelPen.state.userconfig.shorcuts.redo,
			func ():
				if PixelPen.state.current_project == null:
					return false
				return true,
			func ():
				if PixelPen.state.current_project == null:
					return true
				if not PixelPen.state.current_project.undo_redo.has_redo():
					return true
				return not PixelPen.state.current_project.undo_redo.is_commited,
			toolbar_list,
			)
	_build_button("Reset zoom", fit_screen, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPenEnum.ToolBar.TOOLBAR_RESET_ZOOM, false, false, PixelPen.state.userconfig.shorcuts.reset_zoom,
			func ():
				if PixelPen.state.current_project == null:
					return false
				return true,
			func ():
				return PixelPen.state.current_project == null,
			toolbar_list,
			)
	_build_toggle_button("Grid", "Grid", grid, grid, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPenEnum.ToolBar.TOOLBAR_SHOW_GRID, true, 
			false, PixelPen.state.userconfig.shorcuts.view_show_grid,
			func ():
				if PixelPen.state.current_project == null:
					return false
				return PixelPen.state.current_project.show_grid,
			func ():
				if PixelPen.state.current_project == null:
					return true
				return false,
			)
	_build_toggle_button("Tint black", "Tint black", tint_black, tint_black, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPenEnum.ToolBar.TOOLBAR_TOGGLE_TINT_BLACK_LAYER, true,
			false, PixelPen.state.userconfig.shorcuts.toggle_tint_layer,
			func ():
				if PixelPen.state.current_project == null:
					return false
				return canvas.silhouette,
			func ():
				if PixelPen.state.current_project == null:
					return true
				return false,
			)
	_build_toggle_button("Save", "Save", save, save_alert, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBAR,
			PixelPenEnum.ToolBar.TOOLBAR_SAVE, false, false, PixelPen.state.userconfig.shorcuts.save,
			func ():
				if PixelPen.state.current_project == null:
					return true
				return not PixelPen.state.current_project.is_saved,
			func ():
				return PixelPen.state.current_project == null or PixelPen.state.current_project.is_saved,
			)


func _on_select_tool():
	_clean_up()
	_build_button("Find Layer", select_layer, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxSelect.TOOL_SELECT_LAYER, true, true)
	_build_button("Select Color", select_color, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxSelect.TOOL_SELECT_COLOR, true)
	_add_separator(func():
			return SelectTool.active_sub_tool_type == PixelPenEnum.ToolBoxSelect.TOOL_SELECT_COLOR)
	_build_check_box(
			"Grow only in axis",
			func(toggle_on):
				var state = PixelPenEnum.ToolBoxSelect.TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_YES if toggle_on else PixelPenEnum.ToolBoxSelect.TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_NO
				PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
				SelectTool.selection_color_grow_only_axis,
			func():
				return SelectTool.active_sub_tool_type == PixelPenEnum.ToolBoxSelect.TOOL_SELECT_COLOR)
	_add_separator()


func _on_move_tool():
	_clean_up()
	
	_build_button("Cut", cut, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_MOVE_CUT, false, false, PixelPen.state.userconfig.shorcuts.cut, func():
					return MoveTool.mode == MoveTool.Mode.UNKNOWN
					)
	_build_button("Copy", copy, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_MOVE_COPY, false, false, PixelPen.state.userconfig.shorcuts.copy, func():
					return MoveTool.mode == MoveTool.Mode.UNKNOWN
					)
	
	_build_button("Rotate Left", rotate_left, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_MOVE_ROTATE_LEFT, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.state.current_project.multilayer_selected.is_empty())
	_build_button("Rotate Right", rotate_right, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_MOVE_ROTATE_RIGHT, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.state.current_project.multilayer_selected.is_empty())
	_build_button("Flip Horizontal", flip_horizontal, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_MOVE_FLIP_HORIZONTAL, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.state.current_project.multilayer_selected.is_empty())
	_build_button("Flip Vertical", flip_vertical, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_MOVE_FLIP_VERTICAL, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.state.current_project.multilayer_selected.is_empty())
	
	_add_separator(func():
			return MoveTool.mode != MoveTool.Mode.UNKNOWN)
	
	_build_button("Scale Shifted Left", scale_left, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_SCALE_LEFT, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.state.current_project.multilayer_selected.is_empty())
	_build_button("Scale Shifted Top", scale_up, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_SCALE_UP, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.state.current_project.multilayer_selected.is_empty())
	_build_button("Scale Shifted Right", scale_right, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_SCALE_RIGHT, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.state.current_project.multilayer_selected.is_empty())
	_build_button("Scale Shifted Down", scale_down, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_SCALE_DOWN, false, false, null,
			func():
					return MoveTool.mode != MoveTool.Mode.UNKNOWN,
			func():
					return not PixelPen.state.current_project.multilayer_selected.is_empty())
	
	_add_separator(func():
			return MoveTool.mode != MoveTool.Mode.UNKNOWN)
	_build_button("Cancel Transform", cancel, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_MOVE_CANCEL, false, false, null,
			func():
				return MoveTool.mode != MoveTool.Mode.UNKNOWN)
	_build_button("Commit Transform", commit, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMove.TOOL_MOVE_COMMIT, false, false, PixelPen.state.userconfig.shorcuts.confirm,
			func():
				return MoveTool.transformed and  MoveTool.mode != MoveTool.Mode.UNKNOWN)
	_add_separator()


func _on_selection_tool():
	_clean_up()
	_build_button("Selection Union", selection_union, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION, true, SelectionTool.sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_UNION)
	_build_button("Selection Difference", selection_difference, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE, true, SelectionTool.sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DIFFERENCE)
	_build_button("Selection Intersection", selection_intersection, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INTERSECTION, true, SelectionTool.sub_tool_selection_type == PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INTERSECTION)
	_add_separator()
	_build_button("Inverse Selection", selection_inverse, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_INVERSE, false, false, PixelPen.state.userconfig.shorcuts.inverse_selection,
			func (): return true,
			func (): return canvas.selection_tool_hint.texture == null
			)
	_build_button("Remove Selection", selection_remove, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_REMOVE, false, false, PixelPen.state.userconfig.shorcuts.remove_selection,
			func (): return true,
			func (): return canvas.selection_tool_hint.texture == null
			)
	_build_button("Delete Selected Area", delete_in_selection, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_DELETE_SELECTED, false, false, PixelPen.state.userconfig.shorcuts.delete_selected,
			func (): return true,
			func (): return canvas.selection_tool_hint.texture == null
			)
	_add_separator(func():
			return SelectionTool.has_point_selection_polygon)
	_build_button("Cancel Polygon", cancel, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_CANCEL_POLYGON, false, false, null,
			func():
				return SelectionTool.has_point_selection_polygon)
	_build_button("Close Polygon", commit, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, 
			PixelPenEnum.ToolBoxSelection.TOOL_SELECTION_CLOSE_POLYGON, false, false, PixelPen.state.userconfig.shorcuts.confirm,
			func():
				return SelectionTool.can_commit_selection_polygon)
	_add_separator()


func _on_pen_tool():
	_clean_up()
	_build_check_box(
			"Pixel perfect",
			func(toggle_on):
				var state = PixelPenEnum.ToolBoxPen.TOOL_PEN_PIXEL_PERFECT_YES if toggle_on else PixelPenEnum.ToolBoxPen.TOOL_PEN_PIXEL_PERFECT_NO
				PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
			PenTool.pixel_perfect)
	_add_separator()


func _on_brush_tool():
	_clean_up()
	_build_brush_preview("Brush pattern")
	_add_separator()


func _on_eraser_tool():
	_clean_up()
	_build_brush_preview("Brush pattern", true)
	_add_separator()


func _on_stamp_tool():
	_clean_up()
	_build_stamp_preview("Stamp pattern")
	_add_separator()


func _on_magnet_tool():
	_clean_up()
	_build_button("Cancel", cancel, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxMagnet.TOOL_MAGNET_CANCEL, false, false, null,
			func():
				return MagnetTool.mode == MagnetTool.Mode.MOVE_PIXEL)
	_add_separator(func():
				return MagnetTool.mode == MagnetTool.Mode.MOVE_PIXEL)


func _on_line_tool():
	_clean_up()
	_build_check_box(
			"Pixel perfect",
			func(toggle_on):
				var state = PixelPenEnum.ToolBoxLine.TOOL_LINE_PIXEL_PERFECT_YES if toggle_on else PixelPenEnum.ToolBoxLine.TOOL_LINE_PIXEL_PERFECT_NO
				PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
			LineTool.pixel_perfect)
	_add_separator()


func _on_ellipse_tool():
	_clean_up()
	_build_check_box(
			"Filled",
			func(toggle_on):
				var state = PixelPenEnum.ToolBoxEllipse.TOOL_ELLIPSE_FILL_YES if toggle_on else PixelPenEnum.ToolBoxEllipse.TOOL_ELLIPSE_FILL_NO
				PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
			EllipseTool.filled)
	_add_separator()


func _on_rectangle_tool():
	_clean_up()
	_build_check_box(
			"Filled",
			func(toggle_on):
				var state = PixelPenEnum.ToolBoxRectangle.TOOL_RECTANGLE_FILL_YES if toggle_on else PixelPenEnum.ToolBoxRectangle.TOOL_RECTANGLE_FILL_NO
				PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
			RectangleTool.filled)
	_add_separator()


func _on_fill_tool():
	_clean_up()
	_build_check_box(
			"Grow only in axis",
			func(toggle_on):
				var state = PixelPenEnum.ToolBoxFill.TOOL_FILL_OPTION_ONLY_AXIS_YES if toggle_on else PixelPenEnum.ToolBoxFill.TOOL_FILL_OPTION_ONLY_AXIS_NO
				PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, state, false),
				FillTool.fill_grow_only_axis)
	_add_separator()


func _on_zoom_tool():
	_clean_up()
	_build_button("Zoom In", zoom_in, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxZoom.TOOL_ZOOM_IN, true, true)
	_build_button("Zoom Out", zoom_out, PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
			PixelPenEnum.ToolBoxZoom.TOOL_ZOOM_OUT, true)
	_add_separator()


func _clean_up():
	for child in button_list.get_children():
		child.queue_free()


func _add_separator(visible_callback : Callable = Callable(), target : Control = button_list):
	var vs = VSeparator.new()
	if visible_callback.is_valid():
		vs.set_script(load("res://addons/net.yarvis.pixel_pen/editor/editor_main_ui/visible_callback.gd"))
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
			return PixelPen.state.current_project != null
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
		margin.set_script(load("res://addons/net.yarvis.pixel_pen/editor/editor_main_ui/visible_callback.gd"))
		margin.visible_callback = visible_callback
		margin.visible = visible_callback.call()
	
	button_list.add_child(margin)
	check_box.owner = button_list.owner


func _build_brush_preview(label : String, eraser : bool = false):
	var btn = preview_btn.instantiate()
	btn.vbox.tooltip_text = "(LMB) Select brush \n(RMB) Delete brush"
	if PixelPen.state.userconfig.brush.size() == 0:
		var image : Image = Image.create(1, 1, false, Image.FORMAT_R8)
		image.set_pixel(0, 0, Color8(255, 0, 0))
		PixelPen.state.userconfig.brush.push_back(image)
		PixelPen.state.userconfig.save()
	if PixelPen.state.userconfig.brush.size() > 0:
		BrushTool.brush_index = clampi(BrushTool.brush_index, 0, PixelPen.state.userconfig.brush.size() - 1)
		if current_toolbox == PixelPenEnum.ToolBox.TOOL_BRUSH:
			PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, BrushTool.brush_index, false)
	if eraser:
		btn.build_panel(btn.Mode.ERASER)
	else:
		btn.build_panel(btn.Mode.BRUSH)
	button_list.add_child(btn)
	btn.owner = button_list.owner
	btn.selected.connect(func(index):
		BrushTool.brush_index = clampi(index, 0, PixelPen.state.userconfig.brush.size() - 1)
		if PixelPen.state.userconfig.brush.size() > BrushTool.brush_index:
			btn.select(BrushTool.brush_index)
		else:
			btn.preview.texture = null
		PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, BrushTool.brush_index, false)
		)
	if PixelPen.state.userconfig.brush.size() > BrushTool.brush_index:
		btn.select(BrushTool.brush_index)


func _build_stamp_preview(label : String):
	var btn = preview_btn.instantiate()
	btn.vbox.tooltip_text = "(LMB) Select stamp \n(RMB) Delete stamp"
	if PixelPen.state.userconfig.stamp.size() > 0:
		StampTool.stamp_index = clampi(StampTool.stamp_index, 0, PixelPen.state.userconfig.stamp.size() - 1)
		if current_toolbox == PixelPenEnum.ToolBox.TOOL_STAMP:
			PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, StampTool.stamp_index, false)
	btn.build_panel(btn.Mode.STAMP)
	button_list.add_child(btn)
	btn.owner = button_list.owner
	btn.selected.connect(func(index):
		StampTool.stamp_index = clampi(index, 0, PixelPen.state.userconfig.stamp.size() - 1)
		if PixelPen.state.userconfig.stamp.size() > StampTool.stamp_index:
			btn.select(StampTool.stamp_index)
		else:
			btn.preview.texture = null
		PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, StampTool.stamp_index, false)
		)
	if PixelPen.state.userconfig.stamp.size() > StampTool.stamp_index:
		btn.select(StampTool.stamp_index)

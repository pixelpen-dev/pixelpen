@tool
#class_name PixelPen
extends Node


signal theme_changed

signal debug_log(key, value)
signal project_file_changed
signal project_saved(is_saved)
signal palette_changed
signal color_picked(color)
signal layer_image_changed(layer_uid)
signal layer_active_changed(layer_uid)
signal layer_visibility_changed(layer_uid, visible)
signal layer_items_changed
signal thumbnail_changed
signal edit_mode_changed(mode)

signal request_new_project
signal request_open_project
signal request_import_image
signal request_save_project
signal request_save_as_project
signal request_layer_properties(layer_uid)

signal tool_changed(tool_grup, tool_type, grab_active)
signal toolbox_just_changed(tool_type)
signal toolbox_shift_mode(active)

signal animation_about_to_play

# Minimum project version can be handle by current app version
# [project.compatibility_version < MIN_COMPATIBILITY ] > FAIL
const MIN_COMPATIBILITY = 3
const EDITOR_TITTLE = "Pixel Pen"

# load gif exporter module
const GIFExporter = preload("thirdparty/gdgifexporter/exporter.gd")
# load quantization module that you want to use
const MedianCutQuantization = preload("thirdparty/gdgifexporter/quantization/median_cut.gd")


enum ToolBoxGrup{
	TOOL_GRUP_UNKNOWN = -1,
	TOOL_GRUP_TOOLBOX,
	TOOL_GRUP_TOOLBOX_SUB_TOOL,
	TOOL_GRUP_LAYER,
	TOOL_GRUP_ANIMATION,
	TOOL_GRUP_TOOLBAR,
}

enum ToolBox{
	TOOL_UNKNOWN = -1,
	TOOL_SELECT,
	TOOL_MOVE,
	TOOL_PAN,
	TOOL_SELECTION,
	TOOL_PEN,
	TOOL_BRUSH,
	TOOL_STAMP,
	TOOL_ERASER,
	TOOL_MAGNET,
	TOOL_LINE,
	TOOL_ELLIPSE,
	TOOL_RECTANGLE,
	TOOL_FILL,
	TOOL_COLOR_PICKER,
	TOOL_ZOOM
}


enum ToolBoxSelect{
	TOOL_SELECT_UNKNOWN = -1,
	TOOL_SELECT_LAYER,
	TOOL_SELECT_COLOR,
	TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_YES,
	TOOL_SELECTION_COLOR_OPTION_ONLY_AXIS_NO
}


enum ToolBoxMove{
	TOOL_MOVE_UNKNOWN = -1,
	TOOL_MOVE_CUT,
	TOOL_MOVE_COPY,
	TOOL_MOVE_ROTATE_LEFT,
	TOOL_MOVE_ROTATE_RIGHT,
	TOOL_MOVE_FLIP_HORIZONTAL,
	TOOL_MOVE_FLIP_VERTICAL,
	TOOL_MOVE_CANCEL,
	TOOL_MOVE_COMMIT,
	TOOL_SCALE_LEFT,
	TOOL_SCALE_UP,
	TOOL_SCALE_RIGHT,
	TOOL_SCALE_DOWN
}

enum ToolBoxSelection{
	TOOL_SELECTION_UNKNOWN = -1,
	TOOL_SELECTION_UNION,
	TOOL_SELECTION_DIFFERENCE,
	TOOL_SELECTION_INTERSECTION,
	TOOL_SELECTION_CLOSE_POLYGON,
	TOOL_SELECTION_CANCEL_POLYGON,
	TOOL_SELECTION_INVERSE = 1001, # GLOBAL UNIQUE
	TOOL_SELECTION_REMOVE = 1002, # GLOBAL UNIQUE
	TOOL_SELECTION_DELETE_SELECTED = 1003 # GLOBAL UNIQUE
}

enum ToolBoxPen{
	TOOL_PEN_UNKNOWN = -1,
	TOOL_PEN_PIXEL_PERFECT_YES,
	TOOL_PEN_PIXEL_PERFECT_NO
}


enum ToolBoxMagnet{
	TOOL_MAGNET_UNKNOWN = -1,
	TOOL_MAGNET_CANCEL
}


enum ToolBoxLine{
	TOOL_LINE_UNKNOWN = -1,
	TOOL_LINE_PIXEL_PERFECT_YES,
	TOOL_LINE_PIXEL_PERFECT_NO
}


enum ToolBoxEllipse{
	TOOL_ELLIPSE_UNKNOWN = -1,
	TOOL_ELLIPSE_FILL_YES,
	TOOL_ELLIPSE_FILL_NO
}


enum ToolBoxRectangle{
	TOOL_RECTANGLE_UNKNOWN = -1,
	TOOL_RECTANGLE_FILL_YES,
	TOOL_RECTANGLE_FILL_NO
}


enum ToolBoxFill{
	TOOL_FILL_UNKNOWN = -1,
	TOOL_FILL_OPTION_ONLY_AXIS_YES,
	TOOL_FILL_OPTION_ONLY_AXIS_NO
}


enum ToolBoxZoom{
	TOOL_ZOOM_UNKNOWN = -1,
	TOOL_ZOOM_IN,
	TOOL_ZOOM_OUT,
}


enum ToolAnimation{
	TOOL_ANIMATION_UNKNOWN = -1,
	TOOL_ANIMATION_PLAY_PAUSE,
	TOOL_ANIMATION_SKIP_TO_FRONT,
	TOOL_ANIMATION_STEP_BACKWARD,
	TOOL_ANIMATION_STEP_FORWARD,
	TOOL_ANIMATION_SKIP_TO_END
}


enum ToolBar{
	TOOLBAR_UNKNOWN = -1,
	TOOLBAR_UNDO,
	TOOLBAR_RESET_ZOOM,
	TOOLBAR_REDO,
	TOOLBAR_SHOW_GRID,
	TOOLBAR_TOGGLE_TINT_BLACK_LAYER,
	TOOLBAR_SAVE,
}


enum ResizeAnchor{
	CENTER = 0,
	TOP_LEFT,
	TOP,
	TOP_RIGHT,
	RIGHT,
	BOTTOM_RIGHT,
	BOTTOM,
	BOTTOM_LEFT,
	LEFT
}


var current_project : PixelPenProject:
	set(v):
		current_project = v
		if v != null and v.file_path != "":
			save_cache_project_config()

var utils : PixelPenCPP = PixelPenCPP.new()

var userconfig : UserConfig:
	get:
		if userconfig == null:
			userconfig = UserConfig.load_data()
		return userconfig as UserConfig

## Call this when closing PixelPen editor window
func disconnect_all_signal():
	var signals : Array[String] = [
		"theme_changed",
		"debug_log",
		"project_file_changed",
		"project_saved",
		"palette_changed",
		"color_picked",
		"layer_image_changed",
		"layer_active_changed",
		"layer_visibility_changed",
		"layer_items_changed",
		"thumbnail_changed",
		"edit_mode_changed",
		"request_new_project",
		"request_open_project",
		"request_import_image",
		"request_save_project",
		"request_save_as_project",
		"request_layer_properties",
		"tool_changed",
		"toolbox_just_changed",
		"toolbox_shift_mode",
		"animation_about_to_play"]
	for i in range(signals.size()):
		var connection_list : Array[Dictionary] = get_signal_connection_list(signals[i])
		for connection in connection_list:
			connection["signal"].disconnect(connection["callable"])


func load_project(file : String)->bool:
	var erase_recent = func(file_path : String):
		if userconfig.recent_projects.has(file_path):
			userconfig.recent_projects.erase(file_path)
			userconfig.save()
	
	if not ResourceLoader.exists(file):
		erase_recent.call(file)
		return false
	for dependencies in ResourceLoader.get_dependencies(file):
		if not ResourceLoader.exists(dependencies):
			erase_recent.call(file)
			return false
	var res = ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res and res is PixelPenProject:
		var project_compat_version = res.get("compatibility_version")
		if project_compat_version == null or MIN_COMPATIBILITY > project_compat_version:
			erase_recent.call(file)
			return false
		current_project = res
		current_project.is_saved = true
		userconfig.insert_recent_projects(file)
		current_project.sync_gui_palette(true)
		project_file_changed.emit()
		return true
	erase_recent.call(file)
	return false


func save_cache_project_config():
	var p_path = ""
	if current_project != null:
		p_path = current_project.file_path
	userconfig.last_open_path = p_path
	userconfig.save()


func load_cache_project() -> bool:
	if userconfig.last_open_path != "":
		return load_project(userconfig.last_open_path)
	return false

## Prevent running in development mode
func need_connection(window : Window):
	var need := false
	if window.has_method("is_window_running"):
		need = window.is_window_running()
	return need or not Engine.is_editor_hint()


func get_directory():
	if current_project == null:
		return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if current_project.file_path == "" or current_project.file_path.get_base_dir() == "":
		return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	return current_project.file_path.get_base_dir()

@tool
class_name PixelPenState
extends Object


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
signal shorcut_changed

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
var GIFExporter = load("res://addons/net.yarvis.pixel_pen/thirdparty/gdgifexporter/exporter.gd")
# load quantization module that you want to use
var MedianCutQuantization = load("res://addons/net.yarvis.pixel_pen/thirdparty/gdgifexporter/quantization/median_cut.gd")


var current_project : PixelPenProject:
	set(v):
		current_project = v
		if v != null and v.file_path != "":
			save_cache_project_config()

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
		"shorcut_changed",
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
	if file.get_extension() == "res":
		if not ResourceLoader.exists(file):
			erase_recent.call(file)
			return false
		for dependencies in ResourceLoader.get_dependencies(file):
			if not ResourceLoader.exists(dependencies):
				erase_recent.call(file)
				return false
	var res = ProjectPacker.load_project(file)
	if res == null:
		erase_recent.call(file)
		return false
	elif res and res is PixelPenProject:
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
	if current_project == null or current_project.file_path == "" or current_project.file_path.get_base_dir() == "":
		if userconfig.default_workspace == null or userconfig.default_workspace == "":
			return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		return userconfig.default_workspace
	return current_project.file_path.get_base_dir()

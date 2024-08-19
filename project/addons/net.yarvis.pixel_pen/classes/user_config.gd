@tool
extends Resource
class_name UserConfig


const PATH := "user://pixelpen_user_config.res"

@export_category("Cache")
@export var brush : Array[Image]
@export var stamp : Array[Image]
@export var recent_projects : Array = []
@export var last_open_path : String

@export_category("Style")
@export var accent_color : Color = Color(0.25, 1, 0.5)
@export var label_color : Color = Color.WHITE
@export var main_panel_color : Color = Color(0.133, 0.133, 0.133, 1.0)
@export var box_panel_color : Color = Color(0.23, 0.23, 0.23, 1.0)
@export var box_panel_darker_color : Color = Color(0.15, 0.15, 0.15, 1.0)
@export var box_panel_title_color : Color = Color(0.28, 0.28, 0.28, 1.0)
@export var canvas_base_mode_color : Color = Color(0.38, 0.38, 0.38, 1.0)
@export var canvas_sample_mode_color : Color = Color(0.18, 0.18, 0.30, 1.0)
@export var layer_placeholder_color : Color = Color(0.17, 0.17, 0.17, 1.0)
@export var layer_head_color : Color = Color(0.2, 0.2, 0.2, 1.0)
@export var layer_body_color : Color = Color(0.19, 0.19, 0.19, 1.0)
@export var layer_active_color : Color = Color(0.3, 0.3, 0.3, 1.0)
@export var layer_secondary_active_color : Color = Color(0.25, 0.25, 0.25, 1.0)

@export_category("Preferences")
@export_subgroup("General")
@export var default_grid_size : Vector2i = Vector2i(8, 8)
@export var checker_size : Vector2i = Vector2i(8, 8)
@export var default_workspace : String = ""
@export var default_canvas_size : Vector2i = Vector2i(128, 128)
@export var hide_cursor_in_canvas : bool = true
@export var default_animation_fps : int = 24
@export var onion_skin_total : int = 3
@export var onion_skin_tint_previous : Color = Color.BLUE
@export var onion_skin_tint_next : Color = Color.GREEN
@export var onion_skin_tint_alpha : float = 0.5
@export var palette_gui_row : int = 8

@export_subgroup("Shorcuts")
@export var shorcuts : EditorShorcut = load("res://addons/net.yarvis.pixel_pen/resources/editor_shorcut.tres")


static func load_data(reset : bool = false):
	if not reset and ResourceLoader.exists(PATH):
		var res = ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res and res is UserConfig:
			return res
	var new_user = UserConfig.new()
	new_user.save()
	return new_user


func resolve_null():
	var default = UserConfig.new()
	for value in get_property_list():
		if get(value["name"]) == null and default.get(value["name"]) != null:
			set(value["name"], default.get(value["name"]))
			save()


func save():
	ResourceSaver.save(self, PATH)


func make_brush_from_project(mask : Image) -> bool:
	if PixelPen.state.current_project == null:
		return false
	brush.push_back((PixelPen.state.current_project as PixelPenProject).get_region_project_colormap(mask))
	save()
	return true


func delete_brush(index : int):
	if index < brush.size() and index >= 0:
		brush.remove_at(index)
		save()


func make_stamp_from_project(mask : Image) -> bool:
	if PixelPen.state.current_project == null:
		return false
	stamp.push_back((PixelPen.state.current_project as PixelPenProject).get_region_project_image(mask))
	save()
	return true


func delete_stamp(index : int):
	if index < stamp.size() and index >= 0:
		stamp.remove_at(index)
		save()


func insert_recent_projects(file_path : String):
	if not recent_projects.has(file_path):
		recent_projects.push_back(file_path)
		if recent_projects.size() > 10:
			recent_projects = recent_projects.slice(recent_projects.size() - 10)
		save()

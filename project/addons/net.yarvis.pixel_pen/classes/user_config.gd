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


static func load_data(reset : bool = false):
	if not reset and ResourceLoader.exists(PATH):
		var res = ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res and res is UserConfig:
			return res
	return UserConfig.new()


func save():
	ResourceSaver.save(self, PATH)


func make_brush_from_project(mask : Image) -> bool:
	if PixelPen.current_project == null:
		return false
	brush.push_back((PixelPen.current_project as PixelPenProject).get_region_project_colormap(mask))
	save()
	return true


func delete_brush(index : int):
	if index < brush.size() and index >= 0:
		brush.remove_at(index)
		save()


func make_stamp_from_project(mask : Image) -> bool:
	if PixelPen.current_project == null:
		return false
	stamp.push_back((PixelPen.current_project as PixelPenProject).get_region_project_image(mask))
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

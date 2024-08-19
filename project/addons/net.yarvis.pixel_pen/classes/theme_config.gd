@tool
class_name ThemeConfig
extends Node


@export_enum("Main UI:0", "Layer:1") var type : int

@export_category("Editor Main UI")
@export var editor_main_ui : Control
@export var main_panel : Panel
@export var main_menu : Panel

@export var palette_title_panel : Panel
@export var preview_wrapper_panel : ColorRect
@export var preview_title_panel : Panel

@export var layers_wrapper_panel : Panel
@export var layer_title_panel : Panel
@export var animation_menu_panel : Panel
@export var animation_frame_panel : Panel

@export_subgroup("Dock")
@export var toolbox_dock : Control
@export var palette_dock : Control
@export var color_wheel_dock : Control
@export var subtool_dock : Control
@export var preview_dock : Control 
@export var layer_dock : Control
@export var canvas_dock : Control
@export var animation_dock : Control

@export_category("Layer UI")
@export var wrapper_layer_control : ColorRect
@export var head_layer_control : ColorRect
@export var detached_layer_control : ColorRect


static func init_screen():
	if OS.get_name() == "Android":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)


func _ready():
	PixelPen.state.theme_changed.connect(_on_theme_changed)
	_on_theme_changed()


func get_default_layout(layout_node : Control)-> DataBranch:
	var res := DataBranch.new()
	
	var ratio : Vector2 = Vector2(40, 40) / get_viewport().get_visible_rect().size
	if OS.get_name() == "Android" and ratio.y < ratio.x:
		ratio = Vector2(50, 50) / get_viewport().get_visible_rect().size
		res.data.push_back(
				Branch.create("Toolbox", NodePath("."), layout_node.get_path_to(toolbox_dock), 0.0, false))
		res.data.push_back(
				Branch.create("Subtool", layout_node.get_path_to(toolbox_dock), layout_node.get_path_to(subtool_dock), ratio.y, true))
		res.data.push_back(
				Branch.create("Palette", layout_node.get_path_to(subtool_dock), layout_node.get_path_to(palette_dock), ratio.y, true))
		
		res.data.push_back(
				Branch.create("Canvas", layout_node.get_path_to(palette_dock), layout_node.get_path_to(canvas_dock), 0.3, false))
		res.data.push_back(
				Branch.create("Animation", layout_node.get_path_to(canvas_dock), layout_node.get_path_to(animation_dock), 0.8, true))
		res.data.push_back(
				Branch.create("Preview", layout_node.get_path_to(palette_dock), layout_node.get_path_to(preview_dock), 0.5, true))
		res.data.push_back(
				Branch.create("Layer", layout_node.get_path_to(preview_dock), layout_node.get_path_to(layer_dock), 0.35, true))
		res.data.push_back(
			Branch.create("ColorWheel", layout_node.get_path_to(palette_dock), layout_node.get_path_to(color_wheel_dock), 0.5, true))
		return res
	res.data.push_back(
			Branch.create("ToolBox", NodePath("."), layout_node.get_path_to(toolbox_dock), 0.0, false))
	res.data.push_back(
			Branch.create("Palette", layout_node.get_path_to(toolbox_dock), layout_node.get_path_to(palette_dock), ratio.x, false))
	res.data.push_back(
			Branch.create("SubTool", layout_node.get_path_to(palette_dock), layout_node.get_path_to(subtool_dock), 0.15, false))
	res.data.push_back(
			Branch.create("Preview", layout_node.get_path_to(subtool_dock), layout_node.get_path_to(preview_dock), 0.8, false))
	res.data.push_back(
			Branch.create("Layer", layout_node.get_path_to(preview_dock), layout_node.get_path_to(layer_dock), 0.35, true))
	res.data.push_back(
			Branch.create("Canvas", layout_node.get_path_to(subtool_dock), layout_node.get_path_to(canvas_dock), ratio.y, true))
	res.data[5].parent_size = 40
	res.data.push_back(
			Branch.create("Animation", layout_node.get_path_to(canvas_dock), layout_node.get_path_to(animation_dock), 0.8, true))
	res.data.push_back(
			Branch.create("ColorWheel", layout_node.get_path_to(palette_dock), layout_node.get_path_to(color_wheel_dock), 0.5, true))
	return res


func use_safe_area(control : Control):
	var curent_rect : Rect2i = control.get_rect()
	var safe_area : Rect2i = DisplayServer.get_display_safe_area()
	curent_rect.position = safe_area.position
	curent_rect.size = Vector2i(mini(curent_rect.size.x, safe_area.size.x), mini(curent_rect.size.y, safe_area.size.y))
	control.position = curent_rect.position
	control.size = curent_rect.size


func _on_theme_changed():
	if type == 0:
		editor_main_ui.canvas_color_base = PixelPen.state.userconfig.canvas_base_mode_color
		editor_main_ui.canvas_color_sample = PixelPen.state.userconfig.canvas_sample_mode_color
	
	elif type == 1:
		wrapper_layer_control.default_color = PixelPen.state.userconfig.layer_body_color
		wrapper_layer_control.active_color = PixelPen.state.userconfig.layer_active_color
		wrapper_layer_control.secondary_active_color = PixelPen.state.userconfig.layer_secondary_active_color
		wrapper_layer_control.color = PixelPen.state.userconfig.layer_placeholder_color
		head_layer_control.color = PixelPen.state.userconfig.layer_head_color
		detached_layer_control.color = PixelPen.state.userconfig.box_panel_darker_color

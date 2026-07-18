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


const UI_SCALE_MIN := 1.0
const UI_SCALE_MAX := 3.0
const UI_SCALE_STEP := 0.25


## Detect a sensible UI scale from the current display (desktop only).
## Prefers DisplayServer.screen_get_scale() (accurate on macOS / Wayland) and
## falls back to screen DPI / 96. Result is quantized to UI_SCALE_STEP and
## clamped to [UI_SCALE_MIN, UI_SCALE_MAX]. Returns 1.0 on mobile/web/headless.
static func get_auto_ui_scale() -> float:
	var os_name := OS.get_name()
	if os_name == "Android" or os_name == "iOS" or os_name == "Web":
		return 1.0
	if DisplayServer.get_name() == "headless":
		return 1.0
	var screen := DisplayServer.window_get_current_screen()
	var scale := 1.0
	var reported_scale := DisplayServer.screen_get_scale(screen)
	if reported_scale > 0.0:
		scale = reported_scale
	# On Windows screen_get_scale() commonly returns 1.0 even at higher OS
	# scaling, so also derive a factor from the physical DPI and take the max.
	var dpi := DisplayServer.screen_get_dpi(screen)
	if dpi > 0:
		scale = maxf(scale, float(dpi) / 96.0)
	# Quantize to avoid odd fractional factors, then clamp.
	scale = roundf(scale / UI_SCALE_STEP) * UI_SCALE_STEP
	return clampf(scale, UI_SCALE_MIN, UI_SCALE_MAX)


## Resolve the effective UI scale, honoring the user's ui_scale preference
## (0.0 = Auto). In the Godot editor plugin, Auto follows the editor scale.
static func resolve_ui_scale(editor_hint : bool) -> float:
	var configured := 0.0
	if PixelPen.state != null and PixelPen.state.userconfig != null:
		configured = PixelPen.state.userconfig.ui_scale
	if configured > 0.0:
		return clampf(configured, UI_SCALE_MIN, UI_SCALE_MAX)
	if editor_hint and Engine.is_editor_hint() and Engine.has_singleton("EditorInterface"):
		return Engine.get_singleton("EditorInterface").get_editor_scale()
	return get_auto_ui_scale()


## Apply the resolved UI scale to a window using content_scale_factor while
## keeping native-resolution rendering (mode DISABLED). Returns the scale used.
static func apply_ui_scale(window : Window, editor_hint : bool) -> float:
	var scale := resolve_ui_scale(editor_hint)
	if window != null:
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
		window.content_scale_factor = scale
	return scale


## The icon .svg files are imported with svg/scale=ICON_BASE_SCALE so the
## textures carry enough pixels to stay crisp when the UI scale is above 1.
## Keep this constant in sync with svg/scale in resources/icon/*.svg.import.
const ICON_BASE_SCALE := 2.0

static var _icon_cache : Dictionary = {}


## Load an icon texture that reports its logical (1x) size for layout while
## carrying ICON_BASE_SCALE x pixel data, so icons keep their exact current
## size everywhere but stay sharp when drawn at a higher UI scale.
static func ui_icon(path : String) -> Texture2D:
	if _icon_cache.has(path):
		return _icon_cache[path]
	var texture : Texture2D = load(path)
	if texture == null:
		return null
	var image : Image = texture.get_image()
	if image == null or image.is_empty():
		return texture
	var icon := ImageTexture.create_from_image(image)
	icon.set_size_override(Vector2i((image.get_size() as Vector2 / ICON_BASE_SCALE).round()))
	_icon_cache[path] = icon
	return icon


## Recursively swap icon textures assigned in .tscn files (TextureRect and
## TextureButton) with their logical-size ui_icon() equivalent, and use linear
## filtering so the higher-resolution icon downsamples smoothly. Call this on
## a scene root after instantiation.
static func upgrade_icons(node : Node):
	var swap := func(tex):
		if tex is Texture2D and tex.resource_path.begins_with("res://addons/net.yarvis.pixel_pen/resources/icon/") \
				and tex.resource_path.ends_with(".svg"):
			return ui_icon(tex.resource_path)
		return tex
	if node is TextureRect:
		var swapped = swap.call(node.texture)
		if swapped != node.texture:
			node.texture = swapped
			node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	elif node is TextureButton:
		var changed := false
		for property in ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]:
			var swapped = swap.call(node.get(property))
			if swapped != node.get(property):
				node.set(property, swapped)
				changed = true
		if changed:
			node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for child in node.get_children():
		upgrade_icons(child)


func _ready():
	PixelPen.state.theme_changed.connect(_on_theme_changed)
	_on_theme_changed()


## Desktop toolbox column sizing, in layout units so it scales with the UI
## scale: the 40-unit icon buttons plus breathing room on each side.
const TOOLBOX_BUTTON_SIZE := 40.0
const TOOLBOX_DOCK_PADDING := 7.0


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
	var toolbox_width : float = TOOLBOX_BUTTON_SIZE + 2.0 * TOOLBOX_DOCK_PADDING
	res.data.push_back(
			Branch.create("ToolBox", NodePath("."), layout_node.get_path_to(toolbox_dock), 0.0, false))
	var palette_branch := Branch.create("Palette", layout_node.get_path_to(toolbox_dock), layout_node.get_path_to(palette_dock), toolbox_width / get_viewport().get_visible_rect().size.x, false)
	# Dragging the split (or shrinking the window) must not squeeze the
	# toolbox below its padded icon width.
	palette_branch.parent_min_size = toolbox_width
	res.data.push_back(palette_branch)
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

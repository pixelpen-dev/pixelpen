@tool
extends Control


var MoveTool := load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/move_tool.gd")


@export var default_color : Color
@export var active_color : Color
@export var secondary_active_color : Color

@export var visible_btn : Control

@export var active_btn : Button
@export var active_rect : ColorRect
@export var pickable : Node

@export var preview : TextureRect

@export var label : Label

@export var layer_visible : bool = true:
	set(v):
		visible_btn.get_node("ON").visible = v
		visible_btn.get_node("OFF").visible = !v
		layer_visible = v

var layer_uid : Vector3i
var _double_click_timer : float


var thread = Thread.new()


func _exit_tree():
	if thread.is_started():
		thread.wait_to_finish()


func _ready():
	active_rect.self_modulate = default_color
	
	if not PixelPen.state.need_connection(get_window()):
		return
		
	PixelPen.state.layer_active_changed.connect(func(uid):
			active(layer_uid == uid)
			)
	PixelPen.state.layer_image_changed.connect(func(layer_change_uid : Vector3i):
			if layer_change_uid == layer_uid:
				update_preview_texture()
			)
	PixelPen.state.layer_items_changed.connect(func():
			if PixelPen.state.current_project == null or PixelPen.state.current_project.animation_is_play:
				return
			if (PixelPen.state.current_project as PixelPenProject).active_layer_uid == layer_uid:
				update_preview_texture()
			)
	update_preview_texture()


func update_preview_texture():
	if PixelPen.state.current_project == null:
		return
	var image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).get_index_image(layer_uid)
	if image != null:
		if preview.texture == null:
			preview.call_deferred("set_texture", image.get_mipmap_texture(
				(PixelPen.state.current_project as PixelPenProject).palette
			))
		else:
			var img : Image = image.get_mipmap_image((PixelPen.state.current_project as PixelPenProject).palette.color_index)
			if img.get_size() == (preview.texture.get_size() as Vector2i):
				preview.texture.call_deferred("update", img)
			else:
				preview.call_deferred("set_texture", ImageTexture.create_from_image(img))
		var ratio : float = (image.size.x as float) / (image.size.y as float)
		(preview.get_parent() as AspectRatioContainer).call_deferred("set_ratio",  ratio)


func active(yes : bool):
	if yes:
		(PixelPen.state.current_project as PixelPenProject).active_layer_uid = layer_uid
		(PixelPen.state.current_project as PixelPenProject).active_frame.layer_active_uid = layer_uid
		active_rect.self_modulate = active_color
	elif PixelPen.state.current_project.multilayer_selected.has(layer_uid):
		active_rect.self_modulate = secondary_active_color
	else:
		active_rect.self_modulate = default_color


func _on_visible_gui_input(event):
	if event and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).get_index_image(layer_uid)
				if index_image != null:
					layer_visible = !layer_visible
					index_image.visible = layer_visible
					PixelPen.state.layer_visibility_changed.emit(layer_uid, layer_visible)
					PixelPen.state.project_saved.emit(false)


func _on_button_pressed():
	if MoveTool.mode != MoveTool.Mode.UNKNOWN and (not PixelPen.state.current_project.multilayer_selected.is_empty() or Input.is_key_pressed(KEY_SHIFT)):
		return
	if (PixelPen.state.current_project as PixelPenProject).active_layer_uid != layer_uid:
		if Input.is_key_pressed(KEY_SHIFT):
			if not PixelPen.state.current_project.multilayer_selected.has((PixelPen.state.current_project as PixelPenProject).active_layer_uid):
				PixelPen.state.current_project.multilayer_selected.push_back((PixelPen.state.current_project as PixelPenProject).active_layer_uid)
			if not PixelPen.state.current_project.multilayer_selected.has(layer_uid):
				PixelPen.state.current_project.multilayer_selected.push_back(layer_uid)
		else:
			PixelPen.state.current_project.multilayer_selected.clear()
		PixelPen.state.layer_active_changed.emit(layer_uid)
	elif not Input.is_key_pressed(KEY_SHIFT) and not PixelPen.state.current_project.multilayer_selected.is_empty():
		PixelPen.state.current_project.multilayer_selected.clear()
		PixelPen.state.layer_active_changed.emit(layer_uid)
		
	if Time.get_unix_time_from_system() - _double_click_timer < 0.5:
		PixelPen.state.request_layer_properties.emit(layer_uid)
		pickable.on_hold = false
		pickable.is_pressed = false
	_double_click_timer = Time.get_unix_time_from_system()

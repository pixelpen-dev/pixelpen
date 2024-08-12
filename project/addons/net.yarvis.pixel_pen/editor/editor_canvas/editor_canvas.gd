@tool
extends Node2D

const VIRTUAL_MOUSE_SCALE = 12

var ShaderIndex := load("res://addons/net.yarvis.pixel_pen/resources/indexed_layer.gdshader")
var TintShader := load("res://addons/net.yarvis.pixel_pen/resources/skinning_tint.gdshader")
var CanvasPaint := load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/canvas_paint.gd")
var MoveTool := load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/move_tool.gd")

@export var tile_node : Node2D
@export var background_canvas : Node2D
@export var onion_skinning : Node2D
@export var layers : Node2D
@export var camera : Camera2D
@export var overlay_hint : Sprite2D
@export var selection_tool_hint : Sprite2D
@export var filter : Sprite2D
@export var cursor_surface : Control
@export var silhouette : bool = false
@export var virtual_mouse : bool = false
@export var show_view_grayscale : bool = false:
	set(v):
		if filter:
			filter.material.set_shader_parameter("grayscale", v)
		show_view_grayscale = v
	get:
		if filter:
			return filter.material.get_shader_parameter("grayscale")
		else:
			return show_view_grayscale

var canvas_paint = CanvasPaint.new(self)

var _queue_update_camera_zoom : bool = false
var _symetric_guid_color_vertical : Color = Color.WHITE
var _symetric_guid_color_horizontal : Color = Color.WHITE
var _on_move_symetric_guid : bool = false
var _on_move_symetric_guid_type : int = -1
var _on_pan_shorcut_mode : bool = false
var _on_pan_shorcut_mode_pressed_moused_position : Vector2
var _touch_0_pos : Vector2
var _touch_0_pressed : bool
var _touch_1_pos : Vector2
var _touch_1_pressed : bool

var virtual_mouse_origin : Vector2
var canvas_size : Vector2i
var virtual_mouse_offset : Vector2
var virtual_pressed : int = 0
var rmb_inject_mode : bool = false


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	PixelPen.state.project_file_changed.connect(func ():
			silhouette = false
			_queue_update_camera_zoom = true
			_create_layers()
			selection_tool_hint.texture = null
			overlay_hint.texture = null
			overlay_hint.position = Vector2.ZERO
			selection_tool_hint.position = Vector2.ZERO
			selection_tool_hint.offset = -Vector2.ONE
			if PixelPen.state.current_project == null:
				canvas_paint.tool = canvas_paint.Tool.new()
				for child in onion_skinning.get_children():
					child.queue_free()
			else:
				_update_onion_skinning()
				(PixelPen.state.current_project as PixelPenProject).get_image() # Force to create first cache image for tile
			_create_tiled()
			
			update_filter_size()
			)
				
	PixelPen.state.layer_items_changed.connect(
			func():
				var project : PixelPenProject = PixelPen.state.current_project as PixelPenProject
				if project != null:
					if MoveTool.mode != MoveTool.Mode.UNKNOWN and not project.multilayer_selected.is_empty():
						if not await canvas_paint.tool._on_request_switch_tool(PixelPenEnum.ToolBox.TOOL_MOVE):
							return
					project.multilayer_selected.clear()
				
				if project.show_tile:
					project.get_image()
					PixelPen.state.thumbnail_changed.emit()
				
				_update_onion_skinning()
				
				_create_layers())
	PixelPen.state.color_picked.connect(func(color_index):
			canvas_paint.tool._index_color = color_index
			_update_shader_layer()
			)
	PixelPen.state.layer_image_changed.connect(_update_layer_image)
	PixelPen.state.layer_visibility_changed.connect(func(layer_uid, visibility):
			var children = layers.get_children()
			for child in children:
				if child.get_meta("layer_uid") == layer_uid:
					child.visible = visibility
					if (PixelPen.state.current_project as PixelPenProject).active_layer_uid == layer_uid:
						canvas_paint.tool._can_draw = visibility
					break
			)
	PixelPen.state.layer_active_changed.connect(func(layer_uid):
			var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).get_index_image(layer_uid)
			if index_image != null:
				canvas_paint.tool._can_draw = index_image.visible
			)
	PixelPen.state.tool_changed.connect(func(grup, type, _grab_active):
			if grup == PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX:
				if canvas_paint.tool.active_tool_type != type:
					if await canvas_paint.tool._on_request_switch_tool(type):
						canvas_paint.tool.active_tool_type = type
					else:
						# cancel switch
						PixelPen.state.tool_changed.emit(PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX, canvas_paint.tool.active_tool_type, true)
			elif grup == PixelPenEnum.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL:
				canvas_paint.tool._on_sub_tool_changed(type)
			)
	PixelPen.state.thumbnail_changed.connect(_create_tiled)
	PixelPen.state.animation_about_to_play.connect(func():
			canvas_paint.on_force_cancel()
			)
	background_canvas.visible = PixelPen.state.current_project != null
	_queue_update_camera_zoom = true


func _process(_delta):
	if not PixelPen.state.need_connection(get_window()):
		return
	if _queue_update_camera_zoom:
		update_camera_zoom()
	queue_redraw()


func _physics_process(_delta):
	update_filter_size()


func update_filter_size():
	if not PixelPen.state.need_connection(get_window()):
		return
	filter.scale = Vector2(1.0, 1.0)
	var new_texture = PlaceholderTexture2D.new()
	var viewport_zero : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * -Vector2.ZERO
	var viewport_size : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * get_viewport_rect().size
	var margin = Vector2(32, 32)
	new_texture.size = viewport_size - viewport_zero + margin
	filter.texture = new_texture
	filter.global_position = viewport_zero - margin * 0.5


func update_camera_zoom():
	if get_viewport_rect().size != Vector2.ZERO:
		if PixelPen.state.current_project != null:
			background_canvas.scale = PixelPen.state.current_project.canvas_size as Vector2
			
		_queue_update_camera_zoom = false
		var camera_scale_factor = get_viewport_rect().size / background_canvas.scale
		if camera_scale_factor.x < camera_scale_factor.y:
			camera.zoom = Vector2.ONE * camera_scale_factor.x * 0.8
		else:
			camera.zoom = Vector2.ONE * camera_scale_factor.y * 0.8
		camera.position = background_canvas.scale * 0.5
		camera.offset = Vector2.ZERO


func viewport_position(global_pos : Vector2) -> Vector2:
	var viewport_zero : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * Vector2.ZERO
	var viewport_size : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * get_viewport_rect().size
	return ((global_pos - viewport_zero) / (viewport_size - viewport_zero)) * get_viewport_rect().size


func zoom(factor : float, pinch : bool = false, center_pinch : Vector2 = Vector2.ZERO):
	var prev_mouse_offset = camera.get_global_transform() * camera.get_local_mouse_position()
	var prev_screen_offset : Vector2
	if pinch:
		prev_mouse_offset = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * center_pinch
		prev_screen_offset = center_pinch
	elif virtual_mouse:
		prev_mouse_offset = virtual_mouse_origin
		prev_screen_offset = viewport_position(virtual_mouse_origin)
	var zoom_scale = factor - 1.0
	camera.zoom += camera.zoom * zoom_scale * 0.5
	var current_mouse_offset = camera.get_global_transform() * camera.get_local_mouse_position()
	if pinch or virtual_mouse:
		current_mouse_offset = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * prev_screen_offset
	camera.offset -= current_mouse_offset - prev_mouse_offset
	if selection_tool_hint.texture != null:
		selection_tool_hint.material.set_shader_parameter("zoom_bias", camera.zoom)
		overlay_hint.material.set_shader_parameter("zoom_bias", camera.zoom)


func pan(offset : Vector2):
	var w = clampf(camera.zoom.length(), 1, 30)
	camera.offset += offset * lerpf(10, 1, w / 30)


func update_background_shader_state():
	background_canvas.material.set_shader_parameter("tile_size", PixelPen.state.userconfig.checker_size  )
	background_canvas.visible = true


func zoom_input(event: InputEvent) -> bool:
	if not PixelPen.state or not PixelPen.state.userconfig:
		return false
	var shorcut := (PixelPen.state.userconfig as UserConfig).shorcuts
	if shorcut.zoom_in and shorcut.zoom_in.matches_event(event):
		zoom(1.1)
		return true
	if shorcut.zoom_out and shorcut.zoom_out.matches_event(event):
		zoom(0.9)
		return true
	return false


func _input(event: InputEvent):
	PixelPen.state.debug_log.emit("Input", event)
	if PixelPen.state.current_project == null:
		return
	
	if event is InputEventKey:
		if event.keycode == KEY_SHIFT and event.is_released():
			canvas_paint.on_shift_pressed(event.is_pressed())
	
	if event and get_viewport_rect().has_point(get_viewport().get_mouse_position()):
		if event is InputEventScreenTouch or event is InputEventScreenDrag:
			_on_gesture(event)
		PixelPen.state.debug_log.emit("Cursor", floor(get_local_mouse_position()))
		if event is InputEventKey:
			if event.keycode == KEY_SHIFT:
				canvas_paint.on_shift_pressed(event.is_pressed())
		if zoom_input(event):
			return
		if event and event is InputEventMagnifyGesture:
			zoom(event.factor)
		elif event and event is InputEventPanGesture:
			pan(event.delta)
		elif event and event is InputEventMouseButton and not PixelPen.state.current_project.animation_is_play:
			var is_hovered_symetric = _is_hovered_symetric_guid()
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
				zoom(0.9)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
				zoom(1.1)
			elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
				_on_pan_shorcut_mode = true
				_on_pan_shorcut_mode_pressed_moused_position = to_local(get_global_transform() * get_global_mouse_position())

			elif event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
				_on_pan_shorcut_mode = false

			elif not _on_pan_shorcut_mode or (_on_pan_shorcut_mode and rmb_inject_mode):
				if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
					if is_hovered_symetric != -1:
						_on_move_symetric_guid = true
						_on_move_symetric_guid_type = is_hovered_symetric
					else:
						canvas_paint.on_mouse_pressed(get_local_mouse_position(), _update_shader_layer)
					
				elif event.is_released()and event.button_index == MOUSE_BUTTON_LEFT:
					if _on_move_symetric_guid:
						_on_move_symetric_guid = false
						_on_move_symetric_guid_type = -1
					else:
						canvas_paint.on_mouse_released(get_local_mouse_position(), _update_shader_layer)

		if event and event is InputEventMouseMotion:
			if _on_pan_shorcut_mode:
				camera.offset -= to_local(get_global_transform() * get_global_mouse_position()) - _on_pan_shorcut_mode_pressed_moused_position

			elif _on_move_symetric_guid:
				if _on_move_symetric_guid_type == 0:
					PixelPen.state.current_project.symetric_guid.x = round(get_local_mouse_position()).x
					PixelPen.state.current_project.symetric_guid.x = clamp(PixelPen.state.current_project.symetric_guid.x, 0, canvas_size.x)
				elif _on_move_symetric_guid_type == 1:
					PixelPen.state.current_project.symetric_guid.y = round(get_local_mouse_position()).y
					PixelPen.state.current_project.symetric_guid.y = clamp(PixelPen.state.current_project.symetric_guid.y, 0, canvas_size.y)
			else:
				canvas_paint.on_mouse_motion(get_local_mouse_position(), event.relative, _update_shader_layer)


func _on_gesture(event : InputEvent):
	if event is InputEventScreenTouch:
		if event.index == 0:
			if event.is_pressed():
				_touch_0_pressed = true
				_touch_0_pos = event.position
			elif event.is_released():
				_touch_0_pressed = false
		elif event.index == 1:
			if event.is_pressed():
				_touch_1_pressed = true
				_touch_1_pos = event.position
			elif event.is_released():
				_touch_1_pressed = false
	elif event is InputEventScreenDrag and _touch_0_pressed and _touch_1_pressed:
		var prev_distance : float = _touch_0_pos.distance_to(_touch_1_pos)
		if event.index == 0:
			_touch_0_pos = event.position
		elif event.index == 1:
			_touch_1_pos = event.position
		var center : Vector2 = _touch_0_pos + ((_touch_1_pos - _touch_0_pos) / 2.0)
		var offset : float = prev_distance - _touch_0_pos.distance_to(_touch_1_pos)
		var offset_scale = 1.0 - (offset / prev_distance)
		zoom(offset_scale, true, center)


func _draw():
	if get_window().has_focus() and PixelPen.state.current_project != null:
		canvas_paint.on_draw_hint(get_local_mouse_position())
		if get_viewport_rect().has_point(get_viewport().get_mouse_position()):
			if PixelPen.state.current_project.animation_is_play:
				canvas_paint.tool.draw_invalid_cursor(get_local_mouse_position())
			else:
				var type_hovered = _is_hovered_symetric_guid()
				if type_hovered == -1:
					_symetric_guid_color_vertical.a = 1
					_symetric_guid_color_horizontal.a = 1
					if _on_pan_shorcut_mode:
						if rmb_inject_mode:
							canvas_paint.tool.draw_pan_cursor(virtual_mouse_origin)
							cursor_surface.tool_texture = canvas_paint.tool.pan_texture
						else:
							canvas_paint.tool.draw_pan_cursor(get_local_mouse_position())
							cursor_surface.tool_texture = canvas_paint.tool.pan_texture
					else:
						canvas_paint.on_draw_cursor(get_local_mouse_position())
						cursor_surface.tool_texture = canvas_paint.on_get_tool_texture()
				elif type_hovered == 0:
					_symetric_guid_color_vertical.a = 0.75
					canvas_paint.tool.draw_plus_cursor(get_local_mouse_position(), 15)
				elif type_hovered == 1:
					_symetric_guid_color_horizontal.a = 0.75
					canvas_paint.tool.draw_plus_cursor(get_local_mouse_position(), 15)
	if PixelPen.state.current_project != null and PixelPen.state.current_project.show_grid :
		_draw_grid(Vector2i.ONE, 0.07)
		_draw_grid(PixelPen.state.userconfig.default_grid_size, 0.075)
		_draw_grid(PixelPen.state.userconfig.default_grid_size * 2, 0.1)
		_draw_grid(PixelPen.state.userconfig.default_grid_size * 4, 0.125)
	if PixelPen.state.current_project != null:
		_draw_symetric_guid()
	if PixelPen.state.current_project != null and PixelPen.state.current_project.show_tile:
		draw_rect(Rect2i(Vector2.ZERO, canvas_size), Color.MAGENTA, false)
	
	if virtual_mouse:
		var l_scale : float = (get_viewport_transform().affine_inverse() * VIRTUAL_MOUSE_SCALE).x.x
		if not get_viewport_rect().has_point(get_viewport().get_mouse_position()):
			draw_line(virtual_mouse_origin - Vector2(l_scale, 0), virtual_mouse_origin + Vector2(l_scale, 0), Color.WHITE)
			draw_line(virtual_mouse_origin - Vector2(0, l_scale), virtual_mouse_origin + Vector2(0, l_scale), Color.WHITE)
		draw_circle(virtual_mouse_origin + Vector2(0, l_scale * 10), l_scale * 6, Color(1, 1, 1, 0.2))
		draw_arc(virtual_mouse_origin + Vector2(0, l_scale * 10), l_scale * 6, 0, TAU, 100, Color.WHITE)
		var from : Vector2 = virtual_mouse_origin + Vector2(l_scale * -6, l_scale * 10)
		var to : Vector2 = virtual_mouse_origin + Vector2(l_scale * 6, l_scale * 10)
		draw_line(from, to, Color.WHITE)
		draw_line(virtual_mouse_origin + Vector2(0, l_scale * 4), virtual_mouse_origin + Vector2(0, l_scale * 10), Color.WHITE)

## button { -1:body, 0:LMB, 1:RMB, 2:ALL }
func is_hover_virtual_mouse_body(mouse_pos : Vector2, button : int = -1) -> bool:
	assert( button >= -1 and button <= 2, "ERR: is_hover_virtual_mouse_body:button")
	var l_scale : float = (get_viewport_transform().affine_inverse() * VIRTUAL_MOUSE_SCALE).x.x
	var center : Vector2 = virtual_mouse_origin + Vector2(0, l_scale * 10)
	if button == -1:
		return mouse_pos.distance_to(center) < l_scale * 6 and center.y <= mouse_pos.y
	if button == 0:
		return mouse_pos.distance_to(center) < l_scale * 6 and mouse_pos.y < center.y and mouse_pos.x < center.x
	if button == 1:
		return mouse_pos.distance_to(center) < l_scale * 6 and mouse_pos.y < center.y and mouse_pos.x >= center.x
	if button == 2:
		return mouse_pos.distance_to(center) < l_scale * 6
	return false


func center_virtual_mouse():
	virtual_mouse_origin = camera.position + camera.offset


func drag_virtual_mouse(mouse_pos : Vector2):
	virtual_mouse_origin = mouse_pos - virtual_mouse_offset


func reset_virtual_mouse_position(mouse_pos : Vector2):
	var l_scale : float = (get_viewport_transform().affine_inverse() * VIRTUAL_MOUSE_SCALE).x.x
	virtual_mouse_origin = mouse_pos - Vector2(0, l_scale * 13)
	start_drag_virtual_mouse_from(mouse_pos)


func start_drag_virtual_mouse_from(mouse_pos : Vector2):
	virtual_mouse_offset = mouse_pos - virtual_mouse_origin


func _draw_grid(grid_size : Vector2i, alpha : float):
	var color = Color(1, 1, 1, alpha)
	for x in range(1 + canvas_size.x / grid_size.x):
		draw_line(Vector2(x * grid_size.x, 0), Vector2(x * grid_size.x, canvas_size.y), color)
	for y in range(1 + canvas_size.y / grid_size.y):
		draw_line(Vector2(0, y * grid_size.y), Vector2(canvas_size.x, y * grid_size.y), color)


func _draw_symetric_guid():
	if get_viewport_transform().affine_inverse().origin == Vector2(-1, -1):
		return
	var ca : float = 0.5
	
	var viewport_zero : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * Vector2.ZERO
	var viewport_size : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * get_viewport_rect().size
	var radius_size : float = (get_viewport_transform().affine_inverse() * 10.0).x.x
	if PixelPen.state.current_project.show_symetric_vertical:
		var vertical_x_pos = floor(PixelPen.state.current_project.symetric_guid.x)
		draw_line(Vector2(vertical_x_pos, viewport_zero.y + radius_size), Vector2(vertical_x_pos, viewport_size.y), Color(1, 1, 1, ca))
		draw_circle(Vector2(vertical_x_pos, viewport_zero.y), radius_size, _symetric_guid_color_vertical)
	if PixelPen.state.current_project.show_symetric_horizontal:
		var horizontal_y_pos = floor(PixelPen.state.current_project.symetric_guid.y)
		draw_line(Vector2(viewport_zero.x + radius_size, horizontal_y_pos), Vector2(viewport_size.x, horizontal_y_pos), Color(1, 1, 1, ca))
		draw_circle(Vector2(viewport_zero.x, horizontal_y_pos), radius_size, _symetric_guid_color_horizontal)


func _is_hovered_symetric_guid() -> int:
	var viewport_zero : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * Vector2.ZERO
	var viewport_size : Vector2 = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * get_viewport_rect().size
	var radius_size : float = (get_viewport_transform().affine_inverse() * 10.0).x.x
	
	var guid_v_pos = Vector2(floor(PixelPen.state.current_project.symetric_guid.x), viewport_zero.y)
	var guid_h_pos = Vector2(viewport_zero.x, floor(PixelPen.state.current_project.symetric_guid.y))
	if get_local_mouse_position().distance_to(guid_v_pos) < radius_size * 2:
		return 0
	elif get_local_mouse_position().distance_to(guid_h_pos) < radius_size * 2:
		return 1
	return -1


func _update_shader_layer():
	var palette : IndexedPalette = (PixelPen.state.current_project as PixelPenProject).palette
	var dirty_children = layers.get_children()
	var children : Array[Node] = []
	for child in dirty_children:
		if not child.is_queued_for_deletion():
			children.push_back(child)
	for i in children.size():
		var layer : Sprite2D = children[i]
		var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).get_index_image(layer.get_meta("layer_uid"))
		if index_image != null:
			var mat : ShaderMaterial = layer.material
			var layer_size : Vector2i = index_image.size
			mat.set_shader_parameter("image_size", layer_size)
			mat.set_shader_parameter("index_color", palette.get_color_index_texture())
			mat.set_shader_parameter("color_map", index_image.get_color_map_texture())
			mat.set_shader_parameter("silhouette", 1.0 if index_image.silhouette else 0.0)
			silhouette = silhouette or index_image.silhouette


func _create_layers():
	for child in layers.get_children():
		child.queue_free()
	if PixelPen.state.current_project == null or (PixelPen.state.current_project as PixelPenProject).active_frame == null:
		background_canvas.visible = false
		return
	update_background_shader_state()
	var size = (PixelPen.state.current_project as PixelPenProject).active_frame.layers.size()
	canvas_size = (PixelPen.state.current_project as PixelPenProject).canvas_size
	for i in range(size):
		_create_layer(i)
	_update_shader_layer()


func _create_layer(index : int):
	var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_frame.layers[index]
	var sprite = Sprite2D.new()
	sprite.texture = PlaceholderTexture2D.new()
	sprite.centered = false
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = ShaderIndex
	sprite.scale = index_image.size as Vector2
	sprite.visible = index_image.visible
	sprite.set_meta("layer_uid", index_image.layer_uid)
	layers.add_child(sprite)


func _update_layer_image(layer_uid : Vector3i):
	var children = layers.get_children()
	for layer in children:
		if layer.get_meta("layer_uid") == layer_uid:
			var index_image : IndexedColorImage = PixelPen.state.current_project.get_index_image(layer_uid)
			if index_image == null:
				return
			var palette : IndexedPalette = (PixelPen.state.current_project as PixelPenProject).palette
			var mat : ShaderMaterial = layer.material
			var layer_size : Vector2i = index_image.size
			mat.set_shader_parameter("image_size", layer_size)
			mat.set_shader_parameter("index_color", palette.get_color_index_texture())
			mat.set_shader_parameter("color_map", index_image.get_color_map_texture())
			return

func _create_tiled():
	for child in tile_node.get_children():
		child.queue_free()
	if PixelPen.state.current_project == null:
		return
	if not PixelPen.state.current_project.show_tile:
		return
	var image : Image = PixelPen.state.current_project.cache_thumbnail
	if image == null or image.is_empty():
		return
	var texture = ImageTexture.create_from_image(image)
	for x in range(-2, 3):
		for y in range(-2, 3):
			if x == 0 and y == 0:
				continue
			var sprite = Sprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.texture = texture
			sprite.centered = false
			sprite.position = texture.get_size() * Vector2(x, y)
			tile_node.add_child(sprite)


func _update_onion_skinning():
	for child in onion_skinning.get_children():
		child.queue_free()
	var project : PixelPenProject = PixelPen.state.current_project as PixelPenProject
	if project.animation_is_play or not project.onion_skinning:
		return
	project.update_onion_skin_images()
	var prev_color : Color = PixelPen.state.userconfig.onion_skin_tint_previous
	prev_color.a = PixelPen.state.userconfig.onion_skin_tint_alpha
	var next_color : Color = PixelPen.state.userconfig.onion_skin_tint_next
	next_color.a = PixelPen.state.userconfig.onion_skin_tint_alpha
	var color_alpha_step : float = PixelPen.state.userconfig.onion_skin_tint_alpha / PixelPen.state.userconfig.onion_skin_total
	for prev_image in project.animation_prev_skinning_image:
		var sprite : Sprite2D = Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.texture = ImageTexture.create_from_image(prev_image)
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = TintShader
		sprite.material.set_shader_parameter("tint", prev_color)
		onion_skinning.add_child(sprite)
		prev_color.a -= color_alpha_step
	for next_image in project.animation_next_skinning_image:
		var sprite : Sprite2D = Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.texture = ImageTexture.create_from_image(next_image)
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = TintShader
		sprite.material.set_shader_parameter("tint", next_color)
		onion_skinning.add_child(sprite)
		next_color.a -= color_alpha_step

@tool
extends Control


var ShaderIndex := load("res://addons/net.yarvis.pixel_pen/resources/indexed_layer.gdshader")

@export var wrapper : Node2D
@export var camera : Camera2D
@export var layers : Node2D
@export var sample_layers : Node2D
@export var checker_sizing : AspectRatioContainer
@export var viewport_container : SubViewportContainer
@export var front_control : Control
@export var use_canvas_frame : bool = false
@export var show_cache_frame : bool = false
@export_range(1, 100) var stretch_shrink : int = 1: 
	set(v):
		stretch_shrink = v
		viewport_container.stretch_shrink = stretch_shrink

var _frame : Frame:
	get:
		if PixelPen.state.current_project != null and use_canvas_frame:
			return PixelPen.state.current_project.active_frame
		return _frame
var _canvas_size : Vector2i:
	set(v):
		_canvas_size = v
		checker_sizing.ratio = v.x as float / v.y as float
var _queue_update_camera_zoom = false


func show_frame(frame : Frame):
	_frame = frame


func clear_layer():
	for child in layers.get_children():
		child.queue_free()
	for child in sample_layers.get_children():
		child.queue_free()


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	viewport_container.stretch_shrink = stretch_shrink
	PixelPen.state.project_file_changed.connect(func ():
			if PixelPen.state.current_project != null:
				_queue_update_camera_zoom = true
				_create_layers()
				if show_cache_frame and PixelPen.state.current_project.use_sample:
					_create_samples()
			else:
				for child in layers.get_children():
					child.queue_free()
				for child in sample_layers.get_children():
					child.queue_free()
			)
	PixelPen.state.layer_items_changed.connect(func():
			if PixelPen.state.current_project.animation_is_play:
				return
			_create_layers()
			if show_cache_frame and PixelPen.state.current_project.use_sample:
				_create_samples()
			)
	PixelPen.state.color_picked.connect(func(color_index):
			_update_shader_layer()
			if show_cache_frame and PixelPen.state.current_project.use_sample:
				_update_shader_sample()
			)
	PixelPen.state.layer_image_changed.connect(func(layer_uid : Vector3i):
			if PixelPen.state.current_project.animation_is_play:
				return
			_update_layer_image(layer_uid)
			if show_cache_frame and PixelPen.state.current_project.use_sample:
				_update_sample_image(layer_uid)
			)
	PixelPen.state.layer_visibility_changed.connect(func(layer_uid, visibility):
			var children = layers.get_children()
			for child in children:
				if child.get_meta("layer_uid") == layer_uid:
					child.visible = visibility
					break
			if show_cache_frame and PixelPen.state.current_project.use_sample:
				var children_sample = sample_layers.get_children()
				for child in children_sample:
					if child.get_meta("layer_uid") == layer_uid:
						child.visible = visibility
						break
			)


func _process(_delta):
	if _queue_update_camera_zoom:
		update_camera_zoom()


func update_camera_zoom():
	if wrapper.get_viewport_rect().size != Vector2.ZERO:
		var camera_scale : Vector2
		if PixelPen.state.current_project != null:
			if show_cache_frame and PixelPen.state.current_project.use_sample:
				# NOTE: break compat after typo `_cache_canvs_size`
				#camera_scale = PixelPen.state.current_project._cache_canvs_size as Vector2
				camera_scale = PixelPen.state.current_project._cache_pool_frames[0].layers[0].size as Vector2
			else:
				camera_scale = PixelPen.state.current_project.canvas_size as Vector2
		_queue_update_camera_zoom = false
		var camera_scale_factor = wrapper.get_viewport_rect().size / camera_scale
		if camera_scale_factor.x < camera_scale_factor.y:
			camera.zoom = Vector2.ONE * camera_scale_factor.x #* 0.8
		else:
			camera.zoom = Vector2.ONE * camera_scale_factor.y #* 0.8
		camera.position = camera_scale * 0.5
		camera.offset = Vector2.ZERO


func _update_shader_layer():
	var palette : IndexedPalette = (PixelPen.state.current_project as PixelPenProject).palette
	var dirty_children = layers.get_children()
	var children : Array[Node] = []
	for child in dirty_children:
		if not child.is_queued_for_deletion():
			children.push_back(child)
	for i in children.size():
		var layer : Sprite2D = children[i]
		var use_cache : bool = show_cache_frame and PixelPen.state.current_project.use_sample
		var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).find_index_image(layer.get_meta("layer_uid"), use_cache)
		if index_image != null:
			var mat : ShaderMaterial = layer.material
			var layer_size : Vector2i = index_image.size
			mat.set_shader_parameter("image_size", layer_size)
			mat.set_shader_parameter("index_color", palette.get_color_index_texture())
			mat.set_shader_parameter("color_map", index_image.get_color_map_texture())
			mat.set_shader_parameter("silhouette", 0.0)


func _update_shader_sample():
	var palette : IndexedPalette = (PixelPen.state.current_project as PixelPenProject).palette
	var dirty_children = sample_layers.get_children()
	var children : Array[Node] = []
	for child in dirty_children:
		if not child.is_queued_for_deletion():
			children.push_back(child)
	for i in children.size():
		var layer : Sprite2D = children[i]
		var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).find_index_image(layer.get_meta("layer_uid"))
		if index_image != null:
			var mat : ShaderMaterial = layer.material
			var layer_size : Vector2i = index_image.size
			mat.set_shader_parameter("image_size", layer_size)
			mat.set_shader_parameter("index_color", palette.get_color_index_texture())
			mat.set_shader_parameter("color_map", index_image.get_color_map_texture())
			mat.set_shader_parameter("silhouette", 0.0)


func _create_layers():
	for child in layers.get_children():
		child.queue_free()
	if PixelPen.state.current_project == null or _frame == null:
		checker_sizing.visible = false
		return
	checker_sizing.visible = true
	var l_size = _frame.layers.size()
	_canvas_size = (PixelPen.state.current_project as PixelPenProject).canvas_size
	if show_cache_frame and PixelPen.state.current_project.use_sample:
		l_size = (PixelPen.state.current_project as PixelPenProject).get_pool_frame(_frame.frame_uid, true).layers.size()
		# NOTE: break compat after typo `_cache_canvs_size`
		#_canvas_size = PixelPen.state.current_project._cache_canvs_size
		_canvas_size = PixelPen.state.current_project._cache_pool_frames[0].layers[0].size
	for i in range(l_size):
		_create_layer(i)
	_update_shader_layer()


func _create_samples():
	for child in sample_layers.get_children():
		child.queue_free()
	if PixelPen.state.current_project == null:
		return
	var l_size = _frame.layers.size()
	for i in range(l_size):
		_create_sample(i)
	_update_shader_sample()


func _create_layer(index : int):
	var index_image : IndexedColorImage
	if show_cache_frame and PixelPen.state.current_project.use_sample:
		index_image = (PixelPen.state.current_project as PixelPenProject).get_pool_frame(_frame.frame_uid, true).layers[index]
	else:
		index_image = _frame.layers[index]
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
			var index_image : IndexedColorImage
			if show_cache_frame and PixelPen.state.current_project.use_sample:
				index_image = (PixelPen.state.current_project as PixelPenProject).get_pool_frame(_frame.frame_uid, true).find_layer(layer_uid)
			else:
				index_image = _frame.find_layer(layer_uid)
			var palette : IndexedPalette = (PixelPen.state.current_project as PixelPenProject).palette
			var mat : ShaderMaterial = layer.material
			var layer_size : Vector2i = index_image.size
			mat.set_shader_parameter("image_size", layer_size)
			mat.set_shader_parameter("index_color", palette.get_color_index_texture())
			mat.set_shader_parameter("color_map", index_image.get_color_map_texture())
			return


func _update_sample_image(layer_uid : Vector3i):
	var children = sample_layers.get_children()
	for layer in children:
		if layer.get_meta("layer_uid") == layer_uid:
			var index_image : IndexedColorImage = _frame.find_layer(layer_uid)
			if index_image == null:
				return
			var palette : IndexedPalette = (PixelPen.state.current_project as PixelPenProject).palette
			var mat : ShaderMaterial = layer.material
			var layer_size : Vector2i = index_image.size
			mat.set_shader_parameter("image_size", layer_size)
			mat.set_shader_parameter("index_color", palette.get_color_index_texture())
			mat.set_shader_parameter("color_map", index_image.get_color_map_texture())
			return


func _create_sample(index : int):
	var index_image : IndexedColorImage = _frame.layers[index]
	var sprite = Sprite2D.new()
	sprite.texture = PlaceholderTexture2D.new()
	sprite.centered = false
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = ShaderIndex
	sprite.scale = index_image.size as Vector2
	sprite.visible = index_image.visible
	sprite.set_meta("layer_uid", index_image.layer_uid)
	sample_layers.add_child(sprite)


func _on_sub_viewport_container_resized():
	if not PixelPen.state.need_connection(get_window()) or PixelPen.state.current_project == null:
		return
	_queue_update_camera_zoom = true
	_create_layers()
	if show_cache_frame and PixelPen.state.current_project.use_sample:
		_create_samples()

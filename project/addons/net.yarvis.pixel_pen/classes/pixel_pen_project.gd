@tool
## Resource or Project FILE for every PixelPenProject
class_name PixelPenProject
extends Resource

# Increase this number if @export property change
const COMPATIBILITY_NUMBER : int = 3

@export var compatibility_version : int
@export var project_name : String
@export var file_path : String
@export var last_export_file_path : String
@export var canvas_size : Vector2i

@export var palette : IndexedPalette

@export var pool_frames : Array[Frame]
@export var canvas_pool_frame_uid : Vector3i

@export var show_timeline : bool = false
@export var animation_timeline : Array[AnimationCell]
@export var animation_frame_index : int = -1
@export var animation_fps : float = 30
@export var animation_loop : bool = true
@export var onion_skinning : bool = false

## Used by internal for auto name layer
@export var layer_index_counter : int
@export var active_layer_uid : Vector3i
@export var use_sample : bool = false
@export var _sample_offset : Vector2i
@export var _cache_canvas_size : Vector2i
@export var _cache_pool_frames : Array[Frame]
@export var _cache_canvas_pool_frame_uid : Vector3i

@export var show_grid : bool = false
@export var show_tile : bool = false
@export var show_preview : bool = true
@export var show_symetric_vertical : bool = false
@export var show_symetric_horizontal : bool = false
@export var symetric_guid : Vector2
@export var background_color : BackgroundColor = BackgroundColor.TRANSPARENT

@export var uid_counter : int

var paint : PixelPenImage = PixelPenImage.new()
var brush_index : int = -1

var animation_is_play : bool = false
var skinning_frame_index : int = -1 # Record reference frame
var animation_prev_skinning_image : Array[Image] = []
var animation_next_skinning_image : Array[Image] = []

var active_frame : Frame:
	get:
		return get_pool_frame(canvas_pool_frame_uid)
var active_layer : IndexedColorImage:
	get:
		return get_index_image(active_layer_uid)
var is_saved : bool = false

var undo_redo : UndoRedoManager

var cache_copied_colormap : IndexedColorImage
var cache_thumbnail : Image
var multilayer_selected : Array[Vector3i] 

var _cache_undo_redo : UndoRedoManager

enum ProjectMode{
	BASE = 0,
	SAMPLE = 1
}

enum BackgroundColor{
	TRANSPARENT = 0,
	WHITE,
	GREY,
	BLACK
}


func initialized(p_size : Vector2i, p_name : String = "Untitled", p_file_path : String = "", one_layer : bool = true):
	compatibility_version = COMPATIBILITY_NUMBER
	layer_index_counter = 0
	project_name = p_name
	canvas_size = p_size
	animation_fps = PixelPen.state.userconfig.default_animation_fps
	symetric_guid = canvas_size * 0.5
	palette = IndexedPalette.new()
	palette.set_color_index_preset()
	sync_gui_palette()
	pool_frames = [Frame.create(get_uid())]
	canvas_pool_frame_uid = pool_frames[0].frame_uid
	var cell : AnimationCell = AnimationCell.create(get_uid())
	cell.frame = pool_frames[0]
	animation_timeline.push_back(cell)
	animation_frame_index = 0
	if one_layer:
		add_layer()
		active_layer_uid = active_frame.layers[0].layer_uid


func get_uid():
	uid_counter += 1
	var uid = Vector3i(uid_counter, randi(), Time.get_unix_time_from_system() as int)
	if uid == Vector3i.ZERO:
		return get_uid()
	return uid


func get_json() -> String:
	var pool_frames_data : Array = []
	for frame in pool_frames:
		pool_frames_data.push_back(frame.get_data())
	var _cache_pool_frames_data : Array = []
	for frame in _cache_pool_frames:
		_cache_pool_frames_data.push_back(frame.get_data())
	var arr_animation_timeline : Array = []
	for cell in animation_timeline:
		arr_animation_timeline.push_back(cell.get_data())
	var metadata : Dictionary = {
		"compatibility_version" : compatibility_version,
		"project_name" : project_name,
		"file_path" : file_path,
		"last_export_file_path" : last_export_file_path,
		"canvas_size" : var_to_str(canvas_size),
		"palette" : palette.get_data(),
		"pool_frames" : pool_frames_data,
		"canvas_pool_frame_uid" : var_to_str(canvas_pool_frame_uid),
		"show_timeline" : show_timeline,
		"animation_timeline" : arr_animation_timeline,
		"animation_frame_index" : animation_frame_index,
		"animation_fps" : animation_fps,
		"animation_loop" : animation_loop,
		"onion_skinning" : onion_skinning,
		"layer_index_counter" : layer_index_counter,
		"active_layer_uid" : var_to_str(active_layer_uid),
		"use_sample" : use_sample,
		"_sample_offset" : var_to_str(_sample_offset),
		"_cache_canvas_size" : var_to_str(_cache_canvas_size),
		"_cache_pool_frames" : _cache_pool_frames_data,
		"_cache_canvas_pool_frame_uid" : var_to_str(_cache_canvas_pool_frame_uid),
		"show_grid" : show_grid,
		"show_tile" : show_tile,
		"show_preview" : show_preview,
		"show_symetric_vertical" : show_symetric_vertical,
		"show_symetric_horizontal" : show_symetric_horizontal,
		"symetric_guid" : var_to_str(symetric_guid),
		"background_color" : var_to_str(background_color),
		"uid_counter" : uid_counter
	}
	var json := JSON.new()
	return json.stringify(metadata)


func from_json(json_string : String) -> Error:
	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		return err

	var json_data : Dictionary = json.data as Dictionary
	if json_data.has("compatibility_version"):
		compatibility_version = json_data["compatibility_version"] as int
	else:
		return FAILED
	if json_data.has("project_name"):
		project_name = json_data["project_name"] as String
	else:
		return FAILED
	if json_data.has("file_path"):
		file_path = json_data["file_path"] as String
	else:
		return FAILED
	if json_data.has("last_export_file_path"):
		last_export_file_path = json_data["last_export_file_path"] as String
	else:
		return FAILED
	if json_data.has("canvas_size"):
		canvas_size = str_to_var(json_data["canvas_size"]) as Vector2i
	else:
		return FAILED
	if json_data.has("palette"):
		palette = IndexedPalette.new()
		if palette.from_data(json_data["palette"]) != OK:
			return FAILED
	else:
		return FAILED
	if json_data.has("pool_frames"):
		pool_frames.clear()
		var pool_frames_data : Array = json_data["pool_frames"] as Array
		for data in pool_frames_data:
			var frame := Frame.new()
			var frame_err := frame.from_data(data)
			if frame_err != OK:
				return FAILED
			pool_frames.push_back(frame)

	else:
		return FAILED
	if json_data.has("canvas_pool_frame_uid"):
		canvas_pool_frame_uid = str_to_var(json_data["canvas_pool_frame_uid"]) as Vector3i
	else:
		return FAILED
	if json_data.has("show_timeline"):
		show_timeline = json_data["show_timeline"] as bool
	else:
		return FAILED
	if json_data.has("animation_frame_index"):
		animation_frame_index = json_data["animation_frame_index"] as int
	else:
		return FAILED
	if json_data.has("animation_fps"):
		animation_fps = json_data["animation_fps"] as float
	else:
		return FAILED
	if json_data.has("animation_loop"):
		animation_loop = json_data["animation_loop"] as bool
	else:
		return FAILED
	if json_data.has("onion_skinning"):
		onion_skinning = json_data["onion_skinning"] as bool
	else:
		return FAILED
	if json_data.has("layer_index_counter"):
		layer_index_counter = json_data["layer_index_counter"] as int
	else:
		return FAILED
	if json_data.has("active_layer_uid"):
		active_layer_uid = str_to_var(json_data["active_layer_uid"]) as Vector3i
	else:
		return FAILED
	if json_data.has("use_sample"):
		use_sample = json_data["use_sample"] as bool
	else:
		return FAILED
	if json_data.has("_sample_offset"):
		_sample_offset = str_to_var(json_data["_sample_offset"]) as Vector2i
	else:
		return FAILED
	if json_data.has("_cache_canvas_size"):
		_cache_canvas_size = str_to_var(json_data["_cache_canvas_size"]) as Vector2i
	else:
		return FAILED
	if json_data.has("_cache_pool_frames"):
		_cache_pool_frames.clear()
		var pool_frames_data : Array = json_data["_cache_pool_frames"] as Array
		for data in pool_frames_data:
			var frame := Frame.new()
			var frame_err := frame.from_data(data)
			if frame_err != OK:
				return FAILED
			_cache_pool_frames.push_back(frame)
	else:
		return FAILED
	if json_data.has("animation_timeline"):
		animation_timeline.clear()
		var arr_animation_timeline : Array = json_data["animation_timeline"] as Array
		for data in arr_animation_timeline:
			var cell := AnimationCell.new()
			var cell_err := cell.from_data(data, self)
			if cell_err != OK:
				return FAILED
			animation_timeline.push_back(cell)
	else:
		return FAILED
	if json_data.has("_cache_canvas_pool_frame_uid"):
		_cache_canvas_pool_frame_uid = str_to_var(json_data["_cache_canvas_pool_frame_uid"]) as Vector3i
	else:
		return FAILED
	if json_data.has("show_grid"):
		show_grid = json_data["show_grid"] as bool
	else:
		return FAILED
	if json_data.has("show_tile"):
		show_tile = json_data["show_tile"] as bool
	else:
		return FAILED
	if json_data.has("show_preview"):
		show_preview = json_data["show_preview"] as bool
	else:
		return FAILED
	if json_data.has("show_symetric_vertical"):
		show_symetric_vertical = json_data["show_symetric_vertical"] as bool
	else:
		return FAILED
	if json_data.has("show_symetric_horizontal"):
		show_symetric_horizontal = json_data["show_symetric_horizontal"] as bool
	else:
		return FAILED
	if json_data.has("symetric_guid"):
		symetric_guid = str_to_var(json_data["symetric_guid"]) as Vector2
	else:
		return FAILED
	if json_data.has("background_color"):
		background_color = str_to_var(json_data["background_color"]) as BackgroundColor
	else:
		return FAILED
	if json_data.has("uid_counter"):
		uid_counter = json_data["uid_counter"] as int
	else:
		return FAILED
	return OK


func sync_gui_palette(ok_save : bool = false):
	if palette.is_gui_valid():
		var sync : bool = palette.is_gui_order_equal_to_color_index_order()
		if not sync:
			var new_palette : PackedColorArray = [Color.TRANSPARENT]
			for idx in palette.grid_color_index:
				new_palette.push_back(palette.color_index[idx])
			for frame in pool_frames:
				for layer in frame.layers:
					PixelPenCPP.swap_palette(palette.color_index, new_palette, layer.colormap)
			if use_sample:
				for frame in _cache_pool_frames:
					for layer in frame.layers:
						PixelPenCPP.swap_palette(palette.color_index, new_palette, layer.colormap)
			palette.color_index = new_palette
			palette.grid_sync_to_palette()
			if ok_save:
				ResourceSaver.save(self, file_path)
			else:
				is_saved = false
	else:
		palette.grid_sync_to_palette()


func set_mode(mode : ProjectMode, mask : Image = null):
	if mode == ProjectMode.BASE and use_sample:
		var frame := get_pool_frame(_cache_canvas_pool_frame_uid, true)
		for layer_i in range(frame.layers.size()):
			var cache : IndexedColorImage = frame.layers[layer_i]
			var sample : IndexedColorImage = find_index_image(cache.layer_uid)
			if sample != null:
				cache.colormap.blit_rect(sample.colormap, Rect2i(Vector2i.ZERO, sample.colormap.get_size()), _sample_offset)
		use_sample = false

		# NOTE: break compat after typo `_cache_canvs_size`
		#canvas_size = _cache_canvs_size 
		canvas_size = _cache_pool_frames[0].layers[0].size

		pool_frames = _cache_pool_frames
		canvas_pool_frame_uid = _cache_canvas_pool_frame_uid
		undo_redo = _cache_undo_redo
	elif mode == ProjectMode.SAMPLE and mask != null and not use_sample:
		use_sample = true
		_cache_canvas_size = canvas_size
		_cache_pool_frames = pool_frames#get_frames_duplicate(false)
		_cache_canvas_pool_frame_uid = canvas_pool_frame_uid
		_cache_undo_redo = undo_redo
		var region : Rect2i = PixelPenCPP.get_mask_used_rect(mask)
		canvas_size = region.size
		_sample_offset = region.position
		var new_pool_frames : Array[Frame] = [active_frame.get_duplicate(false)]
		for layer_i in range(new_pool_frames[0].layers.size()):
			var new_layer : IndexedColorImage = new_pool_frames[0].layers[layer_i].get_duplicate(false)
			new_layer.size = canvas_size
			new_layer.colormap = new_pool_frames[0].layers[layer_i].colormap.get_region(region)
			new_pool_frames[0].layers[layer_i] = new_layer
		pool_frames = new_pool_frames
		undo_redo = UndoRedoManager.new()
	PixelPen.state.edit_mode_changed.emit(mode)


func resize_canvas(new_size : Vector2i, anchor : PixelPenEnum.ResizeAnchor):
	canvas_size = new_size
	for frame in pool_frames:
		for layer in frame.layers:
			layer.resize(new_size, anchor)
	cache_copied_colormap = null
	symetric_guid = canvas_size * 0.5
	show_symetric_vertical = false
	show_symetric_horizontal = false


func break_history():
	undo_redo.break_history()
	if not (undo_redo.history_breaked as Signal).is_connected(clean_invisible_color):
		undo_redo.history_breaked.connect(clean_invisible_color)


func unbreak_history():
	undo_redo.unbreak_history()


func undo():
	undo_redo.undo()


func redo():
	undo_redo.redo()


func create_undo_layer_and_palette(name : String, callable : Callable):
	undo_redo.create_action(name)
	undo_redo.add_undo_property(active_frame, "layers", active_frame.get_layer_duplicate(false))
	undo_redo.add_undo_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_undo_method(callable)


func create_redo_layer_and_palette(callable : Callable):
	undo_redo.add_do_property(active_frame, "layers", active_frame.get_layer_duplicate(false))
	undo_redo.add_do_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_do_method(callable)
	undo_redo.commit_action()


func create_undo_layers(name : String, callable : Callable):
	undo_redo.create_action(name)
	undo_redo.add_undo_property(active_frame, "layers", active_frame.get_layer_duplicate(false))
	undo_redo.add_undo_method(callable)


func create_redo_layers(callable : Callable):
	undo_redo.add_do_property(active_frame, "layers", active_frame.get_layer_duplicate(false))
	undo_redo.add_do_method(callable)
	undo_redo.commit_action()


func create_undo_layer(name : String, layer_uid : Vector3i , callable : Callable = Callable(), create_action : bool = true):
	var image : IndexedColorImage = find_index_image(layer_uid)
	assert(image != null, "Error: IndexedColorImage != null -> fail")
	if create_action:
		undo_redo.create_action(name)
	undo_redo.add_undo_property(image, "colormap", image.colormap.duplicate())
	undo_redo.add_undo_method(callable)


func create_redo_layer(layer_uid : Vector3i, callable : Callable = Callable(), commit_action : bool = true):
	var image : IndexedColorImage = find_index_image(layer_uid)
	assert(image != null, "Error: IndexedColorImage != null -> fail")
	undo_redo.add_do_property(image, "colormap", image.colormap.duplicate())
	undo_redo.add_do_method(callable)
	if commit_action:
		undo_redo.commit_action()


func create_undo_palette(name : String, callable : Callable):
	undo_redo.create_action(name)
	undo_redo.add_undo_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_undo_method(callable)


func create_redo_palette(callable : Callable):
	undo_redo.add_do_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_do_method(callable)
	undo_redo.commit_action()


func create_undo_palette_gui(name : String, callable : Callable):
	undo_redo.create_action(name)
	undo_redo.add_undo_property(palette, "grid_color_index", palette.grid_color_index.duplicate())
	undo_redo.add_undo_method(callable)


func create_redo_palette_gui(callable : Callable):
	undo_redo.add_do_property(palette, "grid_color_index", palette.grid_color_index.duplicate())
	undo_redo.add_do_method(callable)
	undo_redo.commit_action()


func create_undo_palette_all(name : String, callable : Callable):
	undo_redo.create_action(name)
	undo_redo.add_undo_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_undo_property(palette, "grid_color_index", palette.grid_color_index.duplicate())
	undo_redo.add_undo_method(callable)


func create_redo_palette_all(callable : Callable):
	undo_redo.add_do_property(palette, "color_index", palette.color_index.duplicate())
	undo_redo.add_do_property(palette, "grid_color_index", palette.grid_color_index.duplicate())
	undo_redo.add_do_method(callable)
	undo_redo.commit_action()


func create_undo_property(name : String, object : Object, property : String, value : Variant, callable : Callable, create : bool = false):
	if create: 
		undo_redo.create_action(name)
	undo_redo.add_undo_property(object, property, value)
	undo_redo.add_undo_method(callable)


func create_redo_property(object : Object, property : String, value : Variant, callable : Callable, commit : bool = false):
	undo_redo.add_do_property(object, property, value)
	undo_redo.add_do_method(callable)
	if commit:
		undo_redo.commit_action()

## TODO: prevent linked layer to get duplicated twice
func get_frames_duplicate(new_uid : bool = true) -> Array[Frame]:
	var new_frames : Array[Frame] = pool_frames.duplicate()
	for i in range(new_frames.size()):
		new_frames[i] = new_frames[i].get_duplicate(new_uid)
	return new_frames


func active_layer_is_valid():
	return get_image_index(active_layer_uid) != -1


func add_layer(label : String = "", above_layer_uid : Vector3i = Vector3i.ZERO) -> Vector3i:
	var new_index_image = IndexedColorImage.new()
	if label == "":
		layer_index_counter += 1
		new_index_image.label = str("Layer " , layer_index_counter)
	else:
		new_index_image.label = label
	new_index_image.layer_uid = get_uid()
	new_index_image.size = canvas_size
	var index = get_image_index(above_layer_uid)
	if index == -1 or above_layer_uid == Vector3i.ZERO:
		active_frame.layers.insert(active_frame.layers.size(), new_index_image)
	else:
		active_frame.layers.insert(index + 1, new_index_image)
	return new_index_image.layer_uid


func duplicate_layer(layer_uid : Vector3i):
	var new_index_image : IndexedColorImage = get_index_image(layer_uid)
	if new_index_image != null:
		new_index_image = new_index_image.get_duplicate()
	else:
		return
	layer_index_counter += 1
	new_index_image.label = str(new_index_image.label , " Duplicate", layer_index_counter)
	var index = get_image_index(layer_uid)
	if index == -1:
		active_frame.layers.insert(active_frame.layers.size(), new_index_image)
	else:
		active_frame.layers.insert(index + 1, new_index_image)


func paste_copied_layer(above_layer_uid : Vector3i = Vector3i.ZERO):
	var new_index_image : IndexedColorImage = cache_copied_colormap
	if new_index_image != null:
		new_index_image = new_index_image.get_duplicate()
	else:
		return
	layer_index_counter += 1
	new_index_image.label = str(new_index_image.label , " Copy", layer_index_counter)
	var index = get_image_index(above_layer_uid)
	if index == -1:
		active_frame.layers.insert(active_frame.layers.size(), new_index_image)
	else:
		active_frame.layers.insert(index + 1, new_index_image)
	active_layer_uid = new_index_image.layer_uid


func delete_layer(layer_uid : Vector3i):
	var index = get_image_index(layer_uid)
	if index != -1:
		active_frame.layers.remove_at(index)
	if active_frame.layers.size() == 0:
		layer_index_counter = 0


func sort_palette() -> PackedInt32Array:
	var new_palette : PackedColorArray = palette.get_sorted_palette()
	var new_grid_palette : PackedInt32Array = []
	for i in range(1, new_palette.size()):
		var exist_index : int = palette.color_index.find(new_palette[i], 1)
		while exist_index != -1 and new_grid_palette.has(exist_index):
			if exist_index + 1 >= palette.color_index.size():
				break
			exist_index = palette.color_index.find(new_palette[i], exist_index + 1)
		if new_grid_palette.has(exist_index):
			continue
		elif exist_index != -1:
			new_grid_palette.push_back(exist_index)
	if new_grid_palette.size() == palette.color_index.size() - 1:
		return new_grid_palette
	return []


func delete_unused_color_palette():
	var new_palette : PackedColorArray = []
	
	for frame in pool_frames:
		for layer in frame.layers:
			for x in range(layer.colormap.get_width()):
				for y in range(layer.colormap.get_height()):
					var idx : int = layer.colormap.get_pixel(x, y).r8
					var color : Color = palette.color_index[idx]
					if color not in new_palette:
						new_palette.push_back(color)
	
	var i = 0
	while i < palette.color_index.size() and i < palette.INDEX_COLOR_SIZE:
		if palette.color_index[i] not in new_palette and palette.color_index[i] != Color.TRANSPARENT:
			palette.color_index[i] = Color.TRANSPARENT
		i += 1


func delete_color(palette_index : int):
	var gui_index := palette.palette_to_gui_index(palette_index)
	if gui_index != -1:
		palette.color_index[palette_index] = Color.TRANSPARENT
		palette.grid_color_index.remove_at(gui_index)
		palette.grid_color_index.push_back(palette_index)


func get_image_index(layer_uid : Vector3i) -> int:
	var active_layer_index : int  = -1
	for i in range(active_frame.layers.size()):
		if active_frame.layers[i].layer_uid == layer_uid:
			active_layer_index = i
			break
	return active_layer_index


func get_index_image(layer_uid : Vector3i) -> IndexedColorImage:
	var active_layer_index : int  = -1
	for i in range(active_frame.layers.size()):
		if active_frame.layers[i].layer_uid == layer_uid:
			active_layer_index = i
			break
	if active_layer_index == -1:
		return null
	return active_frame.layers[active_layer_index]


func find_index_image(layer_uid : Vector3i, cache : bool = false) -> IndexedColorImage:
	var frames : Array[Frame] 
	if cache:
		frames = _cache_pool_frames
	else:
		frames = pool_frames
	for frame in frames:
		for layer in frame.layers:
			if layer.layer_uid == layer_uid:
				return layer
	return null


func get_layer_image(layer_uid : Vector3i) -> Image:
	var image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	var color_map : Image = get_index_image(layer_uid).colormap
	for y in range(canvas_size.y):
		for x in range(canvas_size.x):
			image.set_pixel(x, y, palette.color_index[color_map.get_pixel(x, y).r8])
	
	return image


func get_image(frame : Frame = null) -> Image:
	var src_frame : Frame = active_frame if frame == null else frame
	var canvas_image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	for index in range(src_frame.layers.size()):
		if not src_frame.layers[index].visible:
			continue
		var image = PixelPenCPP.get_image(palette.color_index, src_frame.layers[index].colormap, false)
		var rect  = image.get_used_rect()
		canvas_image.blend_rect(image, rect, rect.position)
	if frame == null:
		cache_thumbnail = canvas_image
	return canvas_image


func get_region_project_image(mask : Image = null) -> Image:
	var canvas_image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	for index in range(active_frame.layers.size()):
		if not active_frame.layers[index].visible:
			continue
		var image = PixelPenCPP.get_image(palette.color_index, active_frame.layers[index].colormap, false)
		var rect  = image.get_used_rect()
		canvas_image.blend_rect(image, rect, rect.position)
	
	if mask == null:
		return canvas_image
	else:
		var rect : Rect2i = PixelPenCPP.get_mask_used_rect(mask)
		return canvas_image.get_region(rect)


func get_region_project_colormap(mask : Image = null) -> Image:
	var canvas_image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_R8)
	for index in range(active_frame.layers.size()):
		if not active_frame.layers[index].visible:
			continue
		if mask == null:
			PixelPenCPP.fill_color(active_frame.layers[index].colormap, canvas_image, Color8(255, 0, 0), null)
		else:
			PixelPenCPP.fill_color(active_frame.layers[index].colormap, canvas_image, Color8(255, 0, 0), mask)
	if mask == null:
		return canvas_image
	else:
		var rect : Rect2i = PixelPenCPP.get_mask_used_rect(canvas_image)
		return canvas_image.get_region(rect)


func import_file(path : String) -> Vector3i:
	var image : Image = Image.load_from_file(path)
	image.convert(Image.FORMAT_RGBA8)
	var image_size : Vector2i = image.get_size()
	var layer_uid = add_layer(path.get_file().get_basename(), active_layer_uid)
	var index_image : IndexedColorImage = get_index_image(layer_uid)
	palette.color_index = PixelPenCPP.import_image(index_image.colormap, image, palette.color_index)
	return layer_uid


func import_image(image : Image, path : String) -> Vector3i:
	image.convert(Image.FORMAT_RGBA8)
	var image_size : Vector2i = image.get_size()
	var layer_uid : Vector3i = add_layer(path.get_file().get_basename(), active_layer_uid)
	var index_image : IndexedColorImage = get_index_image(layer_uid)
	palette.color_index = PixelPenCPP.import_image(index_image.colormap, image, palette.color_index)
	return layer_uid


func export_png_image(path : String) -> Error:
	var image : Image = get_image()
	image.convert(Image.FORMAT_RGBA8)
	last_export_file_path = path
	return image.save_png(path)


func export_jpg_image(path : String) -> Error:
	var image : Image = get_image()
	last_export_file_path = path
	return image.save_jpg(path, 1.0)


func export_webp_image(path : String) -> Error:
	var image : Image = get_image()
	image.convert(Image.FORMAT_RGBA8)
	last_export_file_path = path
	return image.save_webp(path)


func export_animation_gif(path : String):
	# initialize exporter object with width and height of gif canvas
	var exporter = PixelPen.state.GIFExporter.new(canvas_size.x, canvas_size.y)
	# write image using median cut quantization method and with one second animation delay
	for cell in animation_timeline:
		var img : Image = get_image(cell.frame)
		img.convert(Image.FORMAT_RGBA8)
		exporter.add_frame(img, 1.0 / animation_fps, PixelPen.state.MedianCutQuantization)

	# when you have exported all frames of animation you, then you can save data into file
	# open new file with write privlige
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file.get_open_error() == OK:
		# save data stream into file
		file.store_buffer(exporter.export_file_data())
		# close the file
		file.close()


func export_animation_frame(folder_path : String):
	for cell_i in range(animation_timeline.size()):
		var cell : AnimationCell = animation_timeline[cell_i]
		var img : Image = get_image(cell.frame)
		img.convert(Image.FORMAT_RGBA8)
		
		var file_path : String = str(folder_path, "/" , project_name ,"." , cell_i + 1, ".png")
		img.save_png(file_path)


func get_pool_index(frame_uid : Vector3i) ->int:
	for i in range(pool_frames.size()):
		if pool_frames[i].frame_uid == frame_uid:
			return i
	return -1


func get_pool_frame(frame_uid : Vector3i, cache : bool = false) -> Frame:
	var frames : Array[Frame]
	if cache:
		frames = _cache_pool_frames
	else:
		frames = pool_frames
	for frame in frames:
		if frame.frame_uid == frame_uid:
			return frame
	return null


func get_animation_draft_pool_index() -> Array[int]:
	var used : Array[int] = []
	for cell in animation_timeline:
		used.push_back(get_pool_index(cell.frame.frame_uid))
	var unused : Array[int] = []
	for frame_i in range(pool_frames.size()):
		if not used.has(frame_i):
			unused.push_back(frame_i)
	return unused


func update_onion_skin_images():
	if animation_frame_index == -1:
		animation_prev_skinning_image.clear()
		animation_next_skinning_image.clear()
		return

	if skinning_frame_index == animation_frame_index: # Do nothing active frame not change
		return

	animation_prev_skinning_image.clear()
	animation_next_skinning_image.clear()

	skinning_frame_index = animation_frame_index
	var last_uid : Vector3i = animation_timeline[animation_frame_index].frame.frame_uid # to ignore linked frame
	var prev_idx : int = animation_frame_index
	for i in PixelPen.state.userconfig.onion_skin_total:
		prev_idx -= 1
		while prev_idx > 0 and animation_timeline[prev_idx].frame.frame_uid == last_uid:
			prev_idx -= 1
		if prev_idx >= 0 and animation_timeline[prev_idx].frame.frame_uid != animation_timeline[animation_frame_index].frame.frame_uid:
			animation_prev_skinning_image.push_back(get_image(animation_timeline[prev_idx].frame))
			last_uid = animation_timeline[prev_idx].frame.frame_uid

	last_uid = animation_timeline[animation_frame_index].frame.frame_uid
	var next_idx : int = animation_frame_index
	var timeline_total = animation_timeline.size()
	for i in PixelPen.state.userconfig.onion_skin_total:
		next_idx += 1
		while next_idx < timeline_total and animation_timeline[next_idx].frame.frame_uid == last_uid:
			next_idx += 1
		if next_idx < timeline_total and animation_timeline[next_idx].frame.frame_uid != animation_timeline[animation_frame_index].frame.frame_uid:
			animation_next_skinning_image.push_back(get_image(animation_timeline[next_idx].frame))
			last_uid = animation_timeline[next_idx].frame.frame_uid


func resolve_missing_visible_frame() -> bool:
	var active_index : int = -1
	if active_frame != null:
		active_index = get_pool_index(active_frame.frame_uid)
	if active_index != -1:
		var frame := pool_frames[active_index]
		for cell_i in range(animation_timeline.size()):
			if frame.frame_uid == animation_timeline[cell_i].frame.frame_uid:
				animation_frame_index = cell_i
				canvas_pool_frame_uid = frame.frame_uid
				return true
		animation_frame_index = -1
		canvas_pool_frame_uid = frame.frame_uid
		return true
	elif animation_frame_index == -1:
		var unused : Array[int] = get_animation_draft_pool_index()
		if unused.size() > 0:
			canvas_pool_frame_uid = pool_frames[unused[0]].frame_uid
			return true
	
	if animation_timeline.size() > 0:
		animation_frame_index = 0
		canvas_pool_frame_uid = animation_timeline[0].frame.frame_uid
		return true
	elif pool_frames.size() > 0:
		animation_frame_index = -1
		canvas_pool_frame_uid = pool_frames[0].frame_uid
		return true
	else:
		pool_frames = [Frame.create(get_uid())]
		canvas_pool_frame_uid = pool_frames[0].frame_uid
		add_layer()
		active_layer_uid = active_frame.layers[0].layer_uid
	return true


func clean_invisible_color():
	for frame in pool_frames:
		for layer in frame.layers:
			PixelPenCPP.clean_invisible_color(layer.colormap, palette.color_index)
	if use_sample:
		for frame in _cache_pool_frames:
			for layer in frame.layers:
				PixelPenCPP.clean_invisible_color(layer.colormap, palette.color_index)
	for i in palette.color_index.size():
		if palette.color_index[i].a == 0:
			palette.color_index[i] = Color.TRANSPARENT


func reset_brush_to_default():
	var Tool := load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/tool.gd")
	PixelPen.state.userconfig.brush.clear()
	for i in range(0, 16):
		var start : Vector2 = Vector2(0.5, 0.5)
		var end : Vector2 = Vector2(i, i) + Vector2(0.5, 0.5)
		var rect : Rect2 = Rect2(start, end - start)
		var image : Image = Image.create(rect.size.x + 1, rect.size.y + 1, false, Image.FORMAT_R8)
		var center_mass : Vector2 = Tool.get_midpoint_ellipse(start, end, Color8(255, 0, 0), image)
		if center_mass != Vector2(-1, -1):
			var image_f = PixelPenCPP.get_image_flood(center_mass, image, Vector2i.ZERO, true)
			if image_f != null:
				PixelPenCPP.fill_color(image_f, image, Color8(255, 0, 0), null)
		image = image.get_region(PixelPenCPP.get_mask_used_rect(image))
		PixelPen.state.userconfig.brush.push_back(image)
		PixelPen.state.userconfig.save()


func reset_stamp_to_default():
	PixelPen.state.userconfig.stamp.clear()
	PixelPen.state.userconfig.save()


func crop_canvas(mask : Image) -> void:
	if use_sample:
		return
	var rect : Rect2i = PixelPenCPP.get_mask_used_rect(mask)
	for frame in pool_frames:
		for layer in frame.layers:
			var colormap : Image = layer.colormap.duplicate()
			layer.size = rect.size
			layer.colormap = colormap.get_region(rect)
	_cache_pool_frames.clear()
	undo_redo.clear_history()
	canvas_size = rect.size

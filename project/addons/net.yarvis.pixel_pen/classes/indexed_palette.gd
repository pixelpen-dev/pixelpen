@tool
class_name IndexedPalette
extends Resource


const INDEX_COLOR_SIZE = 256

@export var color_index : PackedColorArray = [Color.TRANSPARENT]
@export var grid_color_index : PackedInt32Array = [] # palette item order visible to user, array value pointing to color_index


func get_data() -> Dictionary:
	var arr : Array = []
	for c in color_index:
		arr.push_back(var_to_str(c))
	return {
		"color_index" : arr,
		"grid_color_index" : grid_color_index 
	}


func from_data(json_data : Dictionary) -> Error:
	if json_data.has("color_index"):
		color_index.clear()
		var arr : Array = json_data["color_index"] as Array
		for item in arr:
			color_index.push_back(str_to_var(item) as Color)
	else:
		return FAILED
	if json_data.has("grid_color_index"):
		grid_color_index.clear()
		var arr : Array = json_data["grid_color_index"] as Array
		for item in arr:
			grid_color_index.push_back(item as int)
	else:
		return FAILED
	return OK
	


func is_gui_valid() -> bool:
	if grid_color_index.size() != color_index.size() - 1:
		return false
	for i in range(1, color_index.size()):
		if color_index[i] != color_index[0] and palette_to_gui_index(i) == -1:
			return false
	return true


func is_gui_order_equal_to_color_index_order() -> bool:
	if grid_color_index.size() != color_index.size() - 1:
		return false
	for i in grid_color_index.size():
		if grid_color_index[i] != i + 1:
			return false
	return true


func grid_sync_to_palette():
	grid_color_index.clear()
	for i in range(color_index.size() - 1):
		grid_color_index.push_back(i + 1)


func gui_to_color(grid_index : int) -> Color:
	return color_index[grid_color_index[grid_index]]


func gui_index_to_palette_index(grid_index : int) -> int:
	return grid_color_index[grid_index]


func palette_to_gui_index(palette_index : int) -> int:
	for i in range(grid_color_index.size()):
		if grid_color_index[i] == palette_index:
			return i
	return -1


func gui_color_size():
	return grid_color_index.size()


func gui_swap_index(index_a : int, index_b : int):
	var cache_a : int = grid_color_index[index_a]
	grid_color_index[index_a] = grid_color_index[index_b]
	grid_color_index[index_b] = cache_a


func find_slot() -> int:
	for i in grid_color_index:
		if color_index[i].a == 0:
			return i
	return -1


func save_image(path : String):
	var solid_color : PackedColorArray = []
	for color in color_index:
		if color.a > 0:
			solid_color.push_back(color)
	var width : int = 1
	var height : int = solid_color.size()
	var image : Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for n in range(solid_color.size()):
		image.set_pixel(0, n, solid_color[n])
	image.resize(width * 16, height * 16, Image.INTERPOLATE_NEAREST)
	var ext = path.get_extension()
	if ext == "png":
		image.save_png(path)
	elif ext == "jpg" or ext == "jpeg":
		image.save_jpg(path)
	elif ext == "webp":
		image.save_webp(path)
	else:
		image.save_png(path.get_basename() + ".png")


func load_image(path : String, merge : bool = false):
	if not merge or color_index.size() < INDEX_COLOR_SIZE:
		color_index.resize(INDEX_COLOR_SIZE)
	if not merge:
		color_index.fill(Color.TRANSPARENT)
	var image : Image = Image.load_from_file(path)
	var i : int = 1 # keep index 0 as TRANSPARENT
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if merge:
				while color_index[i].a > 0:
					i += 1 
					if i >= color_index.size():
						return
			var color : Color = image.get_pixel(x, y)
			if color_index.find(color) == -1:
				color_index[i] = color
				i += 1
				if i >= color_index.size():
					return


func set_color_index_preset():
	color_index.resize(INDEX_COLOR_SIZE)
	color_index.fill(Color.TRANSPARENT)
	for i in range(2):
		color_index[i] = get_color_index_preset(i)


func get_color_index_preset(i : int) -> Color:
	if i == 0:
		return Color.TRANSPARENT
	if i == 1:
		return Color.BLACK
	#if i == 2:
	#	return Color.WHITE
	#if i < 11:
	#	return Color.from_hsv((i - 3) / 8.0, 0.7, 0.9)
	return Color.TRANSPARENT


func get_color_index_texture():
	var image = Image.create(color_index.size(), 1, false, Image.FORMAT_RGBAF)
	for i in range(color_index.size()):
		image.set_pixel(i, 0, color_index[i])
	return ImageTexture.create_from_image(image)


func get_sorted_palette() -> PackedColorArray:
	
	var sort = func(a : Color, b : Color)-> bool:
		var step : float = 8
		var ah := int(a.h * step)
		var al := int(a.get_luminance() * step)
		var av := int(a.v * step)
		
		if ah % 2 == 1:
			al = step - al
			av = step - av
		
		var bh := int(b.h * step)
		var bl := int(b.get_luminance() * step)
		var bv := int(b.v * step)
		
		if bh % 2 == 1:
			bl = step - bl
			bv = step - bv
		
		if ah == bh:
			if al == bl:
				return av > bv
			return al > bl
		return ah > bh
	
	var new_palette : Array[Color] = []
	for c in range(1, color_index.size()):
		if color_index[c].a > 0:
			new_palette.push_back(color_index[c])
	new_palette.sort_custom(sort)
	var new_palette_packed : PackedColorArray = []
	new_palette_packed.resize(INDEX_COLOR_SIZE)
	new_palette_packed.fill(Color.TRANSPARENT)
	for i in range(new_palette.size()):
		if i + 1 < new_palette_packed.size():
			new_palette_packed[i + 1] = new_palette[i]
	return new_palette_packed

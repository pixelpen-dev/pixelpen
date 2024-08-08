@tool
class_name IndexedColorImage
extends Resource


@export var layer_uid : Vector3i
@export var label : String = "Layer"
@export var size : Vector2i:
	set(v):
		size = v
		colormap = Image.create(size.x, size.y, false, Image.FORMAT_R8)
@export var visible : bool = true
@export var colormap : Image

var silhouette : bool = false

var _cache_colormap : Image


func get_data() -> Dictionary:
	return {
			"layer_uid" : var_to_str(layer_uid),
			"label" : label,
			"size" : var_to_str(size),
			"visible" : visible
		}


func from_data(json_data : Dictionary) -> Error:
	if json_data.has("layer_uid"):
		layer_uid = str_to_var(json_data["layer_uid"]) as Vector3i
	else:
		return FAILED
	if json_data.has("label"):
		label = json_data["label"]
	else:
		return FAILED
	if json_data.has("size"):
		size = str_to_var(json_data["size"]) as Vector2i
	else:
		return FAILED
	if json_data.has("visible"):
		visible = json_data["visible"] as bool
	else:
		return FAILED
	return OK


func get_duplicate(new_uid : bool = true):
	var new_me : IndexedColorImage = (self as IndexedColorImage).duplicate()
	if new_uid:
		new_me.layer_uid = PixelPen.state.current_project.get_uid()
	new_me.colormap = colormap.duplicate() if colormap != null else null
	return new_me


func resize(new_size : Vector2i, anchor : PixelPenEnum.ResizeAnchor):
	var cache : IndexedColorImage = get_duplicate()
	size = new_size
	var offset : Vector2i
	if anchor == PixelPenEnum.ResizeAnchor.CENTER:
		offset.x -= (cache.size.x - size.x) / 2
		offset.y -= (cache.size.y - size.y) / 2
	elif anchor == PixelPenEnum.ResizeAnchor.TOP:
		offset.x -= (cache.size.x - size.x) / 2
	elif anchor == PixelPenEnum.ResizeAnchor.TOP_RIGHT:
		offset.x -= (cache.size.x - size.x)
	elif anchor == PixelPenEnum.ResizeAnchor.RIGHT:
		offset.x -= (cache.size.x - size.x)
		offset.y -= (cache.size.y - size.y) / 2
	elif anchor == PixelPenEnum.ResizeAnchor.BOTTOM_RIGHT:
		offset.x -= (cache.size.x - size.x)
		offset.y -= (cache.size.y - size.y)
	elif anchor == PixelPenEnum.ResizeAnchor.BOTTOM:
		offset.x -= (cache.size.x - size.x) / 2
		offset.y -= (cache.size.y - size.y)
	elif anchor == PixelPenEnum.ResizeAnchor.BOTTOM_LEFT:
		offset.y -= (cache.size.y - size.y)
	elif anchor == PixelPenEnum.ResizeAnchor.LEFT:
		offset.y -= (cache.size.y - size.y) / 2
	PixelPenCPP.blend(colormap, cache.colormap, offset)


func coor_inside_canvas(x : int, y : int, mask : Image = null)->bool:
	var yes = x < size.x and x >= 0 and y < size.y and y >= 0
	if mask != null:
		yes = yes and mask.get_pixel(x, y).r8 != 0
	return yes


func rect_inside_canvas(rect : Rect2i) -> bool:
	var bound = rect.position.x >= 0 and rect.position.y >= 0
	bound = bound and rect.end.x <= size.x and rect.end.y <= size.y
	return bound


func set_index_on_color_map(x : int, y : int, index_color : int):
	assert(coor_inside_canvas(x, y), "coordinate out of bound in canvas")
	colormap.set_pixel(x, y, Color8(index_color, 0, 0, 0))


func paint_brush(x : int, y : int, index_color : int):
	PixelPen.state.current_project.paint.set_image(colormap)
	PixelPen.state.current_project.paint.set_pixel(x, y, Color8(index_color, 0, 0), PixelPen.state.current_project.brush_index)


func get_index_on_color_map(x : int, y) -> int:
	assert(x < size.x and x >= 0 and y < size.y and y >= 0, "coordinate out of bound in canvas")
	return colormap.get_pixel(x, y).r8


func set_index_rect_on_color_map(rect : Rect2i, index_color : int, mask : Image = null, filled : bool = true):
	if filled:
		if mask == null:
			colormap.fill_rect(rect, Color8(index_color, 0, 0, 0))
		else:
			var rect_mask : Image = Image.create(size.x, size.y, false, Image.FORMAT_R8)
			rect_mask.fill_rect(rect, Color8(255, 0, 0, 0))
			PixelPenCPP.fill_color(rect_mask, colormap,  Color8(index_color, 0, 0, 0), mask)
	else:
		if mask == null:
			PixelPenCPP.fill_rect_outline(rect, Color8(index_color, 0, 0, 0), colormap, null)
		else:
			PixelPenCPP.fill_rect_outline(rect, Color8(index_color, 0, 0, 0), colormap, mask)


func fill_index_on_color_map(index_color : int, mask : Image = null):
	if mask == null:
		colormap.fill(Color8(index_color, 0, 0))
	else:
		PixelPenCPP.fill_color(mask, colormap, Color8(index_color, 0, 0, 0), null)


func empty_index_on_color_map(mask : Image = null):
	if mask == null:
		colormap.fill(Color8(0, 0, 0, 0))
	else:
		PixelPenCPP.empty_index_on_color_map(mask, colormap)


func blit_index_on_color_map(index_color : int, src: Image, mask : Image):
	if mask == null:
		PixelPenCPP.fill_color(src, colormap, Color8(index_color, 0, 0, 0), null)
	else:
		PixelPenCPP.fill_color(src, colormap, Color8(index_color, 0, 0, 0), mask)


func get_color_map_with_mask(mask : Image = null)-> Image:
	if mask == null:
		return colormap.duplicate()
	return PixelPenCPP.get_color_map_with_mask(mask, colormap)


func blit_color_map(src_map : Image, mask : Image, offset : Vector2i):
	if mask == null:
		PixelPenCPP.blit_color_map(src_map, null, offset, colormap)
	else:
		PixelPenCPP.blit_color_map(src_map, mask, offset, colormap)


func get_color_map_texture(is_rebuild = false):
	return ImageTexture.create_from_image(colormap)


func swap_color(palette_index_a : int, palette_index_b : int):
	PixelPenCPP.swap_color(palette_index_a, palette_index_b, colormap)


func replace_color(palette_index_from : int, palette_index_to : int):
	PixelPenCPP.replace_color(palette_index_from, palette_index_to, colormap)


func get_mipmap_texture(palette : IndexedPalette, mask : Image = null)->ImageTexture:
	return ImageTexture.create_from_image(get_mipmap_image(palette.color_index, mask))


func get_mipmap_image(palette_color : PackedColorArray, mask : Image = null) -> Image:
	if mask == null:
		return PixelPenCPP.get_image(palette_color, colormap, true)
	return PixelPenCPP.get_image_with_mask(palette_color, colormap, mask, true)

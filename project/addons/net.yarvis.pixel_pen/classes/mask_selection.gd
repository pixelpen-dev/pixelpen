class_name MaskSelection
extends RefCounted


static func create_empty(size : Vector2i, margin : Vector2i = Vector2i.ONE )-> Image:
	return Image.create(size.x + margin.x * 2, size.y + margin.y * 2, false, Image.FORMAT_R8)


static func create_image(polygon : PackedVector2Array, size : Vector2i, margin : Vector2i = Vector2i.ONE) -> Image:
	## Check if it is rectangle, assume last value is the same like the first index
	if polygon.size() == 5:
		var point_a = Vector2(polygon[0].x, polygon[2].y)
		var point_b = Vector2(polygon[2].x, polygon[0].y)
		if (polygon[1] == point_a and polygon[3] == point_b) or (polygon[1] == point_b and polygon[3] == point_a):
			var rect : Rect2i = Rect2i(point_a, point_b - point_a).abs()
			var src_rect : Rect2i = rect.intersection(Rect2i(Vector2i.ZERO, size))
			src_rect.position += margin
			var image := Image.create(size.x + margin.x * 2, size.y + margin.y * 2, false, Image.FORMAT_R8)
			image.fill_rect(src_rect, Color8(255,0,0))
			return image
	return PixelPenCPP.get_mask_from_polygon(polygon, size, margin)


static func get_image_no_margin(image : Image, margin : Vector2i = Vector2i.ONE):
	return image.get_region(Rect2i(margin, image.get_size() - margin * 2))


static func get_inverse_image(image : Image, margin : Vector2i = Vector2i.ONE) -> Image:
	var size : Vector2i = image.get_size()
	var inverse_mask = Image.create(size.x, size.y, false, Image.FORMAT_R8)
	inverse_mask.fill_rect(Rect2i(margin, size - margin * 2) ,Color8(255, 0, 0))
	PixelPenCPP.empty_index_on_color_map(image, inverse_mask)
	return inverse_mask


static func union_image(image_a : Image, image_b : Image)-> Image:
	PixelPenCPP.blend(image_a, image_b, Vector2i.ZERO)
	return image_a


static func union_polygon(image_a : Image, polygon : PackedVector2Array, size : Vector2i, margin : Vector2i = Vector2i.ONE)-> Image:
	## Check if it is rectangle, assume last value is the same like the first index
	if polygon.size() == 5:
		var point_a = Vector2(polygon[0].x, polygon[2].y)
		var point_b = Vector2(polygon[2].x, polygon[0].y)
		if (polygon[1] == point_a and polygon[3] == point_b) or (polygon[1] == point_b and polygon[3] == point_a):
			var rect : Rect2i = Rect2i(point_a, point_b - point_a).abs()
			var src_rect : Rect2i = rect.intersection(Rect2i(Vector2i.ZERO, size))
			src_rect.position += margin
			image_a.fill_rect(src_rect, Color8(255, 0, 0))
			return image_a

	var new_selection_image := MaskSelection.create_image(polygon, size)
	return union_image(image_a, new_selection_image)


static func difference_image(image_a : Image, image_b : Image)-> Image:
	PixelPenCPP.empty_index_on_color_map(image_b, image_a)
	return image_a


static func difference_polygon(image_a : Image, polygon : PackedVector2Array, size : Vector2i, margin : Vector2i = Vector2i.ONE)-> Image:
	## Check if it is rectangle, assume last value is the same like the first index
	if polygon.size() == 5:
		var point_a = Vector2(polygon[0].x, polygon[2].y)
		var point_b = Vector2(polygon[2].x, polygon[0].y)
		if (polygon[1] == point_a and polygon[3] == point_b) or (polygon[1] == point_b and polygon[3] == point_a):
			var rect : Rect2i = Rect2i(point_a, point_b - point_a).abs()
			var src_rect : Rect2i = rect.intersection(Rect2i(Vector2i.ZERO, size))
			src_rect.position += margin
			image_a.fill_rect(src_rect, Color8(0, 0, 0))
			return image_a
	
	var new_selection_image := MaskSelection.create_image(polygon, size)
	return difference_image(image_a, new_selection_image)


static func intersection_image(image_a : Image, image_b : Image)-> Image:
	var new_image = Image.create(image_a.get_size().x, image_a.get_size().y, false, Image.FORMAT_R8)
	PixelPenCPP.fill_color(image_a, new_image, Color8(255, 0, 0), image_b)
	return new_image


static func intersection_polygon(image_a : Image, polygon : PackedVector2Array, size : Vector2i, margin : Vector2i = Vector2i.ONE)-> Image:
	## Check if it is rectangle, assume last value is the same like the first index
	if polygon.size() == 5:
		var point_a = Vector2(polygon[0].x, polygon[2].y)
		var point_b = Vector2(polygon[2].x, polygon[0].y)
		if (polygon[1] == point_a and polygon[3] == point_b) or (polygon[1] == point_b and polygon[3] == point_a):
			var rect : Rect2i = Rect2i(point_a, point_b - point_a).abs()
			var src_rect : Rect2i = rect.intersection(Rect2i(Vector2i.ZERO, size))
			src_rect.position += margin
			var target_image : Image = create_empty(size)
			target_image.blit_rect(image_a.get_region(src_rect), Rect2i(Vector2i.ZERO, src_rect.size), src_rect.position )
			return target_image
	
	var new_selection_image := MaskSelection.create_image(polygon, size)
	return intersection_image(image_a, new_selection_image)


static func offset_image(image : Image, offset : Vector2i, new_size : Vector2i, margin : Vector2i = Vector2i.ONE) -> Image:
	var new_image = Image.create(new_size.x + margin.x * 2, new_size.y + margin.y * 2, false, Image.FORMAT_R8)
	var src_rect : Rect2i =  Rect2i(margin, image.get_size() - margin * 2)
	var target_rect : Rect2i = Rect2i(margin - offset, new_size)
	src_rect = src_rect.intersection(target_rect)
	new_image.blit_rect(image, src_rect, offset + src_rect.position)
	return new_image


static func get_mask_used_rect(mask : Image)-> Rect2i:
	return PixelPenCPP.get_mask_used_rect(mask);

@tool
extends ConfirmationDialog


enum PropertiesID{
	SHEETS_SIZE = 0,
	SHEETS_MARGIN,
	LINKED_FRAME,
	DIRECTIONS,
	FILE_PATH
}


@export var properties_node : Control
@export var canvas_2d : Node2D


var _frame_image : Array[Image] = []


func calculate_data():
	if PixelPen.state.current_project == null:
		return
	var frame_total : int = PixelPen.state.current_project.animation_timeline.size()
	var frame_size : Vector2i = PixelPen.state.current_project.canvas_size
	var collumn : int = frame_total if frame_total * frame_size.x  <= 2040 else floor(2040.0 / frame_size.x)
	var row : int = ceil((frame_total as float) / collumn)
	var canvas_size = Vector2i(frame_size.x * collumn, frame_size.y * row)

	properties_node.structure[PropertiesID.SHEETS_SIZE].vector2i_value = Vector2i(collumn, row)
	properties_node.structure[PropertiesID.SHEETS_MARGIN].vector2i_value = Vector2i.ZERO
	properties_node.structure[PropertiesID.LINKED_FRAME].enum_value = 0
	properties_node.structure[PropertiesID.DIRECTIONS].enum_value = 0
	properties_node.structure[PropertiesID.FILE_PATH].file_value = ""

	canvas_2d.checker.texture.size = canvas_size
	canvas_2d.update_grid(frame_size)
	canvas_2d.update_margin(Vector2i.ZERO)
	canvas_2d.update_camera_zoom()
	
	_frame_image.clear()
	for i in range(frame_total):
		_frame_image.push_back(PixelPen.state.current_project.get_image(PixelPen.state.current_project.animation_timeline[i].frame))


func place_frame():
	if PixelPen.state.current_project == null:
		return
	var canvas_size : Vector2i = canvas_2d.checker.texture.size
	var image : Image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	var rect : Rect2i = Rect2i(Vector2i.ZERO, PixelPen.state.current_project.canvas_size)
	
	var sheet_size : Vector2i = properties_node.structure[PropertiesID.SHEETS_SIZE].vector2i_value
	var margin : Vector2i = properties_node.structure[PropertiesID.SHEETS_MARGIN].vector2i_value
	var keep_all : bool = properties_node.structure[PropertiesID.LINKED_FRAME].enum_value == 0
	var directions : bool = properties_node.structure[PropertiesID.DIRECTIONS].enum_value == 0
	var last_frame_uid : Vector3i
	var i : int = 0
	if directions:
		for y in range(sheet_size.y):
			for x in range(sheet_size.x):
				while i < _frame_image.size():
					var valid : bool = keep_all or last_frame_uid != PixelPen.state.current_project.animation_timeline[i].frame.frame_uid
					if valid:
						image.blit_rect(_frame_image[i], rect, rect.size * Vector2i(x, y) + margin)
						last_frame_uid = PixelPen.state.current_project.animation_timeline[i].frame.frame_uid
						i += 1
						break
					i += 1
	else:
		for x in range(sheet_size.x):
			for y in range(sheet_size.y):
				while i < _frame_image.size():
					var valid : bool = keep_all or last_frame_uid != PixelPen.state.current_project.animation_timeline[i].frame.frame_uid
					if valid:
						image.blit_rect(_frame_image[i], rect, rect.size * Vector2i(x, y) + margin)
						last_frame_uid = PixelPen.state.current_project.animation_timeline[i].frame.frame_uid
						i += 1
						break
					i += 1
	canvas_2d.sprite_sheets.texture = ImageTexture.create_from_image(image)


func _init():
	add_to_group("pixelpen_popup")


func _ready():
	calculate_data()
	properties_node.build()
	place_frame()


func _on_tree_properties_value_changed(index, _value):
	var tree_row : TreeRow = properties_node.structure[index]
	match index:
		PropertiesID.SHEETS_SIZE:
			canvas_2d.checker.texture.size = tree_row.vector2i_value * PixelPen.state.current_project.canvas_size
			place_frame()
			canvas_2d.update_camera_zoom()
		PropertiesID.SHEETS_MARGIN:
			var sheet_size : Vector2i = properties_node.structure[PropertiesID.SHEETS_SIZE].vector2i_value
			canvas_2d.checker.texture.size = sheet_size * PixelPen.state.current_project.canvas_size + (tree_row.vector2i_value * 2)
			canvas_2d.update_margin(tree_row.vector2i_value)
			place_frame()
			canvas_2d.update_camera_zoom()
		PropertiesID.LINKED_FRAME:
			place_frame()
			canvas_2d.update_camera_zoom()
		PropertiesID.DIRECTIONS:
			place_frame()
			canvas_2d.update_camera_zoom()


func _on_canvas_item_rect_changed():
	canvas_2d.update_camera_zoom()


func _on_confirmed():
	if properties_node.structure[PropertiesID.FILE_PATH].file_value == "" or canvas_2d.sprite_sheets.texture == null:
		return
	var image : Image = canvas_2d.sprite_sheets.texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var err : Error = image.save_png(properties_node.structure[PropertiesID.FILE_PATH].file_value)
	if err != OK:
		return
	hide()
	queue_free()

@tool
extends ConfirmationDialog


signal closed


@export var sprite : Sprite2D
@export var spin_box : SpinBox
@export var size_label : Label
@export var grid_button : TextureButton
@export var grid_view : Node2D

var _src_image : Image
var _first : bool = true


func _init():
	add_to_group("pixelpen_popup")


func _ready():
	grid_button.shortcut = PixelPen.state.userconfig.shorcuts.view_show_grid


func _process(_delta):
	if _first:
		grab_focus()
		_first = false
		grid_view.update_camera_zoom()


func show_file(path : String):
	_src_image = Image.load_from_file(path)
	_src_image.convert(Image.FORMAT_RGBA8)
	if _src_image.is_empty():
		return
	sprite.texture = ImageTexture.create_from_image(_src_image)
	update_label()


func get_image()->Image:
	return sprite.texture.get_image()


func _on_update_preview_pressed():
	var scale_factor : int = spin_box.get_line_edit().text as int
	if scale_factor == 0:
		sprite.texture = ImageTexture.create_from_image(_src_image)
	elif scale_factor > 0:
		scale_up(pow(2, scale_factor))
	elif scale_factor < 0:
		scale_down(pow(2, abs(scale_factor)))
	update_label()
	grid_view.update_camera_zoom()


func update_label():
	size_label.text = str("Size : (", _src_image.get_width(),"x",_src_image.get_height(),"px) -> (", 
			sprite.texture.get_width() , "x", sprite.texture.get_height(),"px)")


func scale_up(factor : int):
	var img_size = _src_image.get_size()
	if img_size.x * factor >= 1 and img_size.y * factor >= 1: 
		var new_img : Image = _src_image.duplicate()
		new_img.resize(img_size.x * factor, img_size.y * factor, Image.INTERPOLATE_NEAREST)
		sprite.texture = ImageTexture.create_from_image(new_img)


func scale_down(factor : int):
	var img_size = _src_image.get_size()
	if img_size.x / factor >= 1 and img_size.y / factor >= 1: 
		var new_img : Image = _src_image.duplicate()
		new_img.resize(img_size.x / factor, img_size.y / factor, Image.INTERPOLATE_NEAREST)
		sprite.texture = ImageTexture.create_from_image(new_img)


func _on_grid_pressed():
	grid_view.show_grid = not grid_view.show_grid

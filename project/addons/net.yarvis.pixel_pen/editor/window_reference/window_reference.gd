@tool
extends Window

@export var texture : TextureRect


func load_texture(file : String):
	var image = Image.load_from_file(file)
	title = file.get_file().get_basename()
	texture.texture = ImageTexture.create_from_image(image)
	size.x = 520
	size.y = 520 * image.get_size().y / image.get_size().x


func _on_close_requested():
	hide()
	queue_free()


func _process(_delta):
	if get_window().has_focus() and not is_in_group("pixelpen_popup"):
		add_to_group("pixelpen_popup")
	elif not get_window().has_focus() and is_in_group("pixelpen_popup"):
		remove_from_group("pixelpen_popup")

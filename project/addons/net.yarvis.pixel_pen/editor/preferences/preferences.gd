@tool
extends AcceptDialog


@export var tab_container : TabContainer


func _init():
	add_to_group("pixelpen_popup")


func _ready():
	var screen_size : Rect2i = DisplayServer.screen_get_usable_rect().grow(-128)
	size.x = mini( screen_size.size.y * 1.5, screen_size.size.x)
	size.y = screen_size.size.y
	tab_container.current_tab = 0

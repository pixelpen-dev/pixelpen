@tool
extends ConfirmationDialog


@export var width_node : LineEdit
@export var height_node : LineEdit
@export var anchor : PixelPenEnum.ResizeAnchor

var canvas_width : float:
	set(v):
		width_node.text = str(v)
	get:
		return max(1, width_node.text as float)

var canvas_height : float:
	set(v):
		height_node.text = str(v)
	get:
		return max(1, height_node.text as float)

func _init():
	add_to_group("pixelpen_popup")


func _ready():
	add_button("Reset", false, "on_reset")

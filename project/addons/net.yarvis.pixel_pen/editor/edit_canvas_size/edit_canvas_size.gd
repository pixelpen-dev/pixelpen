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
	var reset_btn := add_button("Reset", false, "on_reset")
	get_cancel_button().focus_next = width_node.get_path()
	height_node.focus_next = reset_btn.get_path()
	width_node.grab_focus.call_deferred()


func _process(_delta):
	if Input.is_key_pressed(KEY_ENTER) and (width_node.has_focus() or height_node.has_focus()):
		get_ok_button().pressed.emit()

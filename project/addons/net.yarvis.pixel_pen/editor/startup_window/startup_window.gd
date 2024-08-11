@tool
extends Window


@export var new_btn : Button


func _init():
	visible = false


func _ready():
	new_btn.grab_focus.call_deferred()


func _on_new_pressed():
	hide()
	queue_free()
	PixelPen.state.request_new_project.emit()


func _on_open_pressed():
	hide()
	queue_free()
	PixelPen.state.request_open_project.emit()


func _on_import_pressed():
	hide()
	queue_free()
	PixelPen.state.request_import_image.emit()


func _on_close_requested():
	hide()
	queue_free()


func _process(_delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		_on_close_requested()

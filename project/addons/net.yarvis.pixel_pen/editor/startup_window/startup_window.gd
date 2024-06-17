@tool
extends Window


func _init():
	visible = false


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

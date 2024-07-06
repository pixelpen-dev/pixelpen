@tool
extends Window


var EditorMainUI := load("res://addons/net.yarvis.pixel_pen/editor/editor_main_ui.tscn")

var window_running : bool = false


func is_window_running():
	return window_running


func _ready():
	if is_window_running():
		if Engine.is_editor_hint():
			PixelPen.state.disconnect_all_signal()
		add_child(EditorMainUI.instantiate())


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_window().window_running = false
		PixelPen.state.current_project = null
		get_window().queue_free()
		if Engine.is_editor_hint():
			PixelPen.state.disconnect_all_signal()


func scan():
	if Engine.is_editor_hint() and type_exists("EditorInterface"):
		var efs = EditorInterface.get_resource_filesystem()
		efs.scan()

@tool
extends EditorPlugin


var EditorWindow := load("res://addons/net.yarvis.pixel_pen/editor/editor_window.tscn")

var editor_window_instance : Window

var last_main_screen : String = "3D"


func _on_tool_pressed():
	editor_window_instance = EditorWindow.instantiate()
	editor_window_instance.window_running = true
	EditorInterface.get_base_control().add_child(editor_window_instance)
	editor_window_instance.show()
	editor_window_instance.grab_focus()
	editor_window_instance.tree_exited.connect(func():
			get_window().grab_focus()
			PixelPen.state.free()
			PixelPen.state = PixelPenState.new()
			)


func _on_main_screen_changed(screen : String):
	last_main_screen = screen


func _has_main_screen():
	return true


func _get_plugin_name():
	return "PixelPen"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("CanvasItem", "EditorIcons")


func _make_visible(visible):
	if not editor_window_instance and visible:
		EditorInterface.set_main_screen_editor(last_main_screen)
		_on_tool_pressed()


func _enter_tree():
	EditorInterface.get_base_control().get_window().about_to_popup.connect(func():
			PixelPen.state.free()
			)
	main_screen_changed.connect(_on_main_screen_changed)


func _exit_tree():
	main_screen_changed.disconnect(_on_main_screen_changed)

@tool
extends EditorPlugin

const EditorWindow := preload("editor/editor_window.tscn")
var main_singleton := preload("pixelpen_singleton.gd")

var editor_window_instance : Window

var last_main_screen : String = "3D"


func _on_tool_pressed():
	editor_window_instance = EditorWindow.instantiate()
	editor_window_instance.window_running = true
	EditorInterface.get_base_control().add_child(editor_window_instance)
	print("PixelPen-v",get_plugin_version(), " running...")
	editor_window_instance.show()
	editor_window_instance.grab_focus()
	editor_window_instance.tree_exited.connect(func():
			get_window().grab_focus()
			print("PixelPen-v",get_plugin_version(), " exited...\n")
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
	add_autoload_singleton("PixelPen", main_singleton.resource_path)
	main_screen_changed.connect(_on_main_screen_changed)


func _exit_tree():
	remove_autoload_singleton("PixelPen")
	main_screen_changed.disconnect(_on_main_screen_changed)

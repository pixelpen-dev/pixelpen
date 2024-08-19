@tool
extends HBoxContainer


@export var tree : Tree
@export var tree_properties : Control

var general_tree_structure : Dictionary = {
	"Guide" : ["Grid"],
	"Projects" : [],
	"Cursor" : [],
	"Palette" : [],
	"Animation" : ["Frame", "Onion Skinning"]
}

var general_structure: Dictionary = {
	"/Guide/Grid" : [
		TreeRow.create_vector2i(
			"Grid line repeat", "X", "Y", PixelPen.state.userconfig.default_grid_size,
			Vector2i.ONE, Vector2i(16384, 16384), Vector2i.ONE
		),
		TreeRow.create_vector2i(
			"Checker size", "WIDTH", "HEIGHT", PixelPen.state.userconfig.checker_size, 
			Vector2i.ONE, Vector2i(16384, 16384), Vector2i.ONE
		)] as Array[TreeRow],
	"/Projects" : [
		TreeRow.create_file_path(
			"Default workspace folder", PixelPen.state.userconfig.default_workspace,
			FileDialog.FILE_MODE_OPEN_DIR
		),
		TreeRow.create_vector2i(
			"Default canvas size", "WIDTH", "HEIGHT", PixelPen.state.userconfig.default_canvas_size,
			Vector2i.ONE, Vector2i(16384, 16384), Vector2i.ONE
		)
	] as Array[TreeRow],
	"/Cursor" : [TreeRow.create_enum(
			"Hide in canvas", 1 if PixelPen.state.userconfig.hide_cursor_in_canvas else 0,
			["FALSE", "TRUE"] as Array[String]
		)] as Array[TreeRow],
	"/Palette" :[
		TreeRow.create_range("Grid rows", PixelPen.state.userconfig.palette_gui_row, 1, 32, 1)
	] as Array[TreeRow],
	"/Animation/Frame" : [
		TreeRow.create_int(
			"Default fps", PixelPen.state.userconfig.default_animation_fps, 1, 1000
		)
	] as Array[TreeRow],
	"/Animation/Onion Skinning" : [
		TreeRow.create_int(
			"Onion skin total", PixelPen.state.userconfig.onion_skin_total, 1, 10
		),
		TreeRow.create_color("Previous frame tint color", PixelPen.state.userconfig.onion_skin_tint_previous, false),
		TreeRow.create_color("Next frame tint color", PixelPen.state.userconfig.onion_skin_tint_next, false),
		TreeRow.create_range("Alpha", PixelPen.state.userconfig.onion_skin_tint_alpha, 0.1, 1.0, 0.01)
	] as Array[TreeRow]
	}


var current_active_path : String


func _ready():
	general_tree_node()


func general_tree_node():
	tree.clear()
	var root = tree.create_item()
	var path : String = ""
	var active_tree : TreeItem
	for key in general_tree_structure.keys():
		var tree_item = tree.create_item(root)
		tree_item.set_text(0, key)
		if not general_structure.has(path):
			path = "/" + key
			active_tree = tree_item
		for item in general_tree_structure[key]:
			var sub_tree_item = tree.create_item(tree_item)
			sub_tree_item.set_text(0, item)
			if not general_structure.has(path):
				path = path + "/" + item
				active_tree = sub_tree_item
	if general_structure.has(path):
		tree.set_selected(active_tree, 0)


func _on_general_tree_item_selected():
	var tree_item : TreeItem = tree.get_selected()
	current_active_path = tree.get_selected().get_text(0)
	while tree_item.get_parent():
		current_active_path = tree_item.get_parent().get_text(0) + "/" + current_active_path
		tree_item = tree_item.get_parent()
	if general_structure.has(current_active_path):
		tree_properties.structure = general_structure[current_active_path]
	else:
		tree.get_selected().collapsed = not tree.get_selected().collapsed
		tree_properties.structure = [] as Array[TreeRow]
		tree.get_selected().deselect(0)
	tree_properties.build()


func _on_general_properties_value_changed(index, value):
	match current_active_path:
		"/Guide/Grid":
			if index == 0:
				PixelPen.state.userconfig.default_grid_size = value as Vector2i
				PixelPen.state.userconfig.save()
			elif index == 1:
				PixelPen.state.userconfig.checker_size = value as Vector2i
				PixelPen.state.userconfig.save()
				PixelPen.state.layer_items_changed.emit()
		"/Projects":
			if index == 0:
				PixelPen.state.userconfig.default_workspace = value as String
				PixelPen.state.userconfig.save()
			elif index == 1:
				PixelPen.state.userconfig.default_canvas_size = value as Vector2i
				PixelPen.state.userconfig.save()
		"/Cursor":
			if index == 0:
				PixelPen.state.userconfig.hide_cursor_in_canvas = (value as int) == 1
				PixelPen.state.userconfig.save()
		"/Palette":
			if index == 0:
				PixelPen.state.userconfig.palette_gui_row = value as int
				PixelPen.state.userconfig.save()
				PixelPen.state.palette_changed.emit()
		"/Animation/Frame":
			if index == 0:
				PixelPen.state.userconfig.default_animation_fps = value as int
				PixelPen.state.userconfig.save()
		"/Animation/Onion Skinning":
			if index == 0:
				PixelPen.state.userconfig.onion_skin_total = value as int
				PixelPen.state.userconfig.save()
				PixelPen.state.layer_items_changed.emit()
			elif index == 1:
				PixelPen.state.userconfig.onion_skin_tint_previous = value as Color
				PixelPen.state.userconfig.save()
				PixelPen.state.layer_items_changed.emit()
			elif index == 2:
				PixelPen.state.userconfig.onion_skin_tint_next = value as Color
				PixelPen.state.userconfig.save()
				PixelPen.state.layer_items_changed.emit()
			elif index == 3:
				PixelPen.state.userconfig.onion_skin_tint_alpha = value as float
				PixelPen.state.userconfig.save()
				PixelPen.state.layer_items_changed.emit()

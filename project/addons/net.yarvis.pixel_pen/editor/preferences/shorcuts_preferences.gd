@tool
extends HBoxContainer


var default_shorcut : EditorShorcut = load("res://addons/net.yarvis.pixel_pen/resources/editor_shorcut.tres")

@export var shorcuts_tree : Tree
@export var edit_button : Button
@export var reset_button : Button
@export var clear_button : Button


var shorcuts_tree_structure : Dictionary = {
	"Menu" : {
		"PixelPen" : ["About.about", "Preferences.preferences" , "Quit.quit_editor"],
		"File" : [
			"New.new_project", "Open.open_project", "Save.save", "Save as.save_as", "Import.import",
			"Quick export.quick_export", "Close project.close_project"
		],
		"Edit" : [
			"Undo.undo", "Redo.redo", "Inverse selection.inverse_selection", 
			"Clear selection.remove_selection", "Delete selection.delete_selected", 
			"Copy.copy", "Cut.cut", "Paste.paste", "Create brush.create_brush",
			"Reset brush.reset_brush", "Create stamp.create_stamp", "Reset stamp.reset_stamp",
			"Switch to previous toolbox.prev_toolbox", "Canvas crop selection.canvas_crop_selection", "Canvas size.canvas_size"
		],
		"Layer" : [
			"Add.add_layer", "Delete.delete_layer", "Duplicate layer.duplicate_layer",
			"Duplicate selection.duplicate_selection", "Copy layer.copy_layer",
			"Cut layer.cut_layer", "Paste layer.paste_layer", "Rename layer.rename_layer",
			"Merge down.merge_down", "Merge visible.merge_visible", "Merge all.merge_all",
			"Show all.show_all", "Hide all.hide_all", "Active Go up.active_go_up",
			"Active Go down.active_go_down"
		],
		"Animation" : [
			"Play/Pause.animation_play_pause", "Preview Play/Pause.animation_preview_play_pause", 
			"Skip to front.animation_skip_to_front", "Step backward.animation_step_backward",
			"Step forward.animation_step_forward", "Skip to end.animation_skip_to_end",
			"Loop animation playback.loop_playback", "Show onion skinning.animation_onion_skinning",
			"Insert frame to right.frame_insert_right", "Insert frame to left.frame_insert_left",
			"Duplicate frame.duplicate_frame", "Duplicate frame linked.duplicate_frame_linked",
			"Convert frame linked to unique.convert_frame_linked_to_unique",
			"Right shift frame.animation_shift_frame_right", "Left shift frame.animation_shift_frame_left",
			"Use frame in timeline.animation_move_frame_to_timeline",
			"Remove frame from timeline.animation_move_frame_to_draft", "Create draft frame.create_draft_frame",
			"Delete draft frame.delete_draft_frame"
		],
		"View" : [
			"Rotate canvas -90.rotate_canvas_min90", "Rotate canvas 90.rotate_canvas_90",
			"Flip canvas horizontal.flip_canvas_horizontal", "Flip canvas vertical.flip_canvas_vertical",
			"Reset canvas transform.reset_canvas_transform", "Reset zoom.reset_zoom", 
			"Edit selection only.toggle_edit_selection_only", "Show virtual mouse.virtual_mouse",
			"Show grid.view_show_grid", "Show vertical mirror guide.vertical_mirror", 
			"Show horizontal mirror guide.horizontal_mirror",
			"Show tile.view_show_tile", "Show preview.show_preview", "Show animation timeline.show_animation_timeline",
			"Tint black to layer.toggle_tint_layer",
			"Filter greyscale.filter_greyscale", "Show info.show_info"
		]
	},
	"Tools" : {
		"Select.tool_select" : [],
		"Move.tool_move" : [],
		"Hand.tool_pan" : [],
		"Selection.tool_selection" : [],
		"Pen.tool_pen" : [],
		"Brush.tool_brush" : [],
		"Stamp.tool_stamp" : [],
		"Eraser.tool_eraser" : [],
		"Magnet.tool_magnet" : [],
		"Line.tool_line" : [],
		"Ellipse.tool_ellipse" : [],
		"Rectangle.tool_rectangle" : [],
		"Fill.tool_fill" : [],
		"Color Picker.tool_color_picker" : [],
		"Zoom.tool_zoom" : []
	},
	"Navigation" : {
		"Zoom in.zoom_in" : [],
		"Zoom out.zoom_out" : [],
	}
}

func _ready():
	PixelPen.state.userconfig.shorcuts = PixelPen.state.userconfig.shorcuts.duplicate(true)
	edit_button.disabled = true
	reset_button.disabled = true
	clear_button.disabled = true
	shorcuts_tree_node()


func get_shortcut(property : String) -> String:
	if property == "":
		return ""
	var shorcut = PixelPen.state.userconfig.shorcuts.get(property)
	if shorcut != null:
		return (shorcut as Shortcut).get_as_text()
	return "_"


func shorcuts_tree_node():
	shorcuts_tree.clear()
	var root = shorcuts_tree.create_item()
	shorcuts_tree.set_column_title(0, "Name")
	shorcuts_tree.set_column_title(1, "Shorcuts")
	shorcuts_tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	shorcuts_tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	shorcuts_tree.set_column_expand(0, true)
	shorcuts_tree.set_column_expand(1, false)
	shorcuts_tree.set_column_custom_minimum_width(1, 200)
	
	for key in shorcuts_tree_structure.keys():
		var tree_item = shorcuts_tree.create_item(root)
		tree_item.collapsed = true
		tree_item.set_text(0, key.get_basename())
		if key.get_extension() == "":
			tree_item.set_selectable(1, false)
		else:
			tree_item.set_text(1, get_shortcut(key.get_extension()))
			tree_item.set_metadata(1, key.get_extension())
		for child_item in shorcuts_tree_structure[key].keys():
			var child_tree_item = shorcuts_tree.create_item(tree_item)
			child_tree_item.collapsed = true
			child_tree_item.set_text(0, child_item.get_basename())
			if child_item.get_extension() == "":
				child_tree_item.set_selectable(1, false)
			else:
				child_tree_item.set_text(1, get_shortcut(child_item.get_extension()))
				child_tree_item.set_metadata(1, child_item.get_extension())
			for grandchild_item in shorcuts_tree_structure[key][child_item]:
				if grandchild_item.get_extension() == "virtual_mouse" and not OS.get_name() == "Android":
					continue
				var grandchild_tree_item = shorcuts_tree.create_item(child_tree_item)
				grandchild_tree_item.collapsed = true
				grandchild_tree_item.set_text(0, grandchild_item.get_basename())
				if grandchild_item.get_extension() == "":
					grandchild_tree_item.set_selectable(1, false)
				else:
					grandchild_tree_item.set_text(1, get_shortcut(grandchild_item.get_extension()))
					grandchild_tree_item.set_metadata(1, grandchild_item.get_extension())


func _on_shorcuts_tree_item_selected():
	var tree_item : TreeItem = shorcuts_tree.get_selected()
	var has_meta : bool = tree_item.get_metadata(1) != null
	
	edit_button.disabled = not has_meta
	reset_button.disabled = not has_meta
	clear_button.disabled = not has_meta
	
	if not has_meta:
		tree_item.collapsed = not tree_item.collapsed
		tree_item.deselect(0)


func _on_edit_pressed():
	var window : ConfirmationDialog = ConfirmationDialog.new()
	window.always_on_top = true
	var wrapper : Control = Control.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	window.add_child(wrapper)
	var line_edit : LineEdit = LineEdit.new()
	line_edit.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	line_edit.placeholder_text = "Linstening for input..."
	line_edit.set_script(load("res://addons/net.yarvis.pixel_pen/editor/preferences/shorcut_listener.gd"))
	wrapper.add_child(line_edit)
	window.confirmed.connect(func ():
			if line_edit.record_shorcut.has_valid_event():
				PixelPen.state.userconfig.shorcuts.set(shorcuts_tree.get_selected().get_metadata(1), line_edit.record_shorcut)
				PixelPen.state.userconfig.save()
				shorcuts_tree.get_selected().set_text(1, line_edit.record_shorcut.get_as_text())
				PixelPen.state.shorcut_changed.emit()
			window.hide()
			window.queue_free()
			)
	window.canceled.connect(func():
			window.hide()
			window.queue_free())
	add_child(window)
	window.popup_centered(Vector2(320, 128))


func _on_reset_pressed():
	var tree_item : TreeItem = shorcuts_tree.get_selected()
	var has_meta : bool = tree_item.get_metadata(1) != null
	if has_meta:
		var shorcut : Shortcut = default_shorcut.get(tree_item.get_metadata(1))
		if shorcut != null:
			PixelPen.state.userconfig.shorcuts.set(tree_item.get_metadata(1), shorcut.duplicate())
			PixelPen.state.userconfig.save()
			shorcuts_tree.get_selected().set_text(1, shorcut.get_as_text())
			PixelPen.state.shorcut_changed.emit()


func _on_clear_pressed():
	var tree_item : TreeItem = shorcuts_tree.get_selected()
	var has_meta : bool = tree_item.get_metadata(1) != null
	if has_meta:
		var shorcut : Shortcut = Shortcut.new()
		if shorcut != null:
			PixelPen.state.userconfig.shorcuts.set(tree_item.get_metadata(1), shorcut)
			PixelPen.state.userconfig.save()
			shorcuts_tree.get_selected().set_text(1, shorcut.get_as_text())
			PixelPen.state.shorcut_changed.emit()


func _on_reset_all_pressed():
	PixelPen.state.userconfig.shorcuts = load("res://addons/net.yarvis.pixel_pen/resources/editor_shorcut.tres").duplicate(true)
	PixelPen.state.userconfig.save()
	PixelPen.state.shorcut_changed.emit()
	shorcuts_tree_node()

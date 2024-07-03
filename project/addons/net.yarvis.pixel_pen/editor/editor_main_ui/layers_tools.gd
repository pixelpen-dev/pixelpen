@tool
extends Control


var LayerProperties := load("res://addons/net.yarvis.pixel_pen/editor/layer_properties.tscn")
var MoveTool := load("res://addons/net.yarvis.pixel_pen/editor/editor_canvas/move_tool.gd")

@export var canvas_node : Node2D
@export var add_layer : TextureButton
@export var delete_layer : TextureButton


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	var disable_btn = func():
			var is_disable = PixelPen.state.current_project == null
			for child in get_children():
				if child is TextureButton:
					child.disabled = is_disable
					var hover = child.get_child(0)
					if hover.name == "Hover":
						# force update shader
						hover.is_active = hover.is_active
	PixelPen.state.project_file_changed.connect(disable_btn)
	disable_btn.call()
	
	PixelPen.state.request_layer_properties.connect(_on_layer_properties)
	PixelPen.state.edit_mode_changed.connect(func(mode: PixelPenProject.ProjectMode):
			add_layer.visible = mode == PixelPenProject.ProjectMode.BASE
			delete_layer.visible = mode == PixelPenProject.ProjectMode.BASE
			)


func _on_layer_properties(layer_uid : Vector3i) -> ConfirmationDialog:
	var lp = LayerProperties.instantiate()
	lp.layer_uid = layer_uid
	add_child(lp)
	lp.popup_in_last_position()
	return lp


func _on_add_pressed():
	var window = _on_layer_properties(Vector3i.ZERO)
	window.confirmed.connect(func():
			(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Add layer", func ():
					PixelPen.state.layer_items_changed.emit()
					PixelPen.state.project_saved.emit(false)
					)
			(PixelPen.state.current_project as PixelPenProject).add_layer(window.layer_name, PixelPen.state.current_project.active_layer_uid)
			(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
					PixelPen.state.layer_items_changed.emit()
					PixelPen.state.project_saved.emit(false)
					)
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)


func _on_duplicate_layer():
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Duplicate layer", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	(PixelPen.state.current_project as PixelPenProject).duplicate_layer(PixelPen.state.current_project.active_layer_uid)
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)


func _on_copy_layer():
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap = (PixelPen.state.current_project as PixelPenProject).active_layer.get_duplicate()


func _on_cut_layer():
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap = (PixelPen.state.current_project as PixelPenProject).active_layer.get_duplicate()
	_on_trash_pressed()


func _on_duplicate_selection():
	if canvas_node.selection_tool_hint.texture == null:
		return
	var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
		
	var mask_selection = MaskSelection.get_image_no_margin(canvas_node.selection_tool_hint.texture.get_image())
	var colormap_image : Image = index_image.get_color_map_with_mask(mask_selection)
	
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap = index_image.get_duplicate()
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap.colormap = colormap_image.duplicate()
	_on_paste()


func _on_copy_selection():
	if canvas_node.selection_tool_hint.texture == null:
		return
	var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
		
	var mask_selection = MaskSelection.get_image_no_margin(canvas_node.selection_tool_hint.texture.get_image())
	var colormap_image : Image = index_image.get_color_map_with_mask(mask_selection)
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap = index_image.get_duplicate()
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap.colormap = colormap_image.duplicate()


func _on_cut_selection():
	if canvas_node.selection_tool_hint.texture == null:
		return
	var index_image : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
	if index_image == null:
		return
		
	var mask_selection = MaskSelection.get_image_no_margin(canvas_node.selection_tool_hint.texture.get_image())
	var colormap_image : Image = index_image.get_color_map_with_mask(mask_selection)
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap = index_image.get_duplicate()
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap.colormap = colormap_image.duplicate()
	
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Cut selection", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	index_image.empty_index_on_color_map(mask_selection)
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)


func _on_paste():
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Paste layer", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	(PixelPen.state.current_project as PixelPenProject).paste_copied_layer(PixelPen.state.current_project.active_layer_uid)
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)
	(PixelPen.state.current_project as PixelPenProject).cache_copied_colormap = null


func _on_merge_down():
	var active_layer_index : int = PixelPen.state.current_project.get_image_index(PixelPen.state.current_project.active_layer_uid)
	if active_layer_index == -1:
		return
		
	var below_layer_index : int = active_layer_index - 1
	if below_layer_index <= -1:
		return
	
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Merge down", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	
	var active_img = (PixelPen.state.current_project as PixelPenProject).active_layer.get_color_map_with_mask()
	(PixelPen.state.current_project as PixelPenProject).active_frame.layers[below_layer_index].blit_color_map(active_img, null, Vector2i.ZERO)
	(PixelPen.state.current_project as PixelPenProject).delete_layer(PixelPen.state.current_project.active_layer_uid)
	PixelPen.state.current_project.active_layer_uid = (PixelPen.state.current_project as PixelPenProject).active_frame.layers[below_layer_index].layer_uid
	(PixelPen.state.current_project as PixelPenProject).active_frame.layers[below_layer_index].visible = true
	
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)


func _on_merge_visible():
	if (PixelPen.state.current_project as PixelPenProject).active_frame.layers.size() <= 1:
		return
	
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Merge visible", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	var j = 0
	for i in range((PixelPen.state.current_project as PixelPenProject).active_frame.layers.size() -1, -1, -1):
		if (PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].visible:
			j = i
			break
	
	var new_arr : Array[IndexedColorImage] = []
	var prev_img = (PixelPen.state.current_project as PixelPenProject).active_frame.layers[j].get_color_map_with_mask()
	var last_index = j
	for i in range((PixelPen.state.current_project as PixelPenProject).active_frame.layers.size() -1, -1, -1):
		if j != i and (PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].visible:
			(PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].blit_color_map(prev_img, null, Vector2i.ZERO)
			prev_img = (PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].get_color_map_with_mask()
			last_index = i
		if not (PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].visible:
			new_arr.push_back((PixelPen.state.current_project as PixelPenProject).active_frame.layers[i])
	new_arr.push_back((PixelPen.state.current_project as PixelPenProject).active_frame.layers[last_index])
	(PixelPen.state.current_project as PixelPenProject).active_frame.layers = new_arr
	
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)


func _on_merge_all():
	if (PixelPen.state.current_project as PixelPenProject).active_frame.layers.size() <= 1:
		return
	
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Merge all", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	var j = 0
	for i in range((PixelPen.state.current_project as PixelPenProject).active_frame.layers.size() -1, -1, -1):
		if (PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].visible:
			j = i
			break
	
	var prev_img = (PixelPen.state.current_project as PixelPenProject).active_frame.layers[j].get_color_map_with_mask()
	var last_index = j
	for i in range(j, -1, -1):
		if (PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].visible:
			(PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].blit_color_map(prev_img, null, Vector2i.ZERO)
			prev_img = (PixelPen.state.current_project as PixelPenProject).active_frame.layers[i].get_color_map_with_mask()
			last_index = i
	(PixelPen.state.current_project as PixelPenProject).active_frame.layers = [(PixelPen.state.current_project as PixelPenProject).active_frame.layers[last_index]]
	
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)


func _on_hide_all():
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Remove layer", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	for img in (PixelPen.state.current_project as PixelPenProject).active_frame.layers:
		img.visible = false
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)


func _on_show_all():
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Remove layer", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	for img in (PixelPen.state.current_project as PixelPenProject).active_frame.layers:
		img.visible = true
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)


func _on_trash_pressed():
	(PixelPen.state.current_project as PixelPenProject).create_undo_layers("Remove layer", func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	
	PixelPen.state.current_project.delete_layer(PixelPen.state.current_project.active_layer_uid)
	for layer_uuid in PixelPen.state.current_project.multilayer_selected:
		PixelPen.state.current_project.delete_layer(layer_uuid)
	PixelPen.state.current_project.multilayer_selected.clear()
	
	(PixelPen.state.current_project as PixelPenProject).create_redo_layers(func ():
			PixelPen.state.layer_items_changed.emit()
			PixelPen.state.project_saved.emit(false)
			)
	
	PixelPen.state.layer_items_changed.emit()
	PixelPen.state.project_saved.emit(false)

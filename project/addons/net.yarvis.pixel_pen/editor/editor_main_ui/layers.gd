@tool
extends VBoxContainer


const Layer := preload("../layer.tscn")

@export var separator_hint : HSeparator
@export var panel_wrapper : Panel

var _meta : int


func _ready():
	if not PixelPen.need_connection(get_window()):
		return
	PixelPen.project_file_changed.connect(_on_project_file_changed)
	PixelPen.layer_items_changed.connect(_on_project_file_changed)
	PixelPen.palette_changed.connect(_on_project_file_changed)
	separator_hint.visible = false
	separator_hint.get("theme_override_styles/separator").color = PixelPen.userconfig.accent_color


func _on_project_file_changed():
	if PixelPen.current_project != null and PixelPen.current_project.animation_is_play:
		return
	var children = get_children()
	for child in children:
		if not(child is HSeparator):
			child.queue_free()
	if PixelPen.current_project == null or (PixelPen.current_project as PixelPenProject).active_frame == null:
		return
	var layers : Array[IndexedColorImage] = (PixelPen.current_project as PixelPenProject).active_frame.layers
	var i : int = layers.size() - 1
	while i >= 0:
		var layer = Layer.instantiate()
		layer.label.text = str(layers[i].label)
		layer.layer_uid = layers[i].layer_uid
		layer.layer_visible = layers[i].visible
		add_child(layer)
		i -= 1
	custom_minimum_size = Vector2i(0, layers.size() * 40)
	
	if not PixelPen.current_project.active_layer_is_valid():
		if PixelPen.current_project.active_frame.layers.size() > 0:
			PixelPen.current_project.active_layer_uid = PixelPen.current_project.active_frame.layers[0].layer_uid
	PixelPen.layer_active_changed.emit(PixelPen.current_project.active_layer_uid)

## state [START 0, MOVE 1, DROP 2]
func _on_pickable_pressed(mouse_pos : Vector2, layer_uid : Vector3i, state : int):
	var root_pos = global_position
	var pick_pos = mouse_pos - root_pos
	var pick_index : int = clampi(round(pick_pos.y / 40.0) as int, 0, (PixelPen.current_project as PixelPenProject).active_frame.layers.size())
	
	if state == 0:
		_meta = clampi(floor(pick_pos.y / 40.0) as int, 0, (PixelPen.current_project as PixelPenProject).active_frame.layers.size())
	
	if state == 2:
		if pick_index > _meta:
			pick_index -= 1
		move_child(separator_hint, 0)
		separator_hint.visible = false
		var index : int = (PixelPen.current_project as PixelPenProject).get_image_index(layer_uid)
		var item : IndexedColorImage = (PixelPen.current_project as PixelPenProject).get_index_image(layer_uid)
		var layers : Array[IndexedColorImage] = (PixelPen.current_project as PixelPenProject).active_frame.layers
		
		(PixelPen.current_project as PixelPenProject).create_undo_layers("Reorder layer", func ():
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
				)
		
		layers.remove_at(index)
		pick_index = clampi(pick_index, 0, layers.size())
		pick_index = layers.size() - pick_index
		
		layers.insert(pick_index, item)
		
		(PixelPen.current_project as PixelPenProject).active_frame.layers = layers
		
		(PixelPen.current_project as PixelPenProject).create_redo_layers(func ():
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
				)
						
		PixelPen.layer_items_changed.emit()
		PixelPen.project_saved.emit(false)
		
	if state == 1:
		separator_hint.visible = pick_index != _meta and pick_index != _meta + 1
		move_child(separator_hint, pick_index)

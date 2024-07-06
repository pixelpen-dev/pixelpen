@tool
extends Control


const COLOR_RECT_COLOR_NAME = "Color"
const X_TOTAL = 8
const I_TOTAL = 255

@export var color_picker : ColorPicker


var _child_item : Array[Control] = []
var _grid_focus_index : int = 0

var tr_material := load("res://addons/net.yarvis.pixel_pen/resources/tile_transparant_material.tres")


func _ready():
	if not PixelPen.state.need_connection(get_window()):
		return
	PixelPen.state.project_file_changed.connect(func():
			update_palette()
			)
	PixelPen.state.color_picked.connect(func(palette_index):
			_grid_focus_index = PixelPen.state.current_project.palette.palette_to_gui_index(palette_index)
			assert(_grid_focus_index != -1, "Error: _grid_focus_index == -1")
			)
	PixelPen.state.palette_changed.connect(update_palette)
	custom_minimum_size = Vector2(0, 0)


func _draw():
	if not _child_item.is_empty():
		var rect = Rect2(_child_item[_grid_focus_index].position, _child_item[_grid_focus_index].size)
		draw_rect(rect, Color.WHITE)
		rect = Rect2(_child_item[_grid_focus_index].position + Vector2.ONE * 1, _child_item[_grid_focus_index].size - Vector2.ONE * 2)
		draw_rect(rect, Color.BLACK)


func update_palette():
	var children = get_children()
	for child in children:
		child.queue_free()
	_child_item.clear()
	

func _process(_delta):
	if not PixelPen.state.need_connection(get_window()):
		return
	if size != Vector2.ZERO and _child_item.is_empty() and PixelPen.state.current_project != null:
		var x_size = floorf(size.x / X_TOTAL)
		var item_size : Vector2 = Vector2.ONE * floorf(x_size - 4)
		custom_minimum_size = Vector2(0, x_size * (1 + floor(I_TOTAL / X_TOTAL)))
		tr_material.set_shader_parameter("tile_size", Vector2.ONE * ( item_size.x / 4))
		var i : int = 0
		var y = 0
		while i < I_TOTAL:
			for x in range(X_TOTAL):
				var ch = _color_item(Vector2.ONE * x_size, item_size)
				ch.position = Vector2(x, y) * x_size
				if i < PixelPen.state.current_project.palette.gui_color_size():
					ch.get_node(COLOR_RECT_COLOR_NAME).color = PixelPen.state.current_project.palette.gui_to_color(i)
					add_child(ch)
					_child_item.push_back(ch)
				i += 1
				if i >= I_TOTAL:
					break
			y += 1
		color_picker.color = _child_item[_grid_focus_index].get_node(COLOR_RECT_COLOR_NAME).color
		PixelPen.state.color_picked.emit( PixelPen.state.current_project.palette.gui_index_to_palette_index(_grid_focus_index) )
		queue_redraw()


func _color_item(wrapper_size : Vector2, item_size : Vector2):
	var wrapper = ColorRect.new()
	wrapper.size = wrapper_size
	wrapper.color = Color.TRANSPARENT
	
	var tr = ColorRect.new()
	tr.set_anchors_preset(Control.PRESET_CENTER)
	tr.size = item_size
	tr.position = item_size * -0.5
	tr.mouse_filter = Control.MOUSE_FILTER_PASS
	tr.material = tr_material
	wrapper.add_child(tr)
	
	var ar = ColorRect.new()
	ar.name = COLOR_RECT_COLOR_NAME
	ar.set_anchors_preset(Control.PRESET_CENTER)
	ar.size = item_size
	ar.position = item_size * -0.5
	ar.mouse_filter = Control.MOUSE_FILTER_PASS
	wrapper.add_child(ar)
	
	wrapper.gui_input.connect(func(event : InputEvent):
			if event and event is InputEventMouseButton:
				if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
					if Input.is_key_pressed(KEY_SHIFT): # Replace color (LMB + SHIFT)
						var layer : IndexedColorImage = (PixelPen.state.current_project as PixelPenProject).active_layer
						if layer != null: 
							var layer_uid : Vector3i = layer.layer_uid
							(PixelPen.state.current_project as PixelPenProject).create_undo_layer("Replace color", layer.layer_uid, func ():
								PixelPen.state.layer_image_changed.emit(layer_uid)
								PixelPen.state.project_saved.emit(false)
								PixelPen.state.palette_changed.emit()
								)
								
							var index_a = PixelPen.state.current_project.palette.gui_index_to_palette_index(_grid_focus_index)
							_grid_focus_index = _child_item.find(wrapper)
							var index_b = PixelPen.state.current_project.palette.gui_index_to_palette_index(_grid_focus_index)
							
							layer.replace_color(index_a, index_b)
							
							(PixelPen.state.current_project as PixelPenProject).create_redo_layer(layer.layer_uid, func ():
								PixelPen.state.layer_image_changed.emit(layer_uid)
								PixelPen.state.project_saved.emit(false)
								PixelPen.state.palette_changed.emit()
								)
							PixelPen.state.layer_image_changed.emit(layer_uid)
							PixelPen.state.project_saved.emit(false)
							PixelPen.state.palette_changed.emit()
							
					elif Input.is_key_pressed(KEY_ALT): # Copy color (LMB + ALT)
						(PixelPen.state.current_project as PixelPenProject).create_undo_palette("copy palette", func():
								PixelPen.state.layer_items_changed.emit()
								PixelPen.state.project_saved.emit(false)
								PixelPen.state.palette_changed.emit()
								)
							
						var copied_color = PixelPen.state.current_project.palette.gui_to_color(_grid_focus_index)
						_grid_focus_index = _child_item.find(wrapper)
						var palette_index = PixelPen.state.current_project.palette.gui_index_to_palette_index(_grid_focus_index)
						PixelPen.state.current_project.palette.color_index[palette_index] = copied_color
						
						(PixelPen.state.current_project as PixelPenProject).create_redo_palette(func():
								PixelPen.state.layer_items_changed.emit()
								PixelPen.state.project_saved.emit(false)
								PixelPen.state.palette_changed.emit()
								)
						
						PixelPen.state.layer_items_changed.emit()
						PixelPen.state.project_saved.emit(false)
						PixelPen.state.palette_changed.emit()
					else: # TODO:Pick color (LMB)
						_grid_focus_index = _child_item.find(wrapper)
						color_picker.color = ar.color
						PixelPen.state.color_picked.emit(PixelPen.state.current_project.palette.gui_index_to_palette_index(_grid_focus_index))
						queue_redraw()
				elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
					if Input.is_key_pressed(KEY_SHIFT): # Opaque color (RMB + SHIFT)
						(PixelPen.state.current_project as PixelPenProject).create_undo_palette("Opaque palette", func():
								PixelPen.state.project_saved.emit(false)
								PixelPen.state.palette_changed.emit()
								)
						
						_grid_focus_index = _child_item.find(wrapper)
						var palette_index = PixelPen.state.current_project.palette.gui_index_to_palette_index(_grid_focus_index)
						PixelPen.state.current_project.palette.color_index[palette_index].a = 1.0
						
						(PixelPen.state.current_project as PixelPenProject).create_redo_palette(func():
								PixelPen.state.project_saved.emit(false)
								PixelPen.state.palette_changed.emit()
								)
						
						PixelPen.state.project_saved.emit(false)
						PixelPen.state.palette_changed.emit()
					else: # Swap color (RMB)
						var gui_index_a : int = _grid_focus_index
						var gui_index_b = _child_item.find(wrapper)
						
						var palette_index_prev : int = PixelPen.state.current_project.palette.gui_index_to_palette_index(gui_index_a)
						(PixelPen.state.current_project as PixelPenProject).create_undo_palette_gui("Swap color", func():
								PixelPen.state.color_picked.emit(palette_index_prev)
								PixelPen.state.project_saved.emit(false)
								PixelPen.state.palette_changed.emit()
								)
						
						PixelPen.state.current_project.palette.gui_swap_index(gui_index_a, gui_index_b)
						
						var palette_index_new : int = PixelPen.state.current_project.palette.gui_index_to_palette_index(gui_index_b)
						(PixelPen.state.current_project as PixelPenProject).create_redo_palette_gui(func():
								PixelPen.state.color_picked.emit(palette_index_new)
								PixelPen.state.project_saved.emit(false)
								PixelPen.state.palette_changed.emit()
								)
						
						_grid_focus_index = gui_index_b
						PixelPen.state.project_saved.emit(false)
						PixelPen.state.palette_changed.emit()
			)
	return wrapper


func _on_color_picker_color_changed(color):
	if not PixelPen.state.project_file_changed.get_connections():
		return
	if PixelPen.state.current_project == null:
		return
	_child_item[_grid_focus_index].get_node(COLOR_RECT_COLOR_NAME).color = color

	var pallet_index : int = PixelPen.state.current_project.palette.gui_index_to_palette_index(_grid_focus_index)
	PixelPen.state.current_project.palette.color_index[pallet_index] = color
	
	PixelPen.state.color_picked.emit(pallet_index)
	PixelPen.state.project_saved.emit(false)


func _on_palette_item_rect_changed():
	update_palette()

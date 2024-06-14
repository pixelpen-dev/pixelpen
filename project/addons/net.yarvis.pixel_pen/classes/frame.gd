@tool
extends Resource
class_name Frame


@export var frame_uid : Vector3i
@export var layers : Array[IndexedColorImage]

var frame_color : Color:
	get:
		if frame_color == Color():
			frame_color = Color.from_hsv(randf(), randf_range(0.25, 0.75), randf_range(0.5, 0.75))
		return frame_color


static func create(uid : Vector3i) -> Frame:
	var frame := Frame.new()
	frame.frame_uid = uid
	return frame


func find_layer(layer_uid : Vector3i) -> IndexedColorImage:
	for layer in layers:
		if layer.layer_uid == layer_uid:
			return layer
	return null


func get_duplicate(new_uid : bool = true) -> Frame:
	var frame : Frame = (self as Frame).duplicate()
	if new_uid:
		frame.frame_uid = PixelPen.singleton.current_project.get_uid()
	var new_layers : Array[IndexedColorImage] = frame.layers.duplicate()
	for i in range(new_layers.size()):
		new_layers[i] = new_layers[i].get_duplicate(new_uid)
	return frame


func get_layer_duplicate(new_uid : bool = true) -> Array[IndexedColorImage]:
	var new_layers : Array[IndexedColorImage] = layers.duplicate()
	for i in range(new_layers.size()):
		new_layers[i] = new_layers[i].get_duplicate(new_uid)
	return new_layers

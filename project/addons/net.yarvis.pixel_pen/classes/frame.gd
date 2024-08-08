@tool
extends Resource
class_name Frame


@export var frame_uid : Vector3i
@export var layers : Array[IndexedColorImage]
@export var layer_active_uid : Vector3i

var frame_color : Color:
	get:
		if frame_color == Color():
			frame_color = Color.from_hsv(randf(), randf_range(0.25, 0.75), randf_range(0.5, 0.75))
		return frame_color


static func create(uid : Vector3i) -> Frame:
	var frame := Frame.new()
	frame.frame_uid = uid
	return frame


func get_data() -> Dictionary:
	var dict : Dictionary = {
		"frame_uid" : var_to_str(frame_uid),
		"layer_active_uid" : var_to_str(layer_active_uid)
	}
	var arr : Array = []
	for layer in layers:
		arr.push_back(layer.get_data())
	dict["layers"] = arr
	return dict


func from_data(json_data : Dictionary) -> Error:
	if json_data.has("frame_uid"):
		frame_uid = str_to_var(json_data["frame_uid"]) as Vector3i
	else:
		return FAILED
	if json_data.has("layer_active_uid"):
		layer_active_uid = str_to_var(json_data["layer_active_uid"]) as Vector3i
	else:
		return FAILED
	layers.clear()
	var arr : Array = json_data["layers"] as Array
	for layer in arr:
		var index_image := IndexedColorImage.new()
		var err := index_image.from_data(layer)
		if err != OK:
			return FAILED
		layers.push_back(index_image)
	return OK


func find_layer(layer_uid : Vector3i) -> IndexedColorImage:
	for layer in layers:
		if layer.layer_uid == layer_uid:
			return layer
	return null


func get_duplicate(new_uid : bool = true) -> Frame:
	var frame : Frame = (self as Frame).duplicate()
	if new_uid:
		frame.frame_uid = PixelPen.state.current_project.get_uid()
	var new_layers : Array[IndexedColorImage] = frame.layers.duplicate()
	for i in range(new_layers.size()):
		new_layers[i] = new_layers[i].get_duplicate(new_uid)
	return frame


func get_layer_duplicate(new_uid : bool = true) -> Array[IndexedColorImage]:
	var new_layers : Array[IndexedColorImage] = layers.duplicate()
	for i in range(new_layers.size()):
		new_layers[i] = new_layers[i].get_duplicate(new_uid)
	return new_layers

@tool
extends Control


signal value_changed(index, value)

enum FloatAligment{
	FLOAT_LEFT = 0,
	FLOAT_RIGHT = 2
}

@export var structure : Array[PixelPenPropertyItem]
@export var list_margin : float = 8
@export_range(0.0, 1.0, 0.001) var column_ratio : float = 0.5:
	set(v):
		if column_ratio != v:
			column_ratio = clampf(v, 0.0, 1.0)
@export var main_label_aligment : FloatAligment = FloatAligment.FLOAT_LEFT

var _aligment : HorizontalAlignment:
	get:
		return HORIZONTAL_ALIGNMENT_LEFT if main_label_aligment == FloatAligment.FLOAT_LEFT else HORIZONTAL_ALIGNMENT_RIGHT

## Call this if strcuture property update manually by code
func build():
	_clean_up()

	for row in structure:
		var field : PixelPenPropertyField = PixelPenPropertyField.new(row, column_ratio, _aligment, list_margin)
		field.value_changed.connect(func(value):
				_on_value_changed(row, value)
				)
		add_child(field)

	if get_child_count() > 0:
		var update_anchor = func():
			var last_y_position: float = 0
			for child in get_children():
				if not child.is_queued_for_deletion():
					child.position.y = last_y_position
					last_y_position += child.custom_minimum_size.y + list_margin
		update_anchor.call_deferred()


func _ready():
	build()


func _clean_up():
	for child in get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()


func _on_value_changed(tree_row : PixelPenPropertyItem, value):
	for i in range(structure.size()):
		if structure[i] == tree_row:
			value_changed.emit(i, value)

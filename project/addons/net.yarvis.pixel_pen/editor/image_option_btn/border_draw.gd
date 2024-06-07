@tool
extends HFlowContainer


@export var main_parent : Control


var _prev_index : int


func _draw():
	if main_parent.brush_index < get_child_count():
		var child = get_child(main_parent.brush_index)
		draw_rect(Rect2(child.position + Vector2(0, 1), child.size - Vector2(0, 1)), Color.MAGENTA, false)


func _process(_delta):
	queue_redraw()
		

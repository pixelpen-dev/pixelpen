@tool
extends CanvasItem


@export var visible_callback : Callable


func _process(_delta):
	if visible_callback.is_valid():
		visible = visible_callback.call()

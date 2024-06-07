@tool
class_name DataBranch
extends Resource


@export var data : Array[Branch]

## Call this to prevent branch lock previus size
func clear_cache():
	for branch in data:
		branch.parent_rect = Rect2()
		branch.child_rect = Rect2()


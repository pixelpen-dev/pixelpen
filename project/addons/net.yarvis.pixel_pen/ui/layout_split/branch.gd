@tool
class_name Branch
extends Resource


signal value_changed

@export var name : String
## Parent Node path of current branch chilldren.
@export var parent : NodePath:
	set(new_value):
		if parent != new_value:
			parent = new_value
			parent_rect = Rect2()
			child_rect = Rect2()


## Make sure the child path is on the dirrect child of main LayoutSplit node
@export var child : NodePath:
	set(new_value):
		if child != new_value:
			child = new_value
			parent_rect = Rect2()
			child_rect = Rect2()

## This value will be ignore if parent_size or child_size is not ZERO
@export_range(0.0, 1.0) var split_ratio : float = 0.5:
	set(new_value):
		if _split_ratio != new_value:
			_split_ratio = clampf(new_value, 0.0, 1.0)
			parent_rect = Rect2()
			child_rect = Rect2()
			value_changed.emit()
	get:
		return _split_ratio

## Split horizontal on TRUE. 
@export var vertical : bool = false:
	set(new_value):
		if vertical != new_value:
			vertical = new_value
			parent_rect = Rect2()
			child_rect = Rect2()
			value_changed.emit()

@export_subgroup("Overrides")
## Override x if split horizontal or y if split vertical
@export var parent_size : float = 0.0
## Override x if split horizontal or y if split vertical
@export var child_size : float = 0.0


var parent_rect : Rect2
var child_rect : Rect2

var _split_ratio : float

## Savely set split_ratio without update the layout
func set_split_ratio(ratio : float):
	_split_ratio = ratio


static func create(
			name : String,
			node_parent : NodePath,
			node_child : NodePath = NodePath(),
			ratio : float = 0.5,
			split_vertical : bool = false
			) -> Branch:
		
	var branch : Branch = Branch.new()
	branch.name = name
	branch.parent = node_parent
	branch.child = node_child
	branch.set_split_ratio(ratio)
	branch.vertical = split_vertical
	return branch

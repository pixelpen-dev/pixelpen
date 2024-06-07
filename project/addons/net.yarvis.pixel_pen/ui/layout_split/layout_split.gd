@tool
extends Control


const BORDER_HOVER_WIDTH : float = 4
const MIN_DOCK_SIZE : float = 16

## Set the layout data. Child Layout will be set base on the order of the current array
@export var branches : DataBranch
@export var border_margin : bool = true
@export var enable : bool = false:
	set(v):
		if v != enable:
			enable = v
			if branches != null:
				branches.clear_cache()
			update_layout()

var _resize : bool = false
var _resize_start_press : Vector2
var _resize_branch : Branch
var _resize_range : Vector2
var _resize_range_start : float


func has_dock(node : Control) -> bool:
	var path_child := get_path_to(node)
	if path_child.is_empty() or branches == null:
		return false
	
	for branch in branches.data:
		if branch.child == path_child:
			return true
	
	return false

## Make sure the [node_child] path is on the dirrect child of this node. [to_parent] can be this node or dirrect child of this node
func dock(node_child : Control, to_parent : Control, front : bool = false, split_ratio : float = 0.5, vertical : bool = false):
	var path_child := get_path_to(node_child)
	var path_parent := get_path_to(to_parent)
	if path_child.is_empty() or path_parent.is_empty():
		return
	branches.data.push_back(Branch.create(node_child.name, path_parent, path_child, split_ratio, vertical))
	if front:
		swap(node_child, to_parent)


func undock(node_child : Control) -> bool:
	var child_path := get_path_to(node_child)
	if child_path.is_empty():
		return false
	
	var new_parent_branch : int = -1

	var count : int = branches.data.size()
	for i in range(count): # Find as branch child
		var branch : Branch = branches.data[i]
		if branch.child == child_path:
			new_parent_branch = i
			break

	if new_parent_branch == -1:
		return false
	
	var i : int  = 0
	count = branches.data.size()
	var found : bool = false
	while i < count: # Find as branch parent
		var branch : Branch = branches.data[i]
		if branch.parent == child_path:
			branches.data[new_parent_branch].child = branch.child
			branches.data.remove_at(i)
			count = branches.data.size()
			found = true
		else:
			i += 1
	if not found:
		branches.data.remove_at(new_parent_branch)
	return true

## Swap dock position
func swap(node_a : Control, node_b : Control):
	var path_a := get_path_to(node_a)
	var path_b := get_path_to(node_b)
	if path_a.is_empty() or path_b.is_empty():
		return
	
	var count : int = branches.data.size()
	for i in range(count):
		var branch : Branch = branches.data[i]
		if branch.parent == path_a:
			branch.parent = path_b
		elif branch.parent == path_b:
			branch.parent = path_a
		if branch.child == path_a:
			branch.child = path_b
		elif branch.child == path_b:
			branch.child = path_a


func update_layout():
	if size.x * size.y == 0 or not enable or branches == null:
		return
	var count : int = branches.data.size()
	for i in range(count):
		_update_anchor_branch(branches.data[i])
	for i in range(count): # Update offset if child border overlap with node border
		var branch : Branch = branches.data[i]
		var child : Control = get_node_or_null(branch.child)
		if get_node_or_null(branch.parent) == self:
			child.position = Vector2.ZERO
		if child != null:
			var start_offset : Vector2
			var end_offset : Vector2
			if border_margin:
				if child.position.x == 0:
					start_offset.x = BORDER_HOVER_WIDTH * 0.5
				if child.position.y == 0:
					start_offset.y = BORDER_HOVER_WIDTH * 0.5
				if child.get_rect().end.x == 0:
					end_offset.x = BORDER_HOVER_WIDTH * 0.5
				if child.get_rect().end.y == 0:
					end_offset.y = BORDER_HOVER_WIDTH * 0.5
			
			child.offset_left = BORDER_HOVER_WIDTH * 0.5 + start_offset.x
			child.offset_top = BORDER_HOVER_WIDTH * 0.5 + start_offset.y
			child.offset_right = BORDER_HOVER_WIDTH * -0.5 - end_offset.x
			child.offset_bottom = BORDER_HOVER_WIDTH * -0.5 - end_offset.y


func _init():
	item_rect_changed.connect(func():
			if branches != null:
				branches.clear_cache()
				update_layout()
			)


func _ready():
	branches.clear_cache()
	update_layout()


func _input(event):
	if not get_window().has_focus() or branches == null:
		return
	var can_resize : bool = false
	var can_resize_rect : Rect2
	
	if not _resize:
		for branch in branches.data:
			var parent : Control = get_node_or_null(branch.parent)
			var child : Control = get_node_or_null(branch.child)
			if parent != self and parent != null and child != null and branch.parent_size == 0 and branch.child_size == 0:
				var parent_rect : Rect2 = branch.parent_rect.grow(BORDER_HOVER_WIDTH)
				var child_rect : Rect2 = branch.child_rect.grow(BORDER_HOVER_WIDTH)
				if parent_rect.intersection(child_rect).has_point(get_local_mouse_position()):
					can_resize = true
					_resize_branch = branch
					_resize_range_start = branch.split_ratio
					can_resize_rect = parent_rect.intersection(child_rect)
					_resize_range = branch.parent_rect.size + branch.child_rect.size
					if can_resize_rect.size.x > can_resize_rect.size.y:
						_resize_range.x = 0
					else:
						_resize_range.y = 0
					break
	
	if can_resize or _resize:
		if event and event is InputEventMouseButton:
			if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
				_resize = true
				_resize_start_press = get_local_mouse_position()
			
			if not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
				_resize = false
			
		if _resize and event and event is InputEventMouseMotion:
			var offset : Vector2 = get_local_mouse_position() - _resize_start_press
			if _resize_range.x == 0:
				offset.y += _resize_range_start * _resize_range.y
				_resize_branch.split_ratio = offset.y / _resize_range.y
			elif _resize_range.y == 0:
				offset.x += _resize_range_start * _resize_range.x
				_resize_branch.split_ratio = offset.x / _resize_range.x
	
	if can_resize:
		if can_resize_rect.size.x > can_resize_rect.size.y:
			mouse_default_cursor_shape = Control.CURSOR_VSPLIT
		else:
			mouse_default_cursor_shape = Control.CURSOR_HSPLIT
	elif not _resize:
		mouse_default_cursor_shape = Control.CURSOR_ARROW


func _exit_tree():
	if branches == null:
		return
	for branch in branches.data:
		if branch.value_changed.is_connected(update_layout):
			branch.value_changed.disconnect(update_layout)


func _update_anchor_branch(branch : Branch):
	var parent := get_node_or_null(branch.parent)
	var child := get_node_or_null(branch.child)
	if parent == null:
		return
		
	if not branch.value_changed.is_connected(update_layout):
		branch.value_changed.connect(update_layout)
	
	var valid_child : bool = child != null and child.visible
	
	if valid_child:
		child.offset_left = 0
		child.offset_top = 0
		child.offset_right = 0
		child.offset_bottom = 0

	if parent == self and valid_child:
		child.anchor_left = 0
		child.anchor_top = 0
		child.anchor_right = 1
		child.anchor_bottom = 1

	elif valid_child:
		var anchor_start : Vector2 = Vector2(parent.anchor_left, parent.anchor_top)
		var anchor_end : Vector2 = Vector2(parent.anchor_right, parent.anchor_bottom)
		if branch.vertical:
			parent.anchor_left = anchor_start.x
			parent.anchor_top = anchor_start.y
			parent.anchor_right = anchor_end.x
			child.anchor_left = anchor_start.x
			child.anchor_right = anchor_end.x
			child.anchor_bottom = anchor_end.y
			
			var anchor_range : float = anchor_end.y - anchor_start.y
			if branch.parent_size != 0:
				parent.anchor_bottom = anchor_start.y + (branch.parent_size / size.y)
			elif branch.child_size != 0:
				parent.anchor_bottom = anchor_end.y - (branch.child_size / size.y)
			elif branch.child_rect.size.y != 0:
				parent.anchor_bottom = anchor_end.y - (branch.child_rect.size.y / size.y)
			else:
				parent.anchor_bottom = anchor_start.y + (anchor_range * branch.split_ratio)
			parent.anchor_bottom = clampf(parent.anchor_bottom, anchor_start.y + MIN_DOCK_SIZE / size.y, anchor_end.y - MIN_DOCK_SIZE / size.y)
			child.anchor_top = parent.anchor_bottom
			branch.set_split_ratio((parent.anchor_bottom - parent.anchor_top) / anchor_range)
		else:
			parent.anchor_left = anchor_start.x
			parent.anchor_top = anchor_start.y
			parent.anchor_bottom = anchor_end.y
			child.anchor_top = anchor_start.y
			child.anchor_right = anchor_end.x
			child.anchor_bottom = anchor_end.y
			
			var anchor_range : float = anchor_end.x - anchor_start.x
			if branch.parent_size != 0:
				parent.anchor_right = anchor_start.x + (branch.parent_size / size.x)
			elif branch.child_size != 0:
				parent.anchor_right = anchor_end.x - (branch.child_size / size.x)
			elif branch.child_rect.size.x != 0:
				parent.anchor_right = anchor_end.x - (branch.child_rect.size.x / size.x)
			else:
				parent.anchor_right = anchor_start.x + (anchor_range * branch.split_ratio)
			parent.anchor_right = clampf(parent.anchor_right, anchor_start.x + MIN_DOCK_SIZE / size.y, anchor_end.x - MIN_DOCK_SIZE / size.y)
			child.anchor_left = parent.anchor_right
			branch.set_split_ratio((parent.anchor_right- parent.anchor_left) / anchor_range)
		branch.parent_rect = parent.get_rect()
		branch.child_rect = child.get_rect()

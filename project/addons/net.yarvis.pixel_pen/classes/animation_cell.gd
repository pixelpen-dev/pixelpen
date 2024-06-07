@tool
extends Resource
class_name AnimationCell


@export var cell_uid : Vector3i
@export var frame : Frame


static func create(uid : Vector3i) -> AnimationCell:
	var cell := AnimationCell.new()
	cell.cell_uid = uid
	return cell

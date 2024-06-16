@tool
class_name TreeRow
extends Resource


enum FieldMode{
	INT,
	FLOAT,
	RANGE,
	STRING,
	VECTOR2,
	VECTOR2I,
	ENUM,
	FILE_PATH,
	COLOR
}

@export var label : String = ""
@export var field : FieldMode = 0

@export_subgroup("Int")
@export var int_value : int = 0
@export var int_min : int = 0
@export var int_max : int = 100
@export var int_step : int = 1

@export_subgroup("Float")
@export var float_value : float = 0
@export var float_min : float = 0
@export var float_max : float = 1
@export var float_step : float = 0.001

@export_subgroup("Range")
@export var range_value : float = 0
@export var range_min : float = 0
@export var range_max : float = 1
@export var range_step : float = 0.001

@export_subgroup("String")
@export var string_value : String = ""

@export_subgroup("Vector2")
@export var vector2_label_x : String = "X"
@export var vector2_label_y : String = "Y"
@export var vector2_value : Vector2 = Vector2.ZERO
@export var vector2_min : Vector2 = Vector2.ZERO
@export var vector2_max : Vector2 = Vector2.ONE
@export var vector2_step : Vector2 = Vector2(0.001, 0.001)

@export_subgroup("Vector2i")
@export var vector2i_label_x : String = "X"
@export var vector2i_label_y : String = "Y"
@export var vector2i_value : Vector2i = Vector2i.ZERO
@export var vector2i_min : Vector2i = Vector2i.ZERO
@export var vector2i_max : Vector2i = Vector2i(100, 100)
@export var vector2i_step : Vector2i = Vector2i.ONE

@export_subgroup("Enum")
@export var enum_value : int = 0
@export var enum_option : Array[String] = []

@export_subgroup("File")
@export_file() var file_value : String = ""
@export var file_mode : FileDialog.FileMode = FileDialog.FILE_MODE_SAVE_FILE
@export var file_dialog_filters : PackedStringArray = ["*.png, *.jpg, *.jpeg ; Supported Images"]

@export_subgroup("Color")
@export var color_value : Color = Color.WHITE
@export var color_alpha : bool = true


static func create_int(
		d_label : String,
		d_value : int,
		d_min : int,
		d_max : int,
		d_step : int = 1
		) -> TreeRow:
	var row = TreeRow.new()
	row.field = FieldMode.INT
	row.label = d_label
	row.int_min = d_min
	row.int_max = d_max
	row.int_value = d_value
	row.int_step = d_step
	return row


static func create_float(
		d_label : String,
		d_value : float,
		d_min : float,
		d_max : float,
		d_step : float = 0.001
		) -> TreeRow:
	var row = TreeRow.new()
	row.field = FieldMode.FLOAT
	row.label = d_label
	row.float_min = d_min
	row.float_max = d_max
	row.float_value = d_value
	row.float_step = d_step
	return row


static func create_range(
		d_label : String,
		d_value : float,
		d_min : float,
		d_max : float,
		d_step : float = 0.001
		) -> TreeRow:
	var row = TreeRow.new()
	row.field = FieldMode.RANGE
	row.label = d_label
	row.range_min = d_min
	row.range_max = d_max
	row.range_value = d_value
	row.range_step = d_step
	return row


static func create_string(
		d_label : String,
		d_value : String
		) -> TreeRow:
	var row = TreeRow.new()
	row.field = FieldMode.STRING
	row.label = d_label
	row.string_value = d_value
	return row


static func create_vector2(
		d_label : String, 
		d_label_a : String,
		d_label_b : String,
		d_value : Vector2,
		d_min : Vector2,
		d_max : Vector2,
		d_step : Vector2 = Vector2.ONE
		) -> TreeRow:
	var row : TreeRow = TreeRow.new()
	row.label = d_label
	row.field = FieldMode.VECTOR2
	row.vector2_label_x = d_label_a
	row.vector2_label_y = d_label_b
	row.vector2_min = d_min
	row.vector2_max = d_max
	row.vector2_value = d_value
	row.vector2_step = d_step
	return row


static func create_vector2i(
		d_label : String, 
		d_label_a : String,
		d_label_b : String,
		d_value : Vector2i,
		d_min : Vector2i,
		d_max : Vector2i,
		d_step : Vector2i = Vector2i.ONE
		) -> TreeRow:
	var row : TreeRow = TreeRow.new()
	row.label = d_label
	row.field = FieldMode.VECTOR2I
	row.vector2i_label_x = d_label_a
	row.vector2i_label_y = d_label_b
	row.vector2i_min = d_min
	row.vector2i_max = d_max
	row.vector2i_value = d_value
	row.vector2i_step = d_step
	return row


static func create_enum(
		d_label : String,
		d_value : int,
		d_option : Array[String]
		) -> TreeRow:
	var row = TreeRow.new()
	row.field = FieldMode.ENUM
	row.label = d_label
	row.enum_value = d_value
	row.enum_option = d_option
	return row


static func create_file_path(
		d_label : String,
		d_value : String,
		d_file_mode : FileDialog.FileMode = FileDialog.FILE_MODE_SAVE_FILE,
		d_file_dialog_filters : PackedStringArray = ["*.png, *.jpg, *.jpeg ; Supported Images"]
		) -> TreeRow:
	var row = TreeRow.new()
	row.field = FieldMode.FILE_PATH
	row.label = d_label
	row.file_value = d_value
	row.file_mode = d_file_mode
	row.file_dialog_filters = d_file_dialog_filters
	return row


static func create_color(
		d_label : String,
		d_value : Color,
		d_alpha : bool
		) -> TreeRow:
	var row = TreeRow.new()
	row.field = FieldMode.COLOR
	row.label = d_label
	row.color_value = d_value
	row.color_alpha = d_alpha
	return row
	

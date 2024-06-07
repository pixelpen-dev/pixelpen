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
	FILE_PATH
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

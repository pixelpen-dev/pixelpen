@tool
extends Label


var data_debug : Dictionary = {}
var version : String


func _ready():
	visible = false
	text = ""
	if not PixelPen.state.need_connection(get_window()):
		return
	PixelPen.state.debug_log.connect(func(key, value):
			data_debug[key] = value
			)


func _enter_tree():
	if Engine.is_editor_hint():
		var cfg := ConfigFile.new()
		if cfg.load("res://addons/net.yarvis.pixel_pen/plugin.cfg") == OK:
			version = cfg.get_value("plugin", "version")
	else:
		version = ProjectSettings.get_setting("application/config/version")


func _process(_delta):
	if not PixelPen.state.need_connection(get_window()):
		text = ""
		return
	var txt = str(
		str("PixelPen v", version, "\n") if version != "" else "", "FPS: ",
		Engine.get_frames_per_second())
	data_debug["Memory"] = str(Performance.get_monitor(Performance.MEMORY_STATIC)/1000000, "/",
			Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1000000, " mb")
	for key in data_debug.keys():
		if str(data_debug[key]) == "":
			data_debug.erase(key)
		else:
			txt += str("\n", key , ": ", data_debug[key])
	text = txt


func _exit_tree():
	text = ""

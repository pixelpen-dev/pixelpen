@tool
extends LineEdit


var record_shorcut : Shortcut = Shortcut.new()


func _ready():
	editable = false
	grab_focus.call_deferred()


func _gui_input(event : InputEvent):
	if has_focus():
		if event.is_pressed():
			record_shorcut.events = [event]
			text = record_shorcut.get_as_text()

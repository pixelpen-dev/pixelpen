# Copyright: 2026, Bayu Santoso Widodo (https://github.com/bayu-sw/select-handle)
# License: MIT

class_name SelectLineEdit
extends Node

signal long_pressed

const CLICK_TIMEOUT = 150

@export var guide_size : int = 32
@export var dpi_scale : bool = true
@export var visible : bool = true

var line_edit : LineEdit
var left : SelectorGuideLine
var right : SelectorGuideLine
var caret : CaretGuideLine

var press_pos : Vector2
var press_time : float

var guide_visible : bool = true:
	set(v):
		guide_visible = v and visible
		if left:
			left.guide_visible = guide_visible
		if right:
			right.guide_visible = guide_visible
		if caret:
			caret.guide_visible = guide_visible
	get:
		return guide_visible and visible


func _enter_tree() -> void:
	var new_guide_size = guide_size
	if dpi_scale:
		var screen_dpi : int = DisplayServer.screen_get_dpi()
		new_guide_size = round(guide_size * screen_dpi / 160.0)
	caret = CaretGuideLine.new()
	caret.guide_visible = guide_visible
	caret.visible = false
	caret.custom_minimum_size = new_guide_size * Vector2i.ONE
	get_parent().add_child.call_deferred(caret)

	left = SelectorGuideLine.new()
	left.guide_visible = guide_visible
	left.visible = false
	left.custom_minimum_size = new_guide_size * Vector2i.ONE
	left.is_left = true
	get_parent().add_child.call_deferred(left)

	right = SelectorGuideLine.new()
	right.guide_visible = guide_visible
	right.visible = false
	right.custom_minimum_size = new_guide_size * Vector2i.ONE
	right.is_left = false
	get_parent().add_child.call_deferred(right)


func _exit_tree() -> void:
	if caret != null and caret.is_inside_tree():
		caret.queue_free()
	if left != null and left.is_inside_tree():
		left.queue_free()
	if right != null and right.is_inside_tree():
		right.queue_free()
	if line_edit != null and line_edit.gui_input.is_connected(_line_edit_gui_event):
		line_edit.gui_input.disconnect(_line_edit_gui_event)
	if line_edit != null and line_edit.focus_entered.is_connected(_line_edit_focus_entered):
		line_edit.focus_entered.disconnect(_line_edit_focus_entered)


func _ready() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		visible = true
	else:
		visible = false
	if get_parent() is LineEdit:
		line_edit = get_parent()
		line_edit.gui_input.connect(_line_edit_gui_event)
		line_edit.focus_entered.connect(_line_edit_focus_entered)


func _line_edit_gui_event(event):
	if line_edit == null:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				press_pos = event.position
				press_time = Time.get_ticks_msec()
				if line_edit.has_focus() and not line_edit.text.is_empty():
					guide_visible = true

			else:
				var dis = event.position.distance_to(press_pos)
				var delta = Time.get_ticks_msec() - press_time
				if dis == 0 and delta > CLICK_TIMEOUT:
					var column = SelectorLineUtils.column_word_under_caret(line_edit)
					line_edit.grab_focus()
					line_edit.select.call_deferred(column.x, column.y)
					long_pressed.emit()


func _line_edit_focus_entered():
	set_deferred("guide_visible", false)


class SelectorLineUtils extends RefCounted:
	static func get_caret_position(line_edit : LineEdit) -> int:
		var line = TextLine.new()
		var font = line_edit.get_theme_font("font")
		var font_size = line_edit.get_theme_font_size("font_size")
		var language = line_edit.language
		var text = line_edit.text
		if line_edit.secret:
			text = ""
			for i in range(line_edit.text.length()):
				text += line_edit.secret_character
		line.add_string(text, font, font_size, language)
		for i in range(line_edit.text.length() * 2):
			var step = line.get_line_width() / (line_edit.text.length() * 2)
			if line.hit_test(step * i) == line_edit.caret_column:
				return step * i
		return line.get_line_width() as int


	static func get_position_at_column(column : int, line_edit : LineEdit) -> int:
		var line = TextLine.new()
		var font = line_edit.get_theme_font("font")
		var font_size = line_edit.get_theme_font_size("font_size")
		var language = line_edit.language
		var text = line_edit.text
		if line_edit.secret:
			text = ""
			for i in range(line_edit.text.length()):
				text += line_edit.secret_character
		line.add_string(text, font, font_size, language)
		for i in range(line_edit.text.length() * 2):
			var step = line.get_line_width() / (line_edit.text.length() * 2)
			if line.hit_test(step * i) == column:
				return step * i
		return line.get_line_width() as int


	static func get_column_at_position(pos : float, line_edit : LineEdit) -> int:
		var line = TextLine.new()
		var font = line_edit.get_theme_font("font")
		var font_size = line_edit.get_theme_font_size("font_size")
		var language = line_edit.language
		var text = line_edit.text
		if line_edit.secret:
			text = ""
			for i in range(line_edit.text.length()):
				text += line_edit.secret_character
		line.add_string(text, font, font_size, language)
		for i in range(line_edit.text.length() * 2):
			var step = line.get_line_width() / (line_edit.text.length() * 2)
			if step * i >= pos:
				return line.hit_test(step * i)
		return line_edit.text.length()


	static func column_word_under_caret(line_edit : LineEdit) -> Vector2i:
		var result = Vector2i(0, line_edit.text.length())
		var update = func(column : int):
			var start : int = 0
			var end : int = line_edit.text.length()
			for i in range(column, 0, -1):
				if line_edit.text.length() <= i:
					continue
				if line_edit.text[i] == " ":
					start = mini(i + 1, line_edit.caret_column)
					break
			for i in range(column, end):
				if line_edit.text.length() <= i:
					continue
				if line_edit.text[i] == " ":
					end = i
					break
			return Vector2i(start, end)
		result = update.call(line_edit.caret_column)
		if result.x == result.y and line_edit.caret_column > 0:
			result = update.call(line_edit.caret_column - 1)
		if result.x >= result.y and line_edit.caret_column > 0:
			result = Vector2i(line_edit.caret_column - 1, line_edit.caret_column)
		return result


	static func _display_text(line_edit : LineEdit) -> String:
		if not line_edit.secret:
			return line_edit.text
		var s := ""
		for _i in range(line_edit.text.length()):
			s += line_edit.secret_character
		return s


	## Horizontal offset the text is shifted by due to non-left alignment. All the
	## position maths above measure from the text's start (x = 0); with centre/right
	## alignment the glyphs (and, when empty, the caret) are pushed right, so the
	## guides must be too. Returns 0 when the text overflows (LineEdit falls back to
	## left-aligned scrolling, which get_scroll_offset already covers).
	static func alignment_offset(line_edit : LineEdit) -> float:
		var align := line_edit.alignment
		if align == HORIZONTAL_ALIGNMENT_LEFT or align == HORIZONTAL_ALIGNMENT_FILL:
			return 0.0
		var line := TextLine.new()
		# Empty text → width 0, so the formula centres the bare caret.
		line.add_string(_display_text(line_edit), line_edit.get_theme_font("font"), line_edit.get_theme_font_size("font_size"), line_edit.language)
		var text_w := line.get_line_width()
		var inner_w := line_edit.size.x
		var sb := line_edit.get_theme_stylebox("normal")
		if sb != null:
			inner_w -= sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
		if text_w >= inner_w:
			return 0.0   # overflowing → left-aligned + scroll_offset handles it
		if align == HORIZONTAL_ALIGNMENT_RIGHT:
			return inner_w - text_w
		return (inner_w - text_w) * 0.5


class CaretGuideLine extends Control:

	var line_edit : LineEdit
	var drag : bool = false
	var guide_visible : bool = true


	func _get_minimum_size():
		return Vector2i(32, 32)


	func _ready() -> void:
		if get_parent() is LineEdit:
			line_edit = get_parent()
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		top_level = true


	func _draw():
		var rect = Rect2(Vector2.ZERO, size)
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = line_edit.get_theme_color("caret_color")
		var radius : int = round(size.x / 2)
		style_box.corner_radius_bottom_left = radius
		style_box.corner_radius_bottom_right = radius
		style_box.corner_radius_top_left = 0
		style_box.corner_radius_top_right = radius
		draw_set_transform(Vector2(4 + size.x / 2, 0), PI / 4)
		draw_style_box(style_box, rect)


	func _process(_delta):
		if line_edit == null:
			return
		visible = guide_visible and not line_edit.has_selection() and line_edit.has_focus()
		position.x = SelectorLineUtils.get_caret_position(line_edit) - (size.x / 2)
		position.x += line_edit.get_scroll_offset() + SelectorLineUtils.alignment_offset(line_edit)
		@warning_ignore("integer_division")
		position.y = (line_edit.size.y / 2) + line_edit.get_theme_font_size("font_size") / 2
		position += line_edit.global_position


	func _input(event):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not event.pressed:
					drag = false


	func _gui_input(event: InputEvent) -> void:
		if line_edit == null:
			return
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				drag = event.pressed
		if event is InputEventMouseMotion and drag:
			var caret_new_pos = line_edit.get_local_mouse_position().x - line_edit.get_scroll_offset() - SelectorLineUtils.alignment_offset(line_edit) - (size.x / 4)
			var caret_line_column = SelectorLineUtils.get_column_at_position(caret_new_pos, line_edit)
			line_edit.caret_column = caret_line_column



class SelectorGuideLine extends Control:
	@export var is_left : bool = true

	var line_edit : LineEdit

	var anchor_start : int
	var anchor_end : int

	var drag : bool = false
	var drag_offset : int

	var guide_visible : bool = true

	func _get_minimum_size() -> Vector2:
		return Vector2(32, 32)


	func _ready() -> void:
		if get_parent() is LineEdit:
			line_edit = get_parent()
		top_level = true
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


	func _draw() -> void:
		var rect = Rect2(Vector2.ZERO, size)
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = line_edit.get_theme_color("caret_color")
		var radius : int = round(size.x / 2)
		style_box.corner_radius_bottom_left = radius
		style_box.corner_radius_bottom_right = radius
		style_box.corner_radius_top_left = radius if is_left else 0
		style_box.corner_radius_top_right = 0 if is_left else radius
		draw_style_box(style_box, rect)


	func _process(_delta: float) -> void:
		if line_edit == null:
			return
		visible = guide_visible and line_edit.has_selection()
		if not visible:
			return
		var lc_caret = line_edit.get_selection_to_column()
		var lc_origin = line_edit.get_selection_from_column()
		var case = lc_origin < lc_caret
		var lc_start = lc_origin if case else lc_caret
		anchor_start = SelectorLineUtils.get_position_at_column(lc_start, line_edit)
		var lc_end = lc_caret if case else lc_origin
		anchor_end = SelectorLineUtils.get_position_at_column(lc_end, line_edit)
		if is_left:
			position.x = anchor_start - round(size.x)
		else:
			position.x = anchor_end
		position.x += line_edit.get_scroll_offset() + SelectorLineUtils.alignment_offset(line_edit)
		@warning_ignore("integer_division")
		position.y = (line_edit.size.y / 2) + line_edit.get_theme_font_size("font_size") / 2
		position += line_edit.global_position


	func _input(event):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not event.pressed:
					drag = false


	func _gui_input(event: InputEvent) -> void:
		if line_edit == null:
			return
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				drag = event.pressed
				if drag:
					if is_left:
						drag_offset = anchor_start - line_edit.get_local_mouse_position().x as int
					else:
						drag_offset = anchor_end - line_edit.get_local_mouse_position().x as int
				queue_redraw()
		if event is InputEventMouseMotion and drag:
			var pos : int = line_edit.get_local_mouse_position().x as int + drag_offset
			var lc_target : int = SelectorLineUtils.get_column_at_position(pos, line_edit)
			var lc_caret = line_edit.get_selection_to_column()
			var lc_origin = line_edit.get_selection_from_column()
			var case = lc_origin < lc_caret
			if is_left:
				if case:
					if  lc_target < lc_caret:
						line_edit.select(lc_target, lc_caret)
						line_edit.caret_column = lc_target
				else:
					if lc_origin > lc_target:
						line_edit.select(lc_origin, lc_target)
						line_edit.caret_column = lc_target
			else:
				if case:
					if lc_origin < lc_target:
						line_edit.select(lc_origin, lc_target)
						line_edit.caret_column = lc_target
				else:
					if lc_target > lc_caret:
						line_edit.select(lc_target, lc_caret)
						line_edit.caret_column = lc_target

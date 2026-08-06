@tool
class_name PixelPenAboutDialog
extends PixelPenDialog


const PLUGIN_CFG := "res://addons/net.yarvis.pixel_pen/plugin.cfg"
const ICON_PATH := "res://addons/net.yarvis.pixel_pen/resources/icon/Icon.png"
const REPO_URL := "https://github.com/pixelpen-dev/pixelpen"
const AUTHOR_URL := REPO_URL + "/blob/main/AUTHOR.md"
const LICENSE_URL := REPO_URL + "/blob/main/COPYRIGHT.txt"
const COPYRIGHT_LINE := "MIT Licence · © 2024–present Bayu Santoso Widodo"

const MUTED_COLOR := Color(0.6, 0.6, 0.6)
const DIM_COLOR := Color(0.49, 0.49, 0.49)


func _init():
	super("About", "Close", Vector2i(340, 0))
	add_to_group("pixelpen_popup")
	cancel_button.visible = false
	_build()


func _build():
	var cfg := ConfigFile.new()
	cfg.load(PLUGIN_CFG)
	var content := get_content()

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	var icon := TextureRect.new()
	icon.texture = load(ICON_PATH)
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(icon)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var app_name := Label.new()
	app_name.text = cfg.get_value("plugin", "name", "PixelPen")
	app_name.add_theme_font_size_override("font_size", 17)
	name_row.add_child(app_name)
	var version := Label.new()
	version.text = cfg.get_value("plugin", "version", "")
	version.add_theme_color_override("font_color", DIM_COLOR)
	version.add_theme_font_size_override("font_size", 12)
	version.size_flags_vertical = Control.SIZE_SHRINK_END
	name_row.add_child(version)
	titles.add_child(name_row)
	var description := Label.new()
	description.text = cfg.get_value("plugin", "description", "")
	description.add_theme_color_override("font_color", MUTED_COLOR)
	description.add_theme_font_size_override("font_size", 12)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(200, 0)
	titles.add_child(description)
	header.add_child(titles)
	content.add_child(header)

	content.add_child(HSeparator.new())

	var credits := Label.new()
	var engine := Engine.get_version_info()
	credits.text = str("Created by ", cfg.get_value("plugin", "author", ""),
			"\nBuilt with Godot ", engine["major"], ".", engine["minor"], ".", engine["patch"])
	credits.add_theme_color_override("font_color", MUTED_COLOR)
	credits.add_theme_font_size_override("font_size", 12)
	content.add_child(credits)

	content.add_child(_link("Source code", REPO_URL))
	content.add_child(_link("Contributors", AUTHOR_URL))
	content.add_child(_link("Licence", LICENSE_URL))

	content.add_child(HSeparator.new())

	var footer := Label.new()
	footer.text = COPYRIGHT_LINE
	footer.add_theme_color_override("font_color", DIM_COLOR)
	footer.add_theme_font_size_override("font_size", 11)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.custom_minimum_size = Vector2(290, 0)
	content.add_child(footer)


func _link(text : String, url : String) -> LinkButton:
	var link := LinkButton.new()
	link.text = text
	link.uri = url
	link.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	link.focus_mode = Control.FOCUS_NONE
	link.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	link.add_theme_color_override("font_color", PixelPen.state.userconfig.accent_color)
	link.add_theme_color_override("font_hover_color", PixelPen.state.userconfig.accent_color.lightened(0.25))
	link.add_theme_font_size_override("font_size", 12)
	return link

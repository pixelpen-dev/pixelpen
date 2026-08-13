@tool
class_name PixelPenAboutDialog
extends PixelPenDialog


const ICON_PATH := "res://addons/net.yarvis.pixel_pen/resources/icon/Icon.png"

func _init():
	super("About", "Close", Vector2i(340, 0))
	add_to_group("pixelpen_popup")
	cancel_button.visible = false
	_build()


func _build():
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
	app_name.text = PixelPenAbout.NAME
	app_name.theme_type_variation = &"TitleLabel"
	name_row.add_child(app_name)
	var version := Label.new()
	version.text = PixelPenAbout.VERSION
	version.theme_type_variation = &"TitleDimLabel"
	name_row.add_child(version)
	titles.add_child(name_row)
	var description := Label.new()
	description.text = PixelPenAbout.DESCRIPTION
	description.theme_type_variation = &"MutedLabel"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(200, 0)
	titles.add_child(description)
	header.add_child(titles)
	content.add_child(header)

	content.add_child(HSeparator.new())

	var credits := Label.new()
	var engine := Engine.get_version_info()
	credits.text = str("Created by ", PixelPenAbout.AUTHOR,
			"\nBuilt with Godot ", engine["major"], ".", engine["minor"], ".", engine["patch"])
	credits.theme_type_variation = &"MutedLabel"
	content.add_child(credits)

	content.add_child(_link("Source code", PixelPenAbout.REPO_URL))
	content.add_child(_link("Contributors", PixelPenAbout.AUTHOR_URL))
	content.add_child(_link("Licence", PixelPenAbout.LICENSE_URL))

	content.add_child(HSeparator.new())

	var footer := Label.new()
	footer.text = PixelPenAbout.COPYRIGHT
	footer.theme_type_variation = &"DimLabel"
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
	link.theme_type_variation = &"AccentLink"
	link.add_theme_color_override("font_color", PixelPen.state.userconfig.accent_color)
	link.add_theme_color_override("font_hover_color", PixelPen.state.userconfig.accent_color.lightened(0.25))
	return link

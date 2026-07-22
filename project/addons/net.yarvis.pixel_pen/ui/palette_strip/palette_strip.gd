@tool
class_name PixelPenPaletteStrip
extends TextureRect


const COLUMNS : int = 12
const CELL_FALLBACK : float = 17.0

## Upper bound on the strip's height in pixels. 0 = unbounded. When the palette
## has more rows than fit, the preview scales down instead of pushing sibling
## nodes out of the window.
@export var max_height : float = 0.0


func _init():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE


func set_colors(palette : PackedColorArray):
	var colors : Array[Color] = []
	for color in palette:
		if color.a > 0:
			colors.push_back(color)
	if colors.is_empty():
		visible = false
		texture = null
		return
	var rows : int = ceili(colors.size() / float(COLUMNS))
	var strip : Image = Image.create(COLUMNS, rows, false, Image.FORMAT_RGBA8)
	for n in range(colors.size()):
		strip.set_pixel(n % COLUMNS, n / COLUMNS, colors[n])
	var cell : float = size.x / float(COLUMNS) if size.x > 0.0 else CELL_FALLBACK
	var height : float = rows * cell
	if max_height > 0.0:
		height = minf(height, max_height)
	custom_minimum_size = Vector2(0, height)
	texture = ImageTexture.create_from_image(strip)
	visible = true

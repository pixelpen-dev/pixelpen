shader_type canvas_item;


uniform vec3 tint : source_color;


void fragment() {
	COLOR.rgb = tint;
}

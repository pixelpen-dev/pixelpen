shader_type canvas_item;


uniform vec4 tint : source_color;


void fragment() {
	float greyscale = COLOR.r * 0.299 + COLOR.g * 0.587 + COLOR.b * 0.114;
	COLOR.rgb = mix(vec3(greyscale), tint.rgb, 0.5); 
	COLOR.a *= tint.a;
}

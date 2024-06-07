shader_type canvas_item;


uniform sampler2D screen_uv : hint_screen_texture, filter_nearest;


void fragment() {
	vec4 screen = texture(screen_uv, SCREEN_UV);
	float value = max(max(screen.r, screen.g), screen.b);
	bool magenta = COLOR.rgb == vec3(1, 0, 1);
	if(!magenta){
		COLOR.rgb = mix(vec3(1.0), vec3(0.0), step(0.5, value));
	}
}

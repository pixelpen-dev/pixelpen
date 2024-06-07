shader_type canvas_item;


uniform sampler2D screen_uv : hint_screen_texture, filter_nearest;
uniform bool grayscale = false;


void fragment() {
	if(grayscale){
		vec4 screen = texture(screen_uv, SCREEN_UV);
		COLOR.rgb = vec3(screen.r * 0.299 + screen.g * 0.587 + screen.b * 0.114);
	}else{
		COLOR.a = 0.0;
	}
}

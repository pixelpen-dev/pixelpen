shader_type canvas_item;

uniform bool enable = true;
uniform bool marching_ant = true;
uniform vec2 zoom_bias;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
varying vec2 model_vertex;
uniform float width : hint_range(0, 2) = 0.05;

const float C = 0.05;


void vertex() {
	model_vertex = VERTEX;
}


void fragment() {
	if(enable){
		// Outline Margin
		vec2 epsilon = TEXTURE_PIXEL_SIZE / zoom_bias;
		float a = texture(TEXTURE, UV + vec2(-epsilon.x, -epsilon.y)).r;
		a *= texture(TEXTURE, UV + vec2(epsilon.x, -epsilon.y)).r;
		a *=  texture(TEXTURE, UV + vec2(epsilon.x, epsilon.y)).r;
		a *=  texture(TEXTURE, UV + vec2(-epsilon.x, epsilon.y)).r;
		
		COLOR.a = max(0.0, COLOR.r - a);
		COLOR.a = min(0.5, COLOR.a);
		
		// Outline
		vec4 screen = texture(screen_texture, SCREEN_UV);
		float value = max(max(screen.r, screen.g), screen.b);
		value = step(0.5, value);
		
		// Marching ant
		vec2 uv = UV * zoom_bias * C / TEXTURE_PIXEL_SIZE ; 
		uv -= TIME;
		// Generate Checker
		vec2 checker = step(fract(uv), vec2(0.5));
		float ant = mix(1.0 - checker.x, checker.x, checker.y);
		if(!marching_ant){
			ant = 1.0;
		}
		
		COLOR.rgb = vec3(mix(ant, 1.0 - ant, value));
	}
}

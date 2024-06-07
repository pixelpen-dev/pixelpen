shader_type canvas_item;

uniform bool enable = true;
uniform bool marching_ant = true;
uniform bool fill = false;
uniform vec4 outline_color : source_color = vec4(0.0);
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
		vec2 epsilon = TEXTURE_PIXEL_SIZE  / zoom_bias;
		if(outline_color.a > 0.0){
			epsilon *= 1.5;
		}
		float a = texture(TEXTURE, UV + vec2(-epsilon.x, -epsilon.y)).a;
		a *= texture(TEXTURE, UV + vec2(epsilon.x, -epsilon.y)).a;
		a *=  texture(TEXTURE, UV + vec2(epsilon.x, epsilon.y)).a;
		a *=  texture(TEXTURE, UV + vec2(-epsilon.x, epsilon.y)).a;
		a = max(0.0, COLOR.a - a);
		a = min(0.5, a);
		
		// Outline
		float value;
		if(fill){
			vec4 screen = texture(TEXTURE, UV);
			value = max(max(screen.r, screen.g), screen.b);
		}else{
			vec4 screen = texture(screen_texture, SCREEN_UV);
			value = max(max(screen.r, screen.g), screen.b);
		}
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

		vec3 checker_ant = vec3(mix(ant, 1.0 - ant, value));
		float rig = mix( mix(ant, 1.0 - ant, value), mix(1.0 - ant, ant, value), value);
		if(!marching_ant){
			rig = 0.0;
		}
		vec3 outline_colored = vec3(mix(outline_color.rgb, checker_ant, rig));
		
		vec3 outline = mix(checker_ant, outline_colored, outline_color.a);
		if(fill){
			COLOR.rgb = mix(COLOR.rgb, outline, a);
			COLOR.a = max(a, COLOR.a);
		}else{
			COLOR.rgb = outline;
			COLOR.a = a;
		}
		
	}
}

shader_type canvas_item;


vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void fragment(){
	if(COLOR.rgb == vec3(0.0)){
		COLOR.rgb = vec3(1.0);
	}else{
		COLOR.rgb = hsv2rgb(vec3(UV.x, 1.0, 1.0));
	}
}

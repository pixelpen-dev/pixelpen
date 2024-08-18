shader_type canvas_item;


uniform float hue : hint_range(0.0, 1.0, 0.001);


vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void fragment(){
	COLOR.rgb = hsv2rgb(vec3(hue, UV.x, 1.0 - UV.y));
}

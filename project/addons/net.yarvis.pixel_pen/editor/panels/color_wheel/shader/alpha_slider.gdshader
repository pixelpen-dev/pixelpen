shader_type canvas_item;


uniform float alpha : hint_range(0.0, 1.0, 0.001) = 1.0;


varying vec2 vert;


void vertex(){
	vert = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
	vec2 coor = vert * SCREEN_PIXEL_SIZE.x * 128.0;
	coor = mod(coor, 1.0);
	coor = step(coor, vec2(0.5));
	vec3 checker = vec3(mix(1.0 - coor.x, coor.x, coor.y)) * 0.2 + 0.4;
	COLOR.rgb = mix(checker, COLOR.rgb, UV.x * alpha);
}

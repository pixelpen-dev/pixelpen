shader_type canvas_item;

uniform vec2 origin;
uniform vec4 tint = vec4(0.0);
uniform vec2 tile_size = vec2(16.0);
uniform float lock_to_global = 1.0;

varying vec2 world_vertex;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy - origin;
	world_vertex = mix(VERTEX, world_vertex, lock_to_global);
}

void fragment() {
	vec2 coor = mod(world_vertex, tile_size * 2.0);
	vec2 checker = step(coor, tile_size);
	COLOR.rgb = mix(vec3(mix(1.0 - checker.x, checker.x, checker.y)) * 0.2 + 0.5, tint.rgb, tint.a);
	COLOR.a = max(COLOR.a, tint.a);
}

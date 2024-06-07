shader_type canvas_item;

uniform vec2 image_size;
uniform sampler2D index_color : source_color;
uniform sampler2D color_map;
uniform float silhouette;
uniform vec3 silhouette_tint : source_color = vec3(0.0); 


varying vec2 local_vertex;

void vertex() {
	local_vertex = VERTEX;
}

void fragment() {
	vec2 world_tile_index = floor(local_vertex * image_size);
	float color_coords_float = texelFetch(color_map, ivec2(world_tile_index), 0).r;
	int color_coords = int(floor(color_coords_float * 256.0));
	COLOR = texelFetch(index_color, ivec2(color_coords, 0), 0);
	COLOR.rgb = mix(COLOR.rgb, silhouette_tint, silhouette);
}

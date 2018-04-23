extern number x_offset;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	vec2 new_coords = vec2(texture_coords.x - x_offset, texture_coords.y);
	return Texel(texture, new_coords);
}

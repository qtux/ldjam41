extern number intensity;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	color = Texel(texture, texture_coords);
	return vec4(color.rgb * intensity, color.a);
}

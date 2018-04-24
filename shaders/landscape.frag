extern number intensity;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	color = Texel(texture, texture_coords);
	// replace color of mountains
	if (color.g == 114.0 / 255.0) {
		float factor = pow(70 / pixel_coords.y, 4) + 70 / pixel_coords.y;
		color = vec4(0.4 * factor, 0.4 * factor, 0.4 * factor, 1);
	}
	return vec4(color.rgb * intensity, color.a);
}

extern number intensity;
extern number sun_x;
extern number sun_y;
extern number sun_r;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
	// background color
	vec3 bg_color = vec3(0.8, 0.9, 1) * intensity;
	
	// sun color
	float dist = distance(pixel_coords, vec2(sun_x, sun_y));
	float sun_intensity = smoothstep(sun_r + 10, sun_r - 10, dist);
	vec3 sun_color = vec3(1, 1, 0.7) * sun_intensity;
	
	// mix background and sun
	return vec4(mix(bg_color, sun_color, pow(sun_intensity, 2)), 1.0);
}

shader_type canvas_item;
render_mode unshaded;

uniform float tension : hint_range(0.0, 1.0) = 0.0;
uniform float effect_time = 0.0;
uniform float flicker_spike : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float distance_from_center = length(centered);
	float inner_edge = mix(0.62, 0.22, tension);
	float vignette = smoothstep(inner_edge, 0.72, distance_from_center);

	float slow_flicker = 0.5 + 0.5 * sin(effect_time * 7.3);
	float fast_flicker = 0.5 + 0.5 * sin(effect_time * 19.7 + 1.4);
	float noise = hash(floor(UV * 96.0) + floor(effect_time * 18.0));
	float pulse = slow_flicker * 0.045 + fast_flicker * 0.025 + noise * 0.025;
	float alpha = tension * (vignette * mix(0.20, 0.78, tension) + pulse
			+ flicker_spike * (0.18 + noise * 0.22));
	vec3 dark_red = mix(vec3(0.10, 0.0, 0.01), vec3(0.25, 0.0, 0.02),
			vignette + flicker_spike * 0.35);
	COLOR = vec4(dark_red, clamp(alpha, 0.0, 0.88));
}

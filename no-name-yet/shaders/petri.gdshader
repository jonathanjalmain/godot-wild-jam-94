shader_type canvas_item;

uniform vec4 col_top : source_color = vec4(0.05, 0.10, 0.12, 1.0);
uniform vec4 col_bottom : source_color = vec4(0.03, 0.06, 0.08, 1.0);
uniform vec4 cell_color : source_color = vec4(0.20, 0.45, 0.40, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec3 base = mix(col_top.rgb, col_bottom.rgb, uv.y);

	// Soft drifting out-of-focus cells
	float glow = 0.0;
	for (int i = 0; i < 8; i++) {
		float fi = float(i);
		vec2 seed = vec2(hash(vec2(fi, 1.0)), hash(vec2(fi, 7.0)));
		vec2 p = vec2(
			fract(seed.x + TIME * 0.012 * (0.4 + seed.x)),
			fract(seed.y + TIME * 0.016 * (0.4 + seed.y))
		);
		float d = distance(uv * vec2(1.78, 1.0), p * vec2(1.78, 1.0));
		float radius = 0.10 + 0.09 * seed.x;
		glow += smoothstep(radius, 0.0, d) * (0.12 + 0.06 * seed.y);
	}

	vec3 color = base + cell_color.rgb * glow;

	// Vignette toward the edges
	float v = smoothstep(1.15, 0.35, distance(uv, vec2(0.5)));
	color *= mix(0.55, 1.0, v);

	COLOR = vec4(color, 1.0);
}

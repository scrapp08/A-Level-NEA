shader_type spatial;
render_mode world_vertex_coords;

// Debug
uniform bool debug_noise = false;
uniform bool debug_falloff = false;

// Mesh
uniform int size = 150;
uniform int resolution = 300;
uniform int amplitude = 0;

// Noise
uniform sampler2D noise : hint_default_black;

// Falloff
uniform bool gen_falloff = true;
uniform float falloff_start = 0.0;
uniform float falloff_end = 1.0;


vec3 srgb_to_linear(vec3 c) {
	return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}


float falloff(float x, float y) {
	vec2 position = vec2(
		x / float(resolution) * 2.0 - 1.0,
		y / float(resolution) * 2.0 - 1.0
	);

	float t = max(abs(position.x), abs(position.y));
	if (t <= falloff_start) {
		return 1.0;
	}
	else if (t >= falloff_end) {
		return 0.0;
	}
	else {
		return smoothstep(1.0, 0.0, mix(falloff_start, falloff_end, t));
	}
}


void vertex() {
	if (gen_falloff) {
		float value = srgb_to_linear(textureLod(noise, UV, 0).rgb).r;
		VERTEX.y = value * float(amplitude) * falloff(UV.x, UV.y);
	}
	else {
		float value = srgb_to_linear(textureLod(noise, UV, 0).rgb).r;
		VERTEX.y = value * float(amplitude);
	}
}


void fragment() {
	float noise_sample = textureLod(noise, UV, 0).r;
	ALBEDO = srgb_to_linear(vec3(noise_sample));

	if (debug_noise) {
		ALBEDO = srgb_to_linear(vec3(noise_sample));
	}

	if (debug_falloff) {
		ALBEDO = srgb_to_linear(vec3(falloff(UV.x, UV.y)));
	}
}

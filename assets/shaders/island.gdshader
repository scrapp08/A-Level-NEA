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

uniform sampler2D terrain_colour;
uniform float max_height = 1;

varying float vertex_y;

vec3 srgb_to_linear(vec3 c) {
	return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}


float inverse_lerp(float a, float b, float value) {
	float val = (value - a) / (b - a);
	return clamp(0.01, 1.0, val);
}


float falloff(float x, float y) {
//	vec2 position = vec2(
//		x / float(resolution) * 2.0 - 1.0,
//		y / float(resolution) * 2.0 - 1.0
//	);
	vec2 position = vec2(
		(x - 0.5) * 2.0,
		(y - 0.5) * 2.0
	);

	float t = max(abs(position.x), abs(position.y));
	if (t <= falloff_start) {
		return 1.0;
	}
	else if (t > falloff_end) {
		return 0.0;
	}
	else {
		return smoothstep(1.0, 0.0, inverse_lerp(falloff_start, falloff_end, t));
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
	vertex_y = VERTEX.y;
}


void fragment() {
	float noise_sample = textureLod(noise, UV, 0).r;
	float position = inverse_lerp(0.0, float(max_height), vertex_y);
	ALBEDO = texture(terrain_colour, vec2(position, 0)).rgb;

	if (debug_noise) {
		ALBEDO = srgb_to_linear(vec3(noise_sample));
		if (gen_falloff) {
			ALBEDO = srgb_to_linear(vec3(noise_sample) * vec3(falloff(UV.x, UV.y)));
		}
	}

	if (debug_falloff) {
		ALBEDO = srgb_to_linear(vec3(falloff(UV.x, UV.y)));
	}
}

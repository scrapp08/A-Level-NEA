shader_type spatial;
render_mode world_vertex_coords;

//#include "res://assets/shaders/heightmap.gdshaderinc"

// Debug
uniform bool debug_noise = false;
uniform bool debug_falloff = false;

// Mesh
//uniform int size = 150;
//uniform int resolution = 300;
uniform float amplitude = 0.0;

// Noise
uniform sampler2D noise : hint_default_black;

// Falloff
uniform bool gen_falloff = true;
uniform float falloff_start = 0.0;
uniform float falloff_end = 1.0;

uniform sampler2D terrain_colour;

varying vec3 vertex_position;



vec3 srgb_to_linear(vec3 c) {
	return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}


float inverse_lerp(float a, float b, float value) {
	float val = (value - a) / (b - a);
	return clamp(0.01, 1.0, val);
}


float falloff(float x, float y) {
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


vec3 xform(mat4 matrix, vec3 position, const float w){
	return (matrix * vec4(position, w)).xyz;
}


vec4 sample_texture(sampler2D texture_map, vec3 position) {
	vec2 texture_size = vec2(textureSize(texture_map, 0));
	vec2 texture_scale = texture_size / 2.0;

	mat4 terrainToWorld = mat4(1);
	terrainToWorld[0] *= texture_scale.x*2.0;
	terrainToWorld[1] *= amplitude;
	terrainToWorld[2] *= texture_scale.y*2.0;
	terrainToWorld[3].xyz = vec3(-texture_scale.x,0,-texture_scale.y);

	position = xform(inverse(terrainToWorld), position, 1.0);

	vec4 pixel = vec4(srgb_to_linear(textureLod(texture_map, position.xz, 0).rgb), 1.0);
	return pixel;
}


vec3 sample_normal(vec3 position) {
	float epsilon = 1.0;
	float sample_left = sample_texture(noise, position + vec3(-epsilon, 0, 0)).x * amplitude;
	float sample_right = sample_texture(noise, position + vec3(epsilon, 0, 0)).x * amplitude;
	float sample_up = sample_texture(noise, position + vec3(0, 0, -epsilon)).x * amplitude;
	float sample_down = sample_texture(noise, position + vec3(0, 0, epsilon)).x * amplitude;
	vec2 g = vec2(sample_right-sample_left, sample_down-sample_up) / epsilon; //-Four Samples, difference across point
	vec3 normals = normalize(vec3(-g.x, 1.0, -g.y));
	return normals;
}


void vertex() {
	if (gen_falloff) {
		float value = srgb_to_linear(textureLod(noise, UV, 0).rgb).r;
		VERTEX.y = value * amplitude * falloff(UV.x, UV.y) * 2.5;
	}
	else {
		float value = srgb_to_linear(textureLod(noise, UV, 0).rgb).r;
//		float value = textureLod(noise, UV, 0).r;
		VERTEX.y = value * amplitude;
	}
	vertex_position = VERTEX;
}


void fragment() {
	float noise_sample = textureLod(noise, UV, 0).r;
	float position = inverse_lerp(0.0, float(amplitude) * 2.5, vertex_position.y);
	ALBEDO = texture(terrain_colour, vec2(position, 0)).rgb;
	if ((mod(vertex_position.x, 0.5) <= 0.1) || (mod(vertex_position.z, 0.5) <= 0.1)) {
		ALBEDO = vec3(0);
	}

	if (debug_noise) {
		ALBEDO = srgb_to_linear(vec3(noise_sample));
		if (gen_falloff) {
			ALBEDO = srgb_to_linear(vec3(noise_sample) * vec3(falloff(UV.x, UV.y)));
		}
	}

	if (debug_falloff) {
		ALBEDO = srgb_to_linear(vec3(falloff(UV.x, UV.y)));
	}

	vec3 normals_frag = sample_normal(vertex_position);
	normals_frag = xform(VIEW_MATRIX, normals_frag, 0.0).xyz;
	NORMAL = normals_frag;
}

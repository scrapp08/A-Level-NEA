shader_type spatial;

uniform sampler2D terrain_colour;

uniform float min_height = 0;
uniform float max_height = 1;

varying float vertex_y;

float inverse_lerp(float a, float b, float value) {
	float val = (value - a) / (b - a);
	return clamp(0.01, 1.0, val);
}


void fragment() {
	float height  = vertex_y;
	float position = inverse_lerp(min_height, max_height, height);
	vec3 colour = texture(terrain_colour, vec2(position, 0)).rgb;
	ALBEDO = colour;
}


void vertex() {
	vertex_y = VERTEX.y;
}
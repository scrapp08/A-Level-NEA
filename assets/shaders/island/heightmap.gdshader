shader_type canvas_item;

uniform sampler2D noise : hint_default_black;

void fragment() {
	float noise_sample = textureLod(noise, UV, 0).r;
	COLOR = vec4(vec3(noise_sample), 1.0);
}

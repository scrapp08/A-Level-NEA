shader_type canvas_item;

uniform sampler2D noise : hint_default_black;
uniform sampler2D falloff : hint_default_black;

void fragment() {
	float noise_map = textureLod(noise, UV, 0).r;
	float falloff_map = texture(falloff, UV, 0).r;
	float resultant = noise_map * falloff_map;
	COLOR = vec4(vec3(resultant), 1.0);
}

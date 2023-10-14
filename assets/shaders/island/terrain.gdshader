shader_type spatial;

render_mode world_vertex_coords;

uniform sampler2D height_map : hint_default_black;
uniform float height_scale = 10.0;

varying smooth vec3 vertex_position;

vec3 srgb_to_linear(vec3 c) {
	return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}

vec3 xform(mat4 matrix, vec3 position, const float w){
	return (matrix * vec4(position, w)).xyz;
}

vec4 sample_texture(sampler2D texture_map, vec3 position) {
	vec2 size = vec2(textureSize(texture_map, 0));
	vec2 scale = size / 2.0;

	mat4 terrainToWorld = mat4(1);
	terrainToWorld[0] *= scale.x*2.0;
	terrainToWorld[1] *= height_scale;
	terrainToWorld[2] *= scale.y*2.0;
	terrainToWorld[3].xyz = vec3(-scale.x,0,-scale.y);

	position = xform(inverse(terrainToWorld), position, 1.0);

	vec4 pixel = vec4(srgb_to_linear(textureLod(texture_map, position.xz, 0).rgb), 1.0);
	return pixel;
}

vec3 sample_normal(vec3 position) {
	float epsilon = 1.0;
	float sample_left = sample_texture(height_map, position + vec3(-epsilon, 0, 0)).x * height_scale;
	float sample_right = sample_texture(height_map, position + vec3(epsilon, 0, 0)).x * height_scale;
	float sample_up = sample_texture(height_map, position + vec3(0, 0, -epsilon)).x * height_scale;
	float sample_down = sample_texture(height_map, position + vec3(0, 0, epsilon)).x * height_scale;
	vec2 g = vec2(sample_right-sample_left, sample_down-sample_up) / epsilon; //-Four Samples, difference across point
	vec3 normals = normalize(vec3(-g.x, 1.0, -g.y));
	return normals;
}

void vertex() {
	float value =  sample_texture(height_map, VERTEX).r;
//	float value =  textureLod(height_map, UV, 0).r;
	VERTEX.y = value * height_scale;
	vertex_position = VERTEX;
}

void fragment() {
//	ALBEDO = srgb_to_linear(textureLod(height_map, vertex_position.xz, 0).rgb);
	ALBEDO = sample_texture(height_map, vertex_position).rgb;
	vec3 normals_frag = sample_normal(vertex_position);
	normals_frag = xform(VIEW_MATRIX, normals_frag, 0.0).xyz;
	NORMAL = normals_frag;
}

shader_type spatial;
render_mode world_vertex_coords, diffuse_toon, specular_toon, cull_disabled, depth_draw_always;

uniform vec4 wave_a = vec4(1, 1, 0.5, 50);
uniform vec4 wave_b = vec4(0, 1, 0.25, 20);
uniform vec4 wave_c = vec4(1, 1, 0.15, 10);


void fragment(){
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	RIM = 0.2;
	METALLIC = 0.0;
	ROUGHNESS = 0.01 * (1.0 - fresnel);
	ALBEDO = vec3(0.01, 0.03, 0.05) + (0.1 * fresnel);
}

vec3 GerstnerWave(
	vec4 wave, vec3 p, inout vec3 tangent, inout vec3 binormal
) {
	float steepness = wave.z;
	float wavelength = wave.w;
	float k = float(2) * PI / wavelength;
	float c = sqrt(9.8 / k);
	vec2 d = normalize(wave.xy);
	float f = k * (dot(d, p.xz) - c * TIME);
	float a = steepness / k;
	tangent += vec3(
		-d.x * d.x * (steepness * sin(f)),
		d.x * (steepness * cos(f)),
		-d.x * d.y * (steepness * sin(f))
	);
	binormal += vec3(
		-d.x * d.y * (steepness * sin(f)),
		d.y * (steepness * cos(f)),
		-d.y * d.y * (steepness * sin(f))
	);
	return vec3(
		d.x * (a * cos(f)),
		a * sin(f),
		d.y * (a *cos(f))
	);
}


void vertex() {
	vec3 grid_point = VERTEX.xyz;
	vec3 tangent = vec3(1, 0, 0);
	vec3 binormal = vec3(0 ,0 , 1);
	vec3 p = grid_point;
//	Lerp through from max to min wave parameters in a for loop of number of waves
	p += GerstnerWave(wave_a, grid_point, tangent, binormal);
	p += GerstnerWave(wave_b, grid_point, tangent, binormal);
	p += GerstnerWave(wave_c, grid_point, tangent, binormal);
	vec3 normal = normalize(cross(binormal, tangent));
	VERTEX.xyz = p;
	NORMAL = normal;
}

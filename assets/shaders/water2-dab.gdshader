shader_type spatial;
render_mode world_vertex_coords, diffuse_toon, specular_toon, cull_disabled, depth_draw_always;//, cull_disabled;//, blend_add;
//render_mode world_vertex_coords, cull_disabled, depth_draw_always;//, cull_disabled;//, blend_add;

uniform bool _debug_dampen = false;
uniform bool _debug_depth_tex = false;
uniform float _debug_flat_shade : hint_range(0.0, 1.0) = 0.0;
uniform bool _debug_fresnel = false;
uniform bool _debug_normal_frag = false;
uniform bool _debug_normal_vert = false;
uniform bool _debug_refract = false;
uniform bool _debug_refract_glitch = false;
uniform bool _debug_water_depth = false;
uniform bool _debug_water_height = false;
uniform bool _debug_ztest = false;
uniform bool _debug_wave_flatten_dist = false;
uniform bool _debug_wind_power = false;
uniform bool _debug_wind_cycle_test = false;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D dampening_map;
uniform vec2 dampening_uv_offset = vec2(0.5,0.5);
uniform float dampening_uv_scale = 0.04;
uniform float dampening_scale = 1.0;
uniform vec2 dampening_offset = vec2(0.5,1.0);
uniform float dampening_ratio_wavelength = -1.0;
uniform float dampening_ratio_steepness = 20.0;
uniform float dampening_ratio_velocity = 1.0;

uniform vec4 shallow_color : source_color = vec4(0.0,0.5,0.65,0.8);
uniform vec4 deep_color : source_color = vec4(0.09,0.24,0.32,1.0);

uniform bool sss_enabled = false;
uniform float sss_strength = 1.0;
uniform vec4 sss_color : source_color = vec4(0.24,0.88,0.62,0.8);
uniform float sss_trans_depth = 1000.0;
uniform float sss_trans_boost = 1.0;
uniform bool test_back_light = false;
uniform vec3 test_backlight_color : source_color = vec3(0.0);

uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.025;
//uniform float water_height : hint_range(0.0, 1.0) = 0.5;
uniform bool wave_a_on = true;
uniform bool wave_b_on = true;
uniform bool wave_c_on = false;
uniform bool wave_d_on = false;
uniform float wave_scale = 1.0;
uniform float wave_time_scale = 1.0;
uniform float wave_foam_flatten_distance = 1000.0;
uniform float wave_vertex_flatten_distance = 1000.0;
uniform bool wave_system_2 = false;
uniform float wind_blend_value: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float wind_direction_blend1 = 0.0;
uniform float wind_direction_blend2 = 0.0;
uniform float wind_power_blend1 = 1.0;
uniform float wind_power_blend2 = 1.0;
uniform float wind_scale = 1.0;
uniform float time_debt = 0.0;

//depth-fade var
uniform float depth_fade_distance = 1.2;
uniform float refraction_amount: hint_range(0.0, 1.0) = 0.02;

//foam var
uniform sampler2D foam_noise : hint_roughness_gray;
uniform vec4 foam_color_edge : source_color = vec4(1.0,1.0,1.0,1.0);
uniform vec4 foam_color_fresnel : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float foam_edge_distance = 1.0;
uniform float foam_uv_scale = 1.0;
uniform float foam_fresnel_smoothing = 0.0;

uniform vec3 target_position = vec3(0.0);
uniform float horizon_power = 0.5;
uniform float horizon_start = 100.0;
uniform float horizon_end = 1000.0;
uniform bool _debug_shader_enable = false;
uniform bool z_snap_to_zero = false;

varying vec3 world_position;
varying vec3 vertex_position;
varying vec3 vertex_normal;
varying float vertex_dampening;
varying vec2 pointXY_dampening;
varying float target_distance;
varying float water_depth;
varying float water_height;
varying float foam_depth;
varying float foam_ridiculous_vert;
varying float crest_mask;
varying float test_value;
varying float wind_power_current;
varying float wind_direction_current;
varying vec2 wind_vector_current;
//0.502,0.332

//varying smooth vec3 vertex_position;
//varying vec3 vertex_normal;
varying float vertex_height;

vec3 xform(mat4 matrix, vec3 position, const float w){
	return (matrix * vec4(position, w)).xyz;
}

vec4 sample_texture(sampler2D texture_map, vec3 position) {
	vec2 size = vec2(textureSize(texture_map, 0));
	vec2 scale = size / (dampening_uv_scale*2.0);

	mat4 terrainToWorld = mat4(1);
	terrainToWorld[0] *= scale.x*2.0;
	//terrainToWorld[1] *= height_scale;
	terrainToWorld[1] *= 100.0;
	terrainToWorld[2] *= scale.y*2.0;
	terrainToWorld[3].xyz = vec3(-scale.x,0,-scale.y);

	position = xform(inverse(terrainToWorld), position, 1.0);
	vec4 pixel = textureLod(texture_map, position.xz, 0);
	return pixel;
}
vec3 gerstner_wave(vec4 wave, vec3 pos, float dampening, inout float crest_masking, inout vec3 tangent, inout vec3 binormal) {
	float wave_length = wave.w*wave_scale;
	wave_length = max(wave_length + ((dampening * dampening_ratio_wavelength) / wave_time_scale), 0.01);
	float steepness = wave.z;
	if(wave_system_2) {
		float wind_modifier = 1.0+clamp(mix(wind_power_blend1, wind_power_blend2, wind_blend_value), 0.0, 1.2) * 2.0;
		steepness = clamp(steepness - (dampening * dampening_ratio_steepness * wind_modifier), 0.0, 0.9);
		//steepness = clamp(steepness - (dampening * dampening_ratio_steepness), 0.0, 0.9);
	}
	else {
		steepness = clamp(steepness - (dampening * dampening_ratio_steepness), 0.0, 0.9);
	}

	float wave_number = (TAU / wave_length);
	float phase_speed = sqrt(9.8 / wave_number); //-Gravity phase
	vec2 velocity = normalize(wave.xy);
	velocity += (dampening * dampening_ratio_velocity) / wave_time_scale;
	float time_mod = (TAU / (pow(phase_speed,0.0) / 9.8));
	time_mod = (TAU / phase_speed) * 1.0;
	//float f = ((TAU / wave_length) * dot(velocity, pos.xz)) - (sqrt(9.8 / (TAU / wave_length)) * mod(TIME, time_mod));
	float f = wave_number * dot(velocity, pos.xz) - (phase_speed * (1000.0+(fract(TIME+time_debt+0.0) * time_mod) * wave_time_scale));
	//float f = wave_number * dot(velocity, pos.xz) - phase_speed * (mod((TIME+10.0), time_mod)* wave_time_scale);
	//float f = wave_number * dot(velocity, pos.xz) - (phase_speed * ((TIME+0.0) * wave_time_scale));
	/////float f = k * (dot(d, p.xz) - c * _Time.y);
	float amplitude = steepness / wave_number;
	if(sin(f) > 0.0) {
		crest_masking += pow(sin(f),2.0)*steepness;
	}
	tangent += vec3(-velocity.x * velocity.x * (steepness * sin(f)), velocity.x * (steepness * cos(f)), -velocity.x * velocity.y * (steepness * sin(f)));
	binormal += vec3(-velocity.x * velocity.y * (steepness * sin(f)), velocity.y * (steepness * cos(f)), -velocity.y * velocity.y * (steepness * sin(f)));
	//vec3 wave_result = vec3(velocity.x * (amplitude * cos(f)), amplitude * sin(f), velocity.y * (amplitude * cos(f)));
	vec3 wave_result = vec3(velocity.x * (amplitude * cos(mod(f,TAU))), amplitude * sin(mod(f,TAU)), velocity.y * (amplitude * cos(mod(f,TAU))));
	//wave_result += vec3(0.0,pow(wave_result.y,1.0),0.0);
	return wave_result;
}

vec2 align_with_grab_texel(vec2 xy) {

//	if (_CameraDepthTexture_TexelSize.y < 0) {
//		xy.y = 1 - xy.y;
//	}
//	return (floor(xy * _CameraDepthTexture_TexelSize.zw) + 0.5) * abs(_CameraDepthTexture_TexelSize.xy);
	return vec2(0.0);
}

void vertex() {
	world_position = VERTEX.xyz;
	if(z_snap_to_zero) {
		world_position.y = 0.0;
	}
	UV = VERTEX.xz;
	target_distance = distance(VERTEX.xz, NODE_POSITION_WORLD.xz);
	if(target_position != vec3(0.0)) {
		target_distance = distance(VERTEX.xz, target_position.xz);
	}
	target_distance = max(target_distance, 0.0001);

	vec3 tangent = vec3(1.0,0.0,0.0);
	vec3 binormal = vec3(0.0,0.0,1.0);
	vec3 new_position = world_position;

	ivec2 dampening_map_size = textureSize(dampening_map, 0);
	vec2 dampening_incr = 1.0/vec2(dampening_map_size);
	vertex_position = VERTEX;

	pointXY_dampening = world_position.xz * dampening_incr * dampening_uv_scale; //- Multiplied the new vertex/pixel position by the heightmap increment (pixel ratio), multiplied by uniform UV scale
	pointXY_dampening.y *= -1.0;

	//float dampening_value = textureLod(dampening_map, pointXY_dampening + dampening_uv_offset, 0.0).r*dampening_scale;
	float dampening_value = sample_texture(dampening_map, vertex_position).x*dampening_scale;
	float dampening_smooth = smoothstep(0.5-dampening_offset.x, 0.5+dampening_offset.y, dampening_value);

	float max_amp = 0.0;
	float crest_masking = 0.0;
	vec3 blend_position1 = new_position;
	vec3 tangent_blend1 = vec3(1.0,0.0,0.0);
	vec3 binormal_blend1 = vec3(0.0,0.0,1.0);
	float crest_masking_blend1 = 0.0;
	float max_amp_blend1 = 0.0;

	vec3 blend_position2 = new_position;
	vec3 tangent_blend2 = vec3(1.0,0.0,0.0);
	vec3 binormal_blend2 = vec3(0.0,0.0,1.0);
	float crest_masking_blend2 = 0.0;
	float max_amp_blend2 = 0.0;

	if(wind_blend_value <= 0.99) {
		//- BLEND 1 VALUES
		//float wind_power_blend1_clamp = clamp(wind_power_blend1,0.0,1.0);
		float wind_power_blend1_clamp = clamp(wind_power_blend1,0.0,1.0) * (1.0-pow(wind_blend_value, 2.0));
		float wind_deviation_blend1 = (PI/4.0)*max(1.2-wind_power_blend1,0.0)+(sin(TIME*0.01)*0.01);

		//-BLEND1_WAVE1
		vec2 wind_vec = vec2(cos(wind_direction_blend1), sin(wind_direction_blend1));
		vec4 wave = vec4(wind_vec, wind_power_blend1_clamp * 0.5, wind_power_blend1*wind_scale);
		blend_position1 += gerstner_wave(wave, blend_position1, dampening_smooth, crest_masking_blend1, tangent_blend1, binormal_blend1);
		max_amp_blend1 += (wave.z*wave.w);

		//-BLEND1_WAVE2
		wind_vec = vec2(cos(wind_direction_blend1+wind_deviation_blend1), sin(wind_direction_blend1+wind_deviation_blend1));
		wave = vec4(wind_vec, wind_power_blend1_clamp * 0.2, wind_power_blend1*wind_scale*2.0);
		blend_position1 += gerstner_wave(wave, blend_position1, dampening_smooth, crest_masking_blend1, tangent_blend1, binormal_blend1);
		max_amp_blend1 += (wave.z*wave.w);

		//-BLEND1_WAVE3
		wind_vec = vec2(cos(wind_direction_blend1-wind_deviation_blend1), sin(wind_direction_blend1-wind_deviation_blend1));
		wave = vec4(wind_vec, wind_power_blend1_clamp * 0.15, wind_power_blend1*wind_scale*4.0);
		blend_position1 += gerstner_wave(wave, blend_position1, dampening_smooth, crest_masking_blend1, tangent_blend1, binormal_blend1);
		max_amp_blend1 += (wave.z*wave.w);
	}
	if(wind_blend_value >= 0.01) {
		//- BLEND 2 VALUES
		//float wind_power_blend2_clamp = clamp(wind_power_blend2,0.0,1.0);
		float wind_power_blend2_clamp = clamp(wind_power_blend2,0.0,1.0) * (1.0-pow(1.0-wind_blend_value, 2.0));
		float wind_deviation_blend2 = (PI/4.0)*max(1.2-wind_power_blend2,0.0)+(sin(TIME*0.01)*0.01);

		//-BLEND2_WAVE1
		vec2 wind_vec = vec2(cos(wind_direction_blend2), sin(wind_direction_blend2));
		vec4 wave = vec4(wind_vec, wind_power_blend2_clamp*0.6, wind_power_blend2*wind_scale);
		blend_position2 += gerstner_wave(wave, blend_position2, dampening_smooth, crest_masking_blend2, tangent_blend2, binormal_blend2);
		max_amp_blend2 += (wave.z*wave.w);

		//-BLEND2_WAVE2
		wind_vec = vec2(cos(wind_direction_blend2+wind_deviation_blend2), sin(wind_direction_blend2+wind_deviation_blend2));
		wave = vec4(wind_vec, wind_power_blend2_clamp * 0.2, wind_power_blend2*wind_scale*2.0);
		blend_position2 += gerstner_wave(wave, blend_position2, dampening_smooth, crest_masking_blend2, tangent_blend2, binormal_blend2);
		max_amp_blend2 += (wave.z*wave.w);

		//-BLEND2_WAVE3
		wind_vec = vec2(cos(wind_direction_blend2-wind_deviation_blend2), sin(wind_direction_blend2-wind_deviation_blend2));
		wave = vec4(wind_vec, wind_power_blend2_clamp * 0.15, wind_power_blend2*wind_scale*4.0);
		blend_position2 += gerstner_wave(wave, blend_position2, dampening_smooth, crest_masking_blend2, tangent_blend2, binormal_blend2);
		max_amp_blend2 += (wave.z*wave.w);
	}

	wind_power_current = mix(wind_power_blend1, wind_power_blend2, wind_blend_value);
	wind_direction_current = mix(wind_direction_blend1, wind_direction_blend2, wind_blend_value);
	wind_vector_current = vec2(cos(wind_direction_current), sin(wind_direction_current));

	//- COMBINE BLEND1 AND BLEND2 RESULTS
	new_position = mix(blend_position1, blend_position2, wind_blend_value);
	binormal = mix(binormal_blend1, binormal_blend2, wind_blend_value);
	tangent = mix(tangent_blend1, tangent_blend2, wind_blend_value);
	max_amp = mix(max_amp_blend1, max_amp_blend2, wind_blend_value);
	crest_masking = mix(crest_masking_blend1, crest_masking_blend2, wind_blend_value);
	//crest_masking *= clamp(wind_power_current, 0.6, 1.5);
	float terrain_height = 1050.0;//290.0-0.0;
	float terrain_offset = 188.0;//45.0;
	float terrain_water_height = terrain_offset / terrain_height;
	float wave_power_current = (wind_power_current*wind_scale)*0.25;
	foam_depth = smoothstep(terrain_water_height - (foam_edge_distance * wave_power_current * (1.0/terrain_height)), terrain_water_height, dampening_value*1.0);
	foam_depth = smoothstep(terrain_water_height - (foam_edge_distance * (1.0/terrain_height)), terrain_water_height, dampening_value);
	//foam_depth = smoothstep(terrain_water_height - ((foam_edge_distance+0.5) * (wave_power_current+0.3) * (1.0/terrain_height)), terrain_water_height, dampening_value*1.0);
	//foam_depth = (cos((clamp(terrain_water_height - dampening_value, 0.0, 1.0)*(PI/terrain_water_height)) + TIME*1.0));
	//foam_ridiculous_vert = smoothstep(terrain_water_height - (5.0/terrain_height), terrain_water_height, dampening_value) * ((sin((PI*4.0) * smoothstep(terrain_water_height - (5.0/terrain_height), terrain_water_height, dampening_value) - (2.0*TIME)) + 1.0) * 0.5);
	float foam_edge_count = 5.0;
	float foam_edge_speed = (wind_power_current+0.1)*wind_scale;

	foam_ridiculous_vert = smoothstep(terrain_water_height - (foam_edge_distance/terrain_height), terrain_water_height, dampening_value) * ((sin((PI*foam_edge_count) * smoothstep(terrain_water_height - (foam_edge_distance/terrain_height), terrain_water_height, dampening_value) - (TIME * foam_edge_speed)) + 1.0) * 0.5);

	//water_depth = smoothstep(terrain_water_height - (1.0/terrain_height), terrain_water_height, dampening_value*1.0);
	water_depth = smoothstep(0.0, terrain_water_height, dampening_value);
	water_height = smoothstep(-2.0, max_amp, (new_position.y - world_position.y)*0.5);
	//water_height = (new_position.y - world_position.y);
	crest_mask = crest_masking;
	vertex_position = new_position;
	if(wave_vertex_flatten_distance > 0.0) {
		vertex_position.y *= max(1.0-(target_distance/wave_vertex_flatten_distance), 0.0);
	}
	vertex_normal = normalize(cross(binormal, tangent));
	vertex_normal = normalize(vertex_normal + vec3(0.0, 10.0, 0.0));
	vertex_dampening = dampening_smooth;
	VERTEX.xyz = vertex_position;
	TANGENT = tangent;
	BINORMAL = binormal;
	NORMAL = vertex_normal;

	//---------------------------------------------------------------------------------
	//- HORIZON DEFORM
	float power = horizon_power;
	float negate = 1.0;
	//VERTEX.y -= smoothstep(horizon_start, horizon_end, dist)*pow(1.0+(horizon_power*0.01),dist);
	//- Apparently 0^0 fails to return a value, so don't use that...
	if(power < 0.0) {
		power *= -1.0;
		negate *= -1.0;
	}
	VERTEX.y -= negate * smoothstep(horizon_start, max(horizon_end, horizon_start), target_distance)*pow(target_distance, horizon_power);

}

void fragment() {

	float depth_tex = textureLod(DEPTH_TEXTURE,SCREEN_UV,0.0).r;
	//vec2 depth_tex_size = textureSize(DEPTH_TEXTURE, 0.0);
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex,1.0);
	world_pos.xyz/=world_pos.w;
	float surface_depth = clamp(1.0-smoothstep(world_pos.z+foam_edge_distance, world_pos.z, VERTEX.z), 0.0, 1.0);

	// FOAM EDGE CALCULATIONS
	vec2 test = normalize(wind_vector_current)*0.1;
	vec2 foam_speed = normalize(wind_vector_current)*0.1;

	//vec3 foam_texture = texture(foam_noise, UV - (TIME * test)).rgb;
	//vec3 foam_texture1 = texture(foam_noise, ((vertex_position.xz/foam_uv_scale) / wind_power_current) - (TIME * test)).rgb;
	vec3 foam_texture1 = texture(foam_noise, ((vertex_position.xz/foam_uv_scale)) - (TIME * foam_speed)).rgb;
	vec3 foam_texture2 = texture(foam_noise, (vertex_position.xz/(foam_uv_scale*3.0) - (TIME * test))).rgb;
	vec3 foam_texture3 = texture(foam_noise, (vertex_position.xz/(foam_uv_scale*(wave_foam_flatten_distance*1.0)) - (TIME * test * 0.1))).rgb;
	// DEPTH COLOR FADE CALCULATIONS
	//ALBEDO = vec3(clamp(world_pos.z+6.0,0.0,1.0)); // Z DEPTH UNDER WATER
	//ALBEDO = vec3(clamp(VERTEX.z+6.0,0.0,1.0)); // Z DEPTH ON TOP OF WATER
	//float depth_fade = depth_fade_distance-(VERTEX.z - world_pos.z)*0.02;
	float depth_fade = smoothstep(-depth_fade_distance, depth_fade_distance, 1.0-((VERTEX.z - depth_fade_distance) - world_pos.z));
	//float depth_fade = clamp(1.0-((VERTEX.z - depth_fade_distance) - world_pos.z), 0.0, 1.0);

	//ALBEDO = vec3(depth_fade);
	// REFRACTION CALCULATIONS
	vec2 refrac_distort = NORMAL.xz * refraction_amount;
	//vec2 refrac_distort = NORMAL.xz * refraction_amount * ((VERTEX.z - world_pos.z)*0.5);
	//vec2 refrac_uv = SCREEN_UV + (refrac_distort * (VERTEX.z - world_pos.z)*0.5));
	vec2 refrac_uv = SCREEN_UV + refrac_distort;
	vec4 refraction_pass1 = texture(SCREEN_TEXTURE, refrac_uv);
	float depth_refrac = texture(DEPTH_TEXTURE, refrac_uv).r;
	vec4 world_pos_refrac = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_refrac,1.0);
	world_pos_refrac.xyz/=world_pos_refrac.w;

	//- Some failed attempts at fixing refraction artifacts etc...
	refrac_uv = SCREEN_UV + (refrac_distort * clamp((VERTEX.z - world_pos_refrac.z),0.0,1.0));
	vec4 refraction = mix(texture(SCREEN_TEXTURE, refrac_uv),refraction_pass1,0.0);
	depth_refrac = texture(DEPTH_TEXTURE, refrac_uv).r;
	vec4 world_pos_refrac2 = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_refrac,1.0);
	world_pos_refrac2.xyz/=world_pos_refrac2.w;

	float depth_fade_refrac = depth_fade_distance-(VERTEX.z - world_pos_refrac2.z)*0.5;
	depth_fade_refrac = mix(depth_fade_refrac,depth_fade,1.0);

	//vec3 refraction_mix1 = mix(refraction.rgb + (shallow_color.rgb*shallow_color.a), shallow_color.rgb, (vert_vis*10.0+depth_fade)*0.5);
	//vec3 refraction_mix1 = mix(refraction.rgb + (shallow_color.rgb*shallow_color.a), shallow_color.rgb*shallow_color.a, water_depth);
	vec3 refraction_mix1 = mix(refraction.rgb + (shallow_color.rgb*shallow_color.a), shallow_color.rgb, depth_fade);
	vec3 refraction_mix2 = deep_color.rgb;
	//vec3 refraction_mix2 = mix(deep_color.rgb, refraction.rgb, (1.0-deep_color.a));
	//vec3 refraction_mix2 = mix(deep_color.rgb, refraction.rgb, 0.0);

	// MIXING DEPTH COLOR FADE AND FOAM CALCULATIONS
	//vec3 col = mix(refraction_mix2, refraction_mix1, clamp(depth_fade,0.0,1.0));
	vec3 color_final = mix(refraction_mix2, refraction_mix1, clamp(depth_fade_refrac,0.0,1.0));
	//float foam_fresnel = pow(1.0-dot(normalize(NORMAL), normalize(VIEW)),3.0);
	float foam_fresnel = pow(2.0-dot(normalize(NORMAL), normalize(VIEW)),3.0);
	//-FIX FOR SEAM MESH AND HARD 90 DEGREE ANGLES
//	if(dot(normalize(NORMAL), vec3(0.0,0.0,1.0)) < -0.5 || dot(normalize(NORMAL), vec3(1.0,0.0,0.0)) < -0.5) {
//		foam_fresnel = 0.0;
//	}
	foam_fresnel *= crest_mask;
	float foam_mask_dist1 = 1.0;
	float foam_mask_dist2 = 1.0;
	if(wave_foam_flatten_distance > 0.0) {
		foam_mask_dist1 = clamp(1.0-(target_distance/wave_foam_flatten_distance) + (target_position.y * 0.01), 0.0, 1.0);
		foam_mask_dist2 = clamp(1.0-(target_distance/(wave_foam_flatten_distance*3.0)) + (target_position.y * 0.01), 0.0, 1.0);
	}
	foam_texture3 = smoothstep(0.35, 0.65, foam_texture3) * foam_mask_dist2;

	float terrain_height = 290.0-0.0;
	float terrain_offset = 45.0;
	float terrain_water_height = terrain_offset / terrain_height; //- 0-1
	float wave_power_current = (wind_power_current*wind_scale)*0.25;

	float foam_edge_count = 6.0;
	float foam_edge_speed = (wind_power_current+0.5)*wind_scale;
	float dampening_value = textureLod(dampening_map, pointXY_dampening + dampening_uv_offset, 0.0).r*dampening_scale;
	float foam_depth2 = smoothstep(terrain_water_height - (foam_edge_distance * (1.0/terrain_height)), terrain_water_height, dampening_value*1.0);
	//float foam_ridiculous = smoothstep(terrain_water_height - (foam_edge_distance/terrain_height), terrain_water_height, dampening_value) * ((sin((PI*4.0) * smoothstep(terrain_water_height - (foam_edge_distance/terrain_height), terrain_water_height, dampening_value) - (10.0*TIME)) + 1.0) * 0.5);
	float foam_ridiculous = smoothstep(terrain_water_height - (foam_edge_distance/terrain_height), terrain_water_height, dampening_value) * ((sin((PI*foam_edge_count) * smoothstep(terrain_water_height - (foam_edge_distance/terrain_height), terrain_water_height, dampening_value) - TIME*foam_edge_speed) + 1.0) * 0.5);
	//ALBEDO = vec3(foam_ridiculous);
//	if(dampening_value > terrain_water_height - (5.0/terrain_height)) {
//		ALBEDO = vec3(((sin((PI*200.0) * smoothstep(0.0, terrain_water_height, dampening_value) - TIME) + 1.0) * 0.5));
//	}
//	else {
//		ALBEDO = vec3(0.0);
//	}
	//vec3 foam_layer1 = mix(foam_color_edge.rgb, vec3(0.0), step(0.25, 0.5-clamp(foam_depth+(foam_texture1.x * 0.25), 0.0, 1.0))) * foam_mask_dist2;
	vec3 foam_layer1 = mix(foam_color_edge.rgb, vec3(0.0), step(0.25, 1.0-clamp(foam_ridiculous+(foam_texture1.x * 0.7), 0.0, 1.0))) * foam_mask_dist2;
	vec3 foam_layer3 = mix(foam_color_edge.rgb, vec3(0.0), step(0.25, 0.5-clamp(foam_depth2+(foam_texture1.x * 0.25), 0.0, 1.0))) * foam_mask_dist2;
	//foam_layer1 = foam_layer3 * foam_layer1;
	//foam_layer1 = foam_layer3 - foam_layer1;
	foam_layer1 = mix(foam_layer1, foam_layer3, 1.0);
	//vec3 foam_layer1 = vec3(step(0.1, foam_depth * foam_texture1.x)) * foam_mask_dist2;
	//vec3 foam_layer2 = mix(foam_color_fresnel.rgb, vec3(0.0), step(0.25, clamp((1.0-foam_fresnel)+(foam_texture3.x * 0.8), 0.0, 1.0)));
	//vec3 foam_layer2 = mix(foam_color_fresnel.rgb, vec3(0.0), step(0.25, clamp((1.0-foam_fresnel * foam_texture1.x * (foam_texture3.x + (foam_mask_dist1))), 0.0, 1.0)));
	vec3 foam_layer2 = mix(foam_color_fresnel.rgb, vec3(0.0), step(0.25, clamp((0.9-foam_fresnel * (foam_texture3.x + foam_mask_dist1))+(foam_texture1.x*0.8), 0.0, 1.0)));
	//vec3 foam_layer2 = mix(foam_color_fresnel.rgb, vec3(0.0), step(0.25, clamp((0.9-foam_fresnel)+(foam_texture1*0.8), 0.0, 1.0)));
	//vec3 crest_result = vec3(clamp(foam_layer2 * (foam_mask_dist1 - foam_texture2.x), 0.0, 1.0));
	vec3 crest_result = vec3(clamp(foam_layer2, 0.0, 1.0));
	//ALBEDO = foam_layer2;

	vec3 foam_layers = (foam_layer1 * foam_color_edge.a)  + (foam_layer2 * crest_result);//* water_height;//max(1.0-(target_distance/1500.0), 0.0);

	color_final = color_final.rgb + foam_layers;
	//ALBEDO = vec3(mix(foam_texture3.x, foam_mask_dist1*2.0, 0.1));
	ALBEDO = color_final;
	if(_debug_dampen) {
		//ALBEDO = vec3(smoothstep(0.5-dampening_offset.x,0.5+dampening_offset.y,texture(dampening_map,(world_position.xz*dampening_uv_scale)+dampening_uv_offset).r*dampening_scale));
		ALBEDO = vec3(vertex_dampening);
	}
	if(_debug_depth_tex) {
		ALBEDO = vec3(clamp(depth_fade_distance-(VERTEX.z - world_pos.z)*0.5,0.0,1.0));
		//ALBEDO = vec3(depth_fade);
	}
	if(_debug_fresnel) {
		ALBEDO = vec3(crest_mask);
	}
	if(_debug_normal_frag) {
		ALBEDO = NORMAL;
	}
	if(_debug_normal_vert) {
		ALBEDO = vertex_normal;
	}
	if(_debug_refract) {
		ALBEDO = refraction.rgb;
		//ALBEDO = vec3(refraction.r + refraction.g + refraction.b);
		//ALBEDO = mix(refraction.rgb*shallow_color.rgb, refraction.rgb, (smoothstep(0.005, 0.1, texture(dampening_map,(world_position.xz*dampening_uv_scale)+dampening_uv_offset).r*dampening_scale)));
	}
	if(_debug_refract_glitch) {
		ALBEDO = vec3(clamp((VERTEX.z - world_pos_refrac.z),0.0,1.0));
	}
	if(_debug_water_depth) {
		ALBEDO = vec3(water_depth);
	}
	if(_debug_water_height) {
		ALBEDO = vec3(water_height);
	}
	if(_debug_wave_flatten_dist) {
		//ALBEDO = vec3(max(1.0-(target_distance/wave_vertex_flatten_distance), 0.0), 0.0, max(1.0-(target_distance/wave_foam_flatten_distance), 0.0));
		//ALBEDO = vec3(max(1.0-(target_distance/wave_foam_flatten_distance) * foam_texture3.x, 0.0));
		ALBEDO = vec3(crest_result);
	}
	if(_debug_wind_power) {
		ALBEDO = vec3(wind_power_current);
	}
	if(_debug_ztest) {
		ALBEDO = vec3(test_value);
	}
	if(_debug_shader_enable) {
		ALBEDO *= COLOR.rgb;
	}

	vec3 point = xform(VIEW_MATRIX, vertex_position, 1.0);
	vec3 normals_flat = normalize(cross(dFdy(point), dFdx(point)));
	if(SCREEN_UV.x < _debug_flat_shade){
		NORMAL = normals_flat;
	}

	METALLIC = metallic;
	ROUGHNESS = roughness;
	RIM = 1.0;
	RIM_TINT = 0.5;
	if(test_back_light) {
		BACKLIGHT = test_backlight_color;
	}
	//EMISSION = vec3(0.2);
//	if(sss_enabled) {
//		SSS_STRENGTH = sss_strength;
//		SSS_TRANSMITTANCE_COLOR = sss_color;
//		SSS_TRANSMITTANCE_DEPTH = sss_trans_depth;
//		SSS_TRANSMITTANCE_BOOST = sss_trans_boost;
//	}
	if(!FRONT_FACING) {
		NORMAL *= -1.0;
	}
}

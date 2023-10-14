shader_type spatial;
render_mode world_vertex_coords, diffuse_toon, specular_toon, cull_disabled, depth_draw_always;//, cull_disabled;//, blend_add;
//render_mode world_vertex_coords, cull_disabled, depth_draw_always;//, cull_disabled;//, blend_add;

uniform bool _debug_dampen = false;
uniform bool _debug_depth_tex = false;
uniform bool _debug_fresnel = false;
uniform bool _debug_normal_frag = false;
uniform bool _debug_normal_vert = false;
uniform bool _debug_refract = false;
uniform bool _debug_refract_glitch = false;
uniform bool _debug_water_depth = false;
uniform bool _debug_water_height = false;
uniform bool _debug_ztest = false;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D dampening_map: repeat_disable, filter_linear_mipmap;
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
uniform vec4 wave_a = vec4(1.0, 0.0, 0.5, 1.5);
uniform bool wave_a_on = true;
uniform vec4 wave_b = vec4(0.5, 0.2, 0.2, 3.0);
uniform bool wave_b_on = true;
uniform vec4 wave_c = vec4(0.5, -0.2,0.15, 6.0);
uniform bool wave_c_on = false;
uniform vec4 wave_d = vec4(0.82,0.84,0.07,1.44);
uniform bool wave_d_on = false;

//depth-fade var
uniform float depth_fade_distance = 1.2;
uniform float refraction_amount: hint_range(0.0, 1.0) = 0.02;

//foam var
uniform sampler2D foam_noise : hint_roughness_gray;
uniform vec4 foam_color_edge : source_color = vec4(1.0,1.0,1.0,1.0);
uniform vec4 foam_color_fresnel : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float foam_scale = 0.25;
uniform float foam_fresnel_smoothing = 0.0;

uniform float wave_time_scale = 1.0;

varying vec3 world_position;
varying vec3 vertex_position;
varying vec3 vertex_normal;
varying float vertex_dampening;
varying float water_depth;
varying float water_height;
varying float crest_mask;
varying float test_value;

//0.502,0.332

vec3 gerstner_wave(vec4 wave, vec3 pos, float dampening, inout float steep_sum, inout float crest_masking, inout vec3 tangent, inout vec3 binormal, inout float tested_value) {
	float wave_length = wave.w;
	wave_length = clamp(wave_length + ((dampening * dampening_ratio_wavelength) / wave_time_scale), 0.01, 1000.0);
	float steepness = wave.z;
	steepness = clamp(steepness - (dampening * dampening_ratio_steepness), 0.0, 0.9);

	float wave_number = (TAU / wave_length);
	float phase_speed = sqrt(9.8 / wave_number); //-Gravity phase
	vec2 velocity = normalize(wave.xy);
	velocity += (dampening * dampening_ratio_velocity) / wave_time_scale;
	float time_mod = (TAU / (pow(phase_speed,0.0) / 9.8));
	time_mod = (TAU / phase_speed) * 1.0;
	//float f = ((TAU / wave_length) * dot(velocity, pos.xz)) - (sqrt(9.8 / (TAU / wave_length)) * mod(TIME, time_mod));
	float f = wave_number * dot(velocity, pos.xz) - (phase_speed * (1000.0+(fract(TIME+0.0) * time_mod) * wave_time_scale));
	//float f = wave_number * dot(velocity, pos.xz) - phase_speed * (mod((TIME+10.0), time_mod)* wave_time_scale);
	//float f = wave_number * dot(velocity, pos.xz) - (phase_speed * ((TIME+0.0) * wave_time_scale));
	/////float f = k * (dot(d, p.xz) - c * _Time.y);
	float amplitude = steepness / wave_number;
	tested_value = (dot(velocity, pos.xz))*0.1;
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

vec2 estimate_wave_velocity() {
	//vec2 test = ((wave_a.xy*wave_a.w) + (wave_b.xy*wave_b.w) + (wave_c.xy*wave_c.w)) / (wave_a.w + wave_b.w + wave_c.w);
	vec2 test = (normalize(wave_a.xy) + normalize(wave_b.xy) + normalize(wave_c.xy)) / 12.0;
	//test = vec2(test.x,test.y);
	return test;
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
	vec3 tangent = vec3(1.0,0.0,0.0);
	vec3 binormal = vec3(0.0,0.0,1.0);
	vec3 new_position = world_position;

	float dampening_value = texture(dampening_map,(world_position.xz*dampening_uv_scale)+dampening_uv_offset).r*dampening_scale;
	float dampening_smooth = smoothstep(0.5-dampening_offset.x,0.5+dampening_offset.y,dampening_value);

	//vec2 dampening_uv_offset_animated = vec2(cos(TIME),sin(TIME))*0.02;
	//vec2 dampening_offset_animated = vec2(cos(TIME),sin(TIME))*0.1;
	//float dampening_value = texture(dampening_map,(world_position.xz*dampening_uv_scale)+dampening_uv_offset).r*dampening_scale;
	//float dampening_smooth = smoothstep(0.5-dampening_offset.x,0.5+dampening_offset.y+dampening_offset_animated.x,dampening_value);

	float steep_sum = 0.0;
	float crest_masking = 0.0;
	float tested_value = 0.0;
	float max_amp = 0.0;
	if(wave_a_on) {
		new_position += gerstner_wave(wave_a, new_position, dampening_smooth, steep_sum, crest_masking, tangent, binormal, tested_value);
		max_amp += (wave_a.z*wave_a.w)/TAU;
	}
	if(wave_b_on) {
		new_position += gerstner_wave(wave_b, new_position, dampening_smooth, steep_sum, crest_masking, tangent, binormal, tested_value);
		max_amp += (wave_b.z*wave_b.w)/TAU;
	}
	if(wave_c_on) {
		new_position += gerstner_wave(wave_c, new_position, dampening_smooth, steep_sum, crest_masking, tangent, binormal, tested_value);
		max_amp += (wave_c.z*wave_c.w)/TAU;
	}
	if(wave_d_on) {
		new_position += gerstner_wave(wave_d, new_position, dampening_smooth, steep_sum, crest_masking, tangent, binormal, tested_value);
		max_amp += (wave_d.z*wave_d.w)/TAU;
	}
	//water_depth = 1.0-clamp(dampening_value*10.0,0.0,1.0);
	water_depth = 1.0-clamp(dampening_value*12.0,0.0,1.0);
	water_height = (new_position.y - world_position.y)+(max_amp);
	test_value = tested_value;
	crest_mask = crest_masking;
	vertex_position = new_position;
	vertex_normal = normalize(cross(binormal, tangent));
	vertex_dampening = dampening_smooth;
	VERTEX.xyz = vertex_position;
	TANGENT = tangent;
	BINORMAL = binormal;
	NORMAL = vertex_normal;
}

void fragment() {
	// FOAM EDGE CALCULATIONS
	float foam_speed = 0.1;
	float foam_proximity = 1.0;
	//vec3 foam_texture = texture(foam_noise, UV - (TIME * foam_speed)).rgb;
	vec2 test = estimate_wave_velocity();
	vec3 foam_texture = texture(foam_noise, UV - (TIME * test)).rgb;

	float depth_tex = textureLod(DEPTH_TEXTURE,SCREEN_UV,0.0).r;
	//vec2 depth_tex_size = textureSize(DEPTH_TEXTURE, 0.0);
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex,1.0);
	world_pos.xyz/=world_pos.w;
	float surface_depth = clamp(1.0-smoothstep(world_pos.z+foam_proximity,world_pos.z,VERTEX.z),0.0,1.0);

	float density = 0.5;
	float gradient = 1.0;
	vec4 vert_to_cam = VIEW_MATRIX * world_pos;
	float vert_dist = length(vert_to_cam.xyz);
	float vert_vis = clamp(exp(-pow(vert_dist*density, gradient)), 0.0, 1.0);

	// DEPTH COLOR FADE CALCULATIONS
	//ALBEDO = vec3(clamp(world_pos.z+6.0,0.0,1.0)); // Z DEPTH UNDER WATER
	//ALBEDO = vec3(clamp(VERTEX.z+6.0,0.0,1.0)); // Z DEPTH ON TOP OF WATER
	//float depth_fade = depth_fade_distance-(VERTEX.z - world_pos.z)*0.5;
	float depth_fade = depth_fade_distance-smoothstep(0.0, depth_fade_distance, (VERTEX.z - world_pos.z)*0.5);

	//vec3 col = vec3((vert_vis*10.0+depth_fade)*0.5); //-surface_depth for foam, depth_fade for bottom and water thickness,
	//col = vec3(depth_fade);
	//col = vec3(vert_vis*10.0);


	//vec3 col = mix(vec3(clamp(world_pos.z+10.0,0.0,1.0)), vec3(vert_vis), 0.8);

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

	//mix(vec3(clamp(world_pos.z+10.0,0.0,1.0)), vec3(vert_vis), 0.8);
	//vert_vis*10.0+depth_fade)*0.5
	//vec3 refraction_mix1 = mix(refraction.rgb + (shallow_color.rgb*shallow_color.a), shallow_color.rgb, (vert_vis*10.0+depth_fade)*0.5);
	vec3 refraction_mix1 = mix(refraction.rgb + (shallow_color.rgb*shallow_color.a), shallow_color.rgb, water_depth);
	vec3 refraction_mix2 = deep_color.rgb;
	//vec3 refraction_mix2 = mix(deep_color.rgb, refraction.rgb, (1.0-deep_color.a));
	//vec3 refraction_mix2 = mix(deep_color.rgb, refraction.rgb, 0.0);

	// MIXING DEPTH COLOR FADE AND FOAM CALCULATIONS
	//vec3 col = mix(refraction_mix2, refraction_mix1, clamp(depth_fade,0.0,1.0));
	vec3 col = mix(refraction_mix2, refraction_mix1, clamp(depth_fade_refrac,0.0,1.0));
	//col = vec3(clamp(VERTEX.z+6.0,0.0,1.0));
	//vec3 col = mix(refraction_mix1, refraction_mix2, water_depth);
	//vec3 col = refraction_mix1;
	//float foam_fresnel = pow(1.0-dot(normalize(NORMAL), normalize(VIEW)),3.0);
	float foam_fresnel = pow(2.0-dot(normalize(NORMAL), normalize(VIEW)), 3.0);
	foam_fresnel *= crest_mask;

	vec3 foam_layer1 = mix(foam_color_edge.rgb, vec3(0.0), step(foam_scale, clamp(surface_depth+(foam_texture.x * 0.25), 0.0, 1.0)));
//	ALBEDO = foam_layer1;
	vec3 foam_layer2 = mix(foam_color_fresnel.rgb, vec3(0.0), step(foam_scale, clamp((0.9-foam_fresnel)+(foam_texture*0.8), 0.0, 1.0)));
	vec3 foam_layers = (foam_layer1 * foam_color_edge.a) + (foam_layer2 * foam_color_fresnel.a * clamp(pow(crest_mask, foam_fresnel_smoothing),0.0,1.0));
	//vec3 foam_layers = (foam_layer1 * foam_color_edge.a) + (foam_layer2 * foam_color_fresnel.a);
	col = col.rgb + foam_layers;

	ALBEDO = col;
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
	if(_debug_ztest) {
		ALBEDO = vec3(test_value);
	}
	METALLIC = metallic;
	ROUGHNESS = roughness;
	RIM = 1.0;
	RIM_TINT = 0.5;
	if(test_back_light) {
		BACKLIGHT = test_backlight_color;
	}

	if(sss_enabled) {
		SSS_STRENGTH = sss_strength;
		SSS_TRANSMITTANCE_COLOR = sss_color;
		SSS_TRANSMITTANCE_DEPTH = sss_trans_depth;
		SSS_TRANSMITTANCE_BOOST = sss_trans_boost;
	}
	if(!FRONT_FACING) {
		NORMAL *= -1.0;
	}
}

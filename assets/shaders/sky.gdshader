shader_type sky;
render_mode use_quarter_res_pass;

group_uniforms sky;
	uniform vec3 day_top_colour : source_color = vec3(0.1, 0.6, 1.0);
	uniform vec3 day_bottom_colour : source_color = vec3(0.4, 0.8, 1.0);

group_uniforms horizon;
	uniform vec3 horizon_colour : source_color = vec3( 0.0, 0.7, 0.8 );
	uniform float horizon_blur : hint_range( 0.0, 1.0, 0.01 ) = 0.05;

group_uniforms sun;
	uniform vec3 sun_colour : source_color = vec3( 10.0, 8.0, 1.0 );
	uniform float sun_size : hint_range( 0.01, 1.0 ) = 0.2;
	uniform float sun_blur : hint_range( 0.01, 20.0 ) = 10.0;


void sky() {
	float _eyedir_y = abs(sin(EYEDIR.y * PI * 0.5));

	// sky
	vec3 _sky_colour = mix(day_bottom_colour, day_top_colour, _eyedir_y);
	_sky_colour = mix(_sky_colour, vec3(0.0), clamp((0.7 - 0.3) * 0.0, 0.0, 1.0));
	COLOR = _sky_colour;

	// horizon
	float _horizon_amount = 0.0;
	if(EYEDIR.y < 0.0)
	{
		_horizon_amount = clamp(abs(EYEDIR.y) / horizon_blur, 0.0, 1.0);
		vec3 _horizon_colour = mix(horizon_colour, _sky_colour, 0.0);
		_horizon_colour = mix(_horizon_colour, vec3(0.0), (1.0 - 0.3) * 0.0 * 0.7);
		COLOR = mix(COLOR, _horizon_colour, _horizon_amount);
	}

	// sun
	float _sun_distance = 0.0;
	_sun_distance = distance(EYEDIR, LIGHT0_DIRECTION);
	// bigger sun near the horizon
	float _sun_size = sun_size + cos(LIGHT0_DIRECTION.y * PI) * sun_size * 0.25;
	// finding sun disc and edge blur
	float _sun_amount = clamp((1.0 - _sun_distance / _sun_size) / sun_blur, 0.0, 1.0);
	vec3 _sun_colour = sun_colour;
	_sun_amount = clamp(_sun_amount * ( 1.0 ), 0.0, 1.0);
	_sun_amount *= 1.0 - _horizon_amount;
	// leveling the "glow" in color
	if( _sun_colour.r > 1.0 || _sun_colour.g > 1.0 || _sun_colour.b > 1.0 )
		_sun_colour *= _sun_amount;
	COLOR = mix( COLOR, _sun_colour, _sun_amount );
}
#define GEN_FALLOFF uniform bool
#define NOISE uniform sampler2D
#define AMPLITUDE uniform float

#define FALLOFF_START uniform float
#define FALLOFF_END uniform float


vec3 srgb_to_linear(vec3 c) {
	return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}

float falloff(float x, float y) {
#define position vec2(
		(x - 0.5) * 2.0,
		(y - 0.5) * 2.0
	)

#define T max(abs(position.x), abs(position.y))
#if (T <= FALLOFF_START)
		return 1.0;
#elif (T > FALLOFF_END)
		return 0.0;
#else
		return smoothstep(1.0, 0.0, inverse_lerp(FALLOFF_START, FALLOFF_END, T));
#endif
}

void calculate_height_map() {
#define value srgb_to_linear(textureLod(NOISE, UV, 0).rgb).r
#if GEN_FALLOFF
	VERTEX.y = value * AMPLITUDE * falloff(UV.x, UV.y) * 2.5;
#else
	VERTEX.y = value * AMPLITUDE;
#endif
}
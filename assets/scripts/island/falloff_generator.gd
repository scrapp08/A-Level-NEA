class_name FalloffGenerator

static func generate_falloff_map(size : Vector2i, falloff_start : float, falloff_end : float) -> Array:
	var height_map = []
	height_map.resize(size.x)

	for x in size.x:
		height_map[x] = []
		height_map[x].resize(size.y)
		for y in size.y:

			var position := Vector2(
				float(x) / size.x * 2 - 1,
				float(y) / size.y * 2 - 1
			)

			var t : float = max(abs(position.x), abs(position.y))

			if t < falloff_start:
				height_map[x][y] = 1
			elif t > falloff_end:
				height_map[x][y] = 0
			else:
				height_map[x][y] = smoothstep(1, 0, inverse_lerp(falloff_start, falloff_end, t))

	return height_map

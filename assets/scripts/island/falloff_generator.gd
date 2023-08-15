class_name FalloffGenerator

static func generate_falloff_map(size : Vector2i, falloff_start : float, falloff_end : float) -> Array:
	var height_map := []
	height_map.resize(size.x * size.y)

	for y in size.y:
		for x in size.x:

			var position := Vector2(
				float(x) / (size.x - 1) * 2 - 1,
				float(y) / (size.y - 1) * 2 - 1
			)

			var t : float = max(abs(position.x), abs(position.y))

			if t <= falloff_start:
				height_map[x + size.x * y] = 0
			elif t >= falloff_end:
				height_map[x + size.x * y] = 1
			else:
				height_map[x + size.x * y] = smoothstep(0, 1, inverse_lerp(falloff_start, falloff_end, t))

	return height_map

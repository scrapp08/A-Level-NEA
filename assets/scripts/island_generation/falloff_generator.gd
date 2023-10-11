class_name FalloffGenerator


static func generate_falloff_map(size : int, resolution : int, falloff_start : float, falloff_end : float) -> Array:
	var height_map := []
	var sample_count := resolution + 1
	height_map.resize(sample_count * sample_count)

	for sy in sample_count:
		var y: float = sy / float(sample_count - 1) * size
		for sx in sample_count:
			var x: float = sx / float(sample_count - 1) * size
			var position := Vector2(
				float(sx) / (size - 1) * 2 - 1,
				float(sy) / (size - 1) * 2 - 1)

			var t : float = max(abs(position.x), abs(position.y))
			if t <= falloff_start:
				height_map[sx + sample_count * sy] = 1
			elif t >= falloff_end:
				height_map[sx + sample_count * sy] = 0
			else:
				height_map[sx + sample_count * sy] = smoothstep(1, 0, inverse_lerp(falloff_start, falloff_end, t))

	return height_map

class_name FalloffGenerator


static func generate_falloff_map(size : int, resolution : int, falloff_start : float, falloff_end : float) -> Array:
	var height_map := []
	var sample_count := resolution + 1
	height_map.resize(sample_count * sample_count) # Initialise array for falloff to populate, corresponding to terrain size

	for sy in sample_count:
		var y: float = sy / float(sample_count - 1) * size
		for sx in sample_count:
			var x: float = sx / float(sample_count - 1) * size
			
			# Get the x and y position of where falloff is being calculated
			var position := Vector2(
				float(x) / (size - 1) * 2 - 1,
				float(y) / (size - 1) * 2 - 1)

			var t: float = max(abs(position.x), abs(position.y))
			
			# Handle what happens if value falls outside defined range of falloff
			if t <= falloff_start:
				height_map[sx + sample_count * sy] = 1
			elif t >= falloff_end:
				height_map[sx + sample_count * sy] = 0
				
			# Smoothly interpolate between 1 and 0, with the weight defined as the falloff value t
			else:
				height_map[sx + sample_count * sy] = smoothstep(1, 0, inverse_lerp(falloff_start, falloff_end, t))

	return height_map

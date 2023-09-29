class_name ImageGenerator


static func generate_image_from_map(size : int, map : Array, render_mode : int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var colour_map : Array[Color] = []
	colour_map.resize(size * size)

	for y in size:
		for x in size:
			var t: float = 0.25 * (
				map[(x + 0) + (size + 1) * (y + 0)] +
				map[(x + 1) + (size + 1) * (y + 0)] +
				map[(x + 0) + (size + 1) * (y + 1)] +
				map[(x + 1) + (size + 1) * (y + 1)])

			if render_mode == 1:
				colour_map[y * size + x] = Color.BLACK.lerp(Color.WHITE, t)
			else:
				colour_map[y * size + x] = Color.WHITE.lerp(Color.BLACK, t)
			image.set_pixel(x, y, colour_map[y * size + x])

#	image.save_png("res://assets/heightmap.png")
	var texture := ImageTexture.create_from_image(image)

	return texture

class_name TextureGenerator


static func generate_texture(noise : FastNoiseLite, width : float, height : float, falloff : bool, falloff_map : Array) -> ImageTexture:
	var noise_image := noise.get_image(width, height)
	noise_image.convert(Image.FORMAT_RGBA8)
	var falloff_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var masked_image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	if falloff:
		var colour_map : Array[Color] = []
		colour_map.resize(width * height)
		for y in height:
			for x in width:
				colour_map[y * width + x] = Color.WHITE.lerp(Color.BLACK, falloff_map[x][y])
				falloff_image.set_pixel(x, y, colour_map[y * width + x])
				var noise_pixel = noise_image.get_pixel(x, y)
				masked_image.set_pixel(x, y, (noise_pixel) - (colour_map[y * width + x]))
		
	else:
		masked_image.set_data(width, height, false, Image.FORMAT_RGBA8, noise_image.get_data())


	var noise_texture := ImageTexture.create_from_image(masked_image)
	return noise_texture

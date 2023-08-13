class_name TextureGenerator


static func generate_noise_texture(noise : FastNoiseLite, width : float, height : float, offset_x : float, offset_y : float) -> ImageTexture:
	var noise_image := noise.get_image(width, height)
	noise_image.convert(Image.FORMAT_RGBA8)

	var noise_texture := ImageTexture.create_from_image(noise_image)
	return noise_texture

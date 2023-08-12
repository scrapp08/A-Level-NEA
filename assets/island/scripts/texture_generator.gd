class_name TextureGenerator


static func generate_noise_texture(noise : FastNoiseLite, width : float, height : float, offset_x : float, offset_y : float, colour : bool, regions : Array) -> ImageTexture:
	var noise_image := noise.get_image(width, height)
	noise_image.convert(Image.FORMAT_RGBA8)
	
	if colour:
		for y in height:
			for x in width:
				var _x = x + offset_x
				var _y = y + offset_y
				var current_height = noise.get_noise_2d(_x, _y)
				for region in regions:
					if(current_height <= region.height):
						noise_image.set_pixel(x, y, region.colour)
						break
	
	var noise_texture := ImageTexture.create_from_image(noise_image)
	return noise_texture

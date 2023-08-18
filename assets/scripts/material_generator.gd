class_name MaterialGenerator


static func generate_material_from_map(size : int,map : Array) -> StandardMaterial3D:
	var image := Image.create(size,size,false,Image.FORMAT_RGBA8)
	var colour_map : Array[Color] = []
	colour_map.resize(size * size)

	for y in size:
		for x in size:
			var t: float = 0.25 * (
				map[(x + 0) + (size + 1) * (y + 0)] +
				map[(x + 1) + (size + 1) * (y + 0)] +
				map[(x + 0) + (size + 1) * (y + 1)] +
				map[(x + 1) + (size + 1) * (y + 1)]
			)
			colour_map[y * size + x] = Color.BLACK.lerp(Color.WHITE, t)
			image.set_pixel(x, y, colour_map[y * size + x])

	var texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.albedo_texture = texture

	return material

class_name MaterialGenerator


static func generate_material_from_map(texture_size : Vector2i, map : Array) -> StandardMaterial3D:
	var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	var colour_map : Array[Color] = []
	colour_map.resize(texture_size.x * texture_size.y)
	for y in texture_size.y:
		for x in texture_size.x:
			var t: float = 0.25 * (
				map[(x + 0) + (texture_size.x + 1) * (y + 0)] +
				map[(x + 1) + (texture_size.x + 1) * (y + 0)] +
				map[(x + 0) + (texture_size.x + 1) * (y + 1)] +
				map[(x + 1) + (texture_size.x + 1) * (y + 1)]
			)
			colour_map[y * texture_size.x + x] = Color.WHITE.lerp(Color.BLACK, t)
			image.set_pixel(x, y, colour_map[y * texture_size.x + x])
	
	var texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.albedo_texture = texture
	
	return material

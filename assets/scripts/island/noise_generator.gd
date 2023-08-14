class_name NoiseGenerator

static func generate_noise_map(size : Vector2i, scale : float):
	var noise_map = []
	noise_map.resize(size.x)
	
	for x in size.x:
		noise_map[x] = []
		noise_map[x].resize(size.y)

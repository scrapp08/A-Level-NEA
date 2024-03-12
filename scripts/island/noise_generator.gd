class_name NoiseGenerator


static func generate_noise_map(size : int, resolution: int, noise_seed : int, noise_scale : float, octaves : int, persistance : float, lacunarity : float, offset : Vector2i) -> Array:
	# generate noise using FastNoiseLite library
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = noise_scale / 10
	noise.fractal_octaves = octaves
	noise.fractal_gain = persistance
	noise.fractal_lacunarity = lacunarity
	noise.seed = noise_seed
	noise.offset = Vector3i(offset.x,offset.y,0)

	# convert noise into an array
	var noise_map := []
	var sample_count := resolution + 1
	noise_map.resize(sample_count * sample_count)
	for sy in sample_count:
		var y: float = sy / float(sample_count - 1) * size
		for sx in sample_count:
			var x: float = sx / float(sample_count - 1) * size
			noise_map[sx + sample_count * sy] = noise.get_noise_2d(x,y) * 0.5 + 0.5

	return noise_map
class_name NoiseGenerator


static func generate_noise_map(scale : float, octaves : int, persistance : float, lacunarity : float, noise_seed : int, offset : Vector2) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = scale / 10
	noise.fractal_octaves = octaves
	noise.fractal_gain = persistance
	noise.fractal_lacunarity = lacunarity
	noise.seed = noise_seed
	noise.offset = Vector3(offset.x, offset.y, 0)
	return noise
 

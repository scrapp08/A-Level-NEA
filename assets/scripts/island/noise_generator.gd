class_name NoiseGenerator


static func generate_noise_map(size : Vector2i, noise_seed : int, scale : float, octaves : int, persistance : float, lacunarity : float) -> Array:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = scale / 10
	noise.fractal_octaves = octaves
	noise.fractal_gain = persistance
	noise.fractal_lacunarity = lacunarity
	noise.seed = noise_seed
	
	var noise_map := []
	noise_map.resize(size.x * size.y)
	for y in size.y:
		for x in size.x:
			noise_map[x + size.x * y] = noise.get_noise_2d(x, y) * 0.5 + 0.5
	
	return noise_map



#static func generate_noise_map(size : Vector2i, noise_seed : int, scale : float) -> Array:
#	var noise_map := []
#	noise_map.resize(size.x * size.y)
#
#	if scale <= 0:
#		scale = 0.0001
#
#	for y in size.y:
#		for x in size.x:
#			var sample_x := x / scale
#			var sample_y := y / scale
#
#			var perlin_value = perlin_noise(noise_seed, sample_x, sample_y)
#			noise_map[x + size.x * y] = perlin_value
#
#	return noise_map
#
#
#static func perlin_noise(noise_seed : int, x : float, y : float) -> float:
## Determine grid cell coordinates
#	var x0 : int = floor(x)
#	var x1 := x0 + 1
#	var y0 : int = floor(y)
#	var y1 := y0 + 1
#
## Determine interpolation weights
#	var sx := x - float(x0)
#	var sy = y - float(y0)
#
## Interpolate between grid point gradients
#	var n0 := grid_gradient(x0, y0, x, y)
#	var n1 := grid_gradient(x1, y0, x, y)
#	var ix0 := lerpf(n0, n1, sx)
#
#	n0 = grid_gradient(x0, y1, x, y)
#	n1 = grid_gradient(x1, y1, x, y)
#	var ix1 := lerpf(n0, n1, sx)
#
#	return lerpf(ix0, ix1, sy) * 0.5 + 0.5
#
#
#static func grid_gradient(ix : int, iy : int, x : float, y : float) -> float:
#	var gradient : Vector2 = random_gradient(ix, iy)
#
#
#static func random_gradient(ix : int, iy : int) -> Vector2:
#	var w : 
#	return v
#

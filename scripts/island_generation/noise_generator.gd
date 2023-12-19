class_name NoiseGenerator


static func generate_noise_map(size : int, resolution: int, noise_seed : int, noise_scale : float, octaves : int, persistance : float, lacunarity : float, offset : Vector2i) -> Noise:
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
#	var noise_map := []
#	var sample_count := resolution + 1
#	noise_map.resize(sample_count * sample_count)
#	for sy in sample_count:
#		var y: float = sy / float(sample_count - 1) * size
#		for sx in sample_count:
#			var x: float = sx / float(sample_count - 1) * size
#			noise_map[sx + sample_count * sy] = noise.get_noise_2d(x,y) * 0.5 + 0.5

	return noise


## FIX: perlin_value always returns 0 for some reason, for now just use FastNoise
#static func generate_noise_map(size : Vector2i, noise_seed : int, scale : float, octaves : int, persistance : float, lacunarity : float, offset : Vector2i) -> Array:
#	var noise_map := []
#	noise_map.resize(size.x * size.y)
#
#
#	var octave_offsets : Array[Vector2]
#	octave_offsets.resize(octaves)
#	for i in octaves:
#		seed(noise_seed)
#		var offset_x := randi_range(-100000, 100000) + offset.x
#		seed(noise_seed)
#		var offset_y := randi_range(-100000, 100000) + offset.y
#		octave_offsets[i] = Vector2(offset_x, offset_y)
#
#	if scale <= 0:
#		scale = 0.0001
#
#	var half_width :=  size.x / 2
#	var half_height := size.y / 2
#
#	var max_noise := float(1.79769e308)
#	var min_noise := float(-1.79769e308)
#
#	for y in size.y:
#		for x in size.x:
#			var amplitude := 1
#			var frequency := 1
#			var noise_height := 0
#
#			for i in octaves:
## Higher frequency makes points further apart
#				var sample_x := (x - half_width) / scale * frequency + octave_offsets[i].x * frequency
#				var sample_y := (y - half_height) / scale * frequency - octave_offsets[i].y * frequency
#
#				var perlin_value = perlin_noise(noise_seed, sample_x, sample_y) * 2 - 1
#				noise_height += perlin_value * amplitude
#
## Amplitude decreases over time with persistance
#				amplitude *= persistance
#				frequency *= lacunarity
#
#			if noise_height < min_noise:
#				noise_height = min_noise
#			if noise_height > max_noise:
#				noise_height = max_noise
#
#			noise_map[x + size.x * y] = noise_height
#
## Normalise values
#	for y in size.y:
#		for x in size.x:
#			noise_map[x + size.x * y] = inverse_lerp(min_noise, max_noise, noise_map[x + size.x * y])
#
#	return noise_map
#
## Compute Perlin noise at coordinates x, y
#static func perlin_noise(noise_seed : int, x : float, y : float) -> float:
## Determine grid cell coordinates
#	var x0 : int = floor(x)
#	var x1 := x0 + 1
#	var y0 : int = floor(y)
#	var y1 := y0 + 1
#
## Determine interpolation weights
#	var sx := x - float(x0)
#	var sy := y - float(y0)
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
## Computes the dot product of the distance and gradient vectors.
#static func grid_gradient(ix : int, iy : int, x : float, y : float) -> float:
## Get gradient from integer coordinates
#	var gradient : Vector2 = random_gradient(ix, iy)
#
## Compute the distance vector
#	var dx = x - float(ix)
#	var dy = y - float(iy)
#
## Compute the dot-product
#	return (dx*gradient.x + dy*gradient.y)
#
## Create pseudorandom direction vector
#static func random_gradient(ix : int, iy : int) -> Vector2:
#	var w : int = 32
#	var s : int = w / 2
#	var a := ix
#	var b := iy
#
#	a *= 3284157443
#	b ^= a << s | a >> w-s
#	b *= 1911520717
#	a ^= b << s | b >> w-s
#	a *= 2048419325
#
#	var random = a * (1.462918e-09)
#
#	var v : Vector2
#	v.x = cos(random)
#	v.y = sin(random)
#
#	return v

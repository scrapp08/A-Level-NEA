@tool
class_name ColliderGen
extends StaticBody3D

# Generation data
var size : int
var resolution : int
var amplitude : float
var noise : NoiseTexture2D
var gen_falloff : bool
var falloff_start : float
var falloff_end : float
var render_vertices : bool

# Collision
var height_map := HeightMapShape3D.new()
var map_data : PackedFloat32Array = []


func generate_collision(data) -> void:
	# Unpack generation data
	size = data[0]
	height_map.map_depth = size
	height_map.map_width = size

	resolution = data[1]
	amplitude = data[2]
	noise = data[3]
	gen_falloff = data[4]
	falloff_start = data[5]
	falloff_end = data[6]
	render_vertices = data[7]

	var increment : float = float(size)/(resolution + 1)
	var bottom_left := Vector3(size * -0.5, 1, size * -0.5)
	var xz := Vector3.ZERO

	for x_step in range(resolution + 2):
		xz.x = bottom_left.x + x_step * increment
		for z_step in range(resolution + 2):
			xz.z = bottom_left.z + z_step * increment
			xz.y = _world_to_texture_value(xz) * amplitude * 2.5
			if gen_falloff:
				xz.y *= _falloff(xz)
				#map_data.append(value * amplitude * _falloff(xz.x, xz.z) * 2.5)
			if render_vertices:
				var sphere_mesh : MeshInstance3D = _spawn_sphere(xz)
				add_child(sphere_mesh)


func _world_to_texture_coordinate(coordinate: Vector3) -> Vector2i:
	var bottom_left := Vector2(size * -0.5, size * -0.5)
	var top_right := Vector2(size * 0.5, size * 0.5)
	var noise_width := noise.width
	var noise_height := noise.height
	var texture_coordinate : Vector2i
	texture_coordinate.x = int(remap(coordinate.x, bottom_left.x, top_right.x, 0.0, noise_width))
	texture_coordinate.y = int(remap(coordinate.z, bottom_left.y, top_right.y, 0.0, noise_height))
	return texture_coordinate


func _world_to_texture_value(coordinate: Vector3) -> float:
	var bottom_left := Vector2(size * -0.5, size * -0.5)
	var top_right := Vector2(size * 0.5, size * 0.5)
	var noise_width := noise.width
	var noise_height := noise.height
	var texture_coordinate : Vector2i
	texture_coordinate.x = int(remap(coordinate.x, bottom_left.x, top_right.x, 0.0, noise_width))
	texture_coordinate.y = int(remap(coordinate.z, bottom_left.y, top_right.y, 0.0, noise_height))
	print(noise.noise.get_noise_2dv(texture_coordinate))
	return noise.noise.get_noise_2dv(texture_coordinate)


func _falloff(world_coordinate: Vector3) -> float:
	var coord_x := remap(world_coordinate.x, float(size) * -0.5, float(size) * 0.5, 1.0, -1.0)
	var coord_z := remap(world_coordinate.z, float(size) * -0.5, float(size) * 0.5, 1.0, -1.0)

	var t : float = max(abs(coord_x), abs(coord_z))
	if t <= falloff_start:
		return 1.0
	elif t > falloff_end:
		return 0.0
	else:
		return smoothstep(1.0, 0.0, inverse_lerp(falloff_start, falloff_end, t))


func _srgb_to_linear(c) -> Vector3:
	return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878)


func _spawn_sphere(position: Vector3) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.position = position
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	instance.mesh = sphere
	return instance



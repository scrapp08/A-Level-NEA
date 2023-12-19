class_name Collider
extends CollisionShape3D

# Generation data
var size : int
var resolution : int
var amplitude : float
var noise : NoiseTexture2D
var gen_falloff : bool
var falloff_start : float
var falloff_end : float

# Collision
var height_map := HeightMapShape3D.new()
var map_data : PackedFloat32Array = []
@onready var collision_shape := $CollisionShape3D


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

	for i in size * size:
		if gen_falloff:
			var value : float = _srgb_to_linear(Vector3(noise, UV, 0).rgb).r
			map_data.append(value * amplitude * _falloff(UV.x, UV.y) * 2.5)
		else:
			var value : float = _srgb_to_linear(Vector3(noise, UV, 0).rgb).r
			map_data.append(value * amplitude)


func _srgb_to_linear(c) -> Vector3:
	return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878)


func _falloff(x : float, y : float) -> float:
	var position := Vector2(
		(x - 0.5) * 2.0,
		(y - 0.5) * 2.0
	)

	var t : float = max(abs(position.x), abs(position.y))
	if t <= falloff_start:
		return 1.0
	elif t > falloff_end:
		return 0.0
	else:
		return smoothstep(1.0, 0.0, inverse_lerp(falloff_start, falloff_end, t))

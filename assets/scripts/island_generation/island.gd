@tool
class_name Island
extends Node3D

@export_category("Mesh")
@export_range(1, 300, 1) var size := 150 :
	set(value):
		size = value
		mesh.set_size(Vector2(size, size))
@export_range(1, 600, 1) var resolution := 300 :
	set(value):
		resolution = value
		mesh.set_subdivide_width(resolution)
		mesh.set_subdivide_depth(resolution)
@export_range(0, 20, 1) var amplitude := 0 :
	set(value):
		amplitude = value
		_generate_island()

@export_category("Noise")
@export_range(0.01, 5, 0.01) var noise_scale := 0.5 :
	set(value):
		noise_scale = value
		_generate_island()
@export_range(1, 10, 1) var octaves := 5 :
	set(value):
		octaves = value
		_generate_island()
@export_range(0.000001, 1, 0.01) var persistance : float :
	set(value):
		persistance = value
		_generate_island()
@export_range(1, 10, 0.01) var lacunarity : float :
	set(value):
		lacunarity = value
		_generate_island()
@export_range(0, 100, 1) var noise_seed : int :
	set(value):
		noise_seed = value
		_generate_island()
@export var offset := Vector2i(0, 0):
	set(value):
		offset = value
		_generate_island()

@export_category("Falloff")
@export var falloff : bool :
	set(value):
		falloff = value
		_generate_island()
@export_range(0.0, 1.0, 0.001) var falloff_start : float :
	set(value):
		falloff_start = value
		_generate_island()
@export_range(0.0, 1.0, 0.001) var falloff_end : float :
	set(value):
		falloff_end = value
		_generate_island()

@export_category("Shader")
@export_enum("Island", "Noise", "Falloff") var render_mode : int :
	set(value):
		render_mode = value
		_generate_island()
@export var terrain_colour : GradientTexture1D :
	set(value):
		terrain_colour = value
		_generate_island()

@onready var mesh_instance := $MeshInstance3D
@onready var mesh : PlaneMesh = mesh_instance.mesh
@onready var island : ShaderMaterial = mesh.get_material()


func _ready() -> void:
	if not is_node_ready(): return
	_generate_island()


func _generate_island() -> void:
	if not is_node_ready(): return
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = NoiseGenerator.generate_noise_map(size, resolution, noise_seed, noise_scale, octaves, persistance, lacunarity, offset)
	await noise_texture.changed

	# Mesh
	island.set_shader_parameter("size", size)
	island.set_shader_parameter("amplitude", amplitude)

	# Noise
	island.set_shader_parameter("noise", noise_texture)

	# Falloff
	island.set_shader_parameter("gen_falloff", falloff)
	island.set_shader_parameter("falloff_start", falloff_start)
	island.set_shader_parameter("falloff_end", falloff_end)

	# Shader
	if render_mode == 1:
		island.set_shader_parameter("debug_noise", true)
	elif render_mode == 2:
		island.set_shader_parameter("debug_falloff", true)

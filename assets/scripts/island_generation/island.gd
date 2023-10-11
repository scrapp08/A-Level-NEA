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
@onready var color_rect := $SubViewport/ColorRect
@onready var terrain : ShaderMaterial = mesh.get_material()
@onready var heightmap : ShaderMaterial = color_rect.get_material()


func _ready() -> void:
	if not is_node_ready(): return
	_generate_island()


func _generate_island() -> void:
	if not is_node_ready(): return
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = NoiseGenerator.generate_noise_map(size, resolution, noise_seed, noise_scale, octaves, persistance, lacunarity, offset)
	await noise_texture.changed
	if render_mode == 0 or render_mode == 1:
		heightmap.set_shader_parameter("noise", noise_texture)
	elif render_mode == 2:
		heightmap.set_shader_parameter("noise", PlaceholderTexture2D.new())

	if falloff:
		var falloff_map := FalloffGenerator.generate_falloff_map(size, resolution, falloff_start, falloff_end)
		var falloff_texture := ImageGenerator.generate_image_from_map(size, falloff_map, render_mode)
		terrain.set_shader_parameter("falloff_map", falloff_texture)
	else:
		terrain.set_shader_parameter("falloff_map", PlaceholderTexture2D.new())

	terrain.set_shader_parameter("amplitude", amplitude)

	var viewport_texture := ViewportTexture.new()
	viewport_texture.set_viewport_path_in_scene("SubViewport")
	terrain.set_shader_parameter("height_map", viewport_texture)

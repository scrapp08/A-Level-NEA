@tool
extends Node3D

@export_category("Mesh")
@export_range(1, 200, 1) var size := 100 :
	set(value):
		size = value
		_clear_vertices()
		generate_island()
@export_range(1, 400, 1) var resolution := 100 :
	set(value):
		resolution = value
		_clear_vertices()
		generate_island()
@export_range(0, 20, 1) var amplitude := 0 :
	set(value):
		amplitude = value
		generate_island()
@export var render_vertices := false :
	set(value):
		render_vertices = value
		_clear_vertices()
		generate_island()
@export var collision : bool :
	set(value):
		collision = value
		generate_island()

@export_category("Noise")
@export_range(0.01, 5, 0.01) var noise_scale := 0.5 :
	set(value):
		noise_scale = value
		generate_island()
@export_range(1, 10, 1) var octaves := 5 :
	set(value):
		octaves = value
		generate_island()
@export_range(0.000001, 1, 0.01) var persistance : float :
	set(value):
		persistance = value
		generate_island()
@export_range(1, 10, 0.01) var lacunarity : float :
	set(value):
		lacunarity = value
		generate_island()
@export_range(0, 100, 1) var noise_seed : int :
	set(value):
		noise_seed = value
		generate_island()
@export var offset := Vector2i(0, 0):
	set(value):
		offset = value
		generate_island()

@export_category("Falloff")
@export var falloff : bool :
	set(value):
		falloff = value
		generate_island()
@export_range(0.0, 1.0, 0.001) var falloff_start : float :
	set(value):
		falloff_start = value
		generate_island()
@export_range(0.0, 1.0, 0.001) var falloff_end : float :
	set(value):
		falloff_end = value
		generate_island()

@export_category("Shader")
@export_enum("Island", "Noise", "Falloff") var render_mode : int :
	set(value):
		render_mode = value
		generate_island()
@export var terrain_colour : GradientTexture1D :
	set(value):
		terrain_colour = value
		generate_island()

var min_height : int
var max_height : int

@onready var mesh := $MeshInstance3D


func _ready() -> void:
	generate_island()


func generate_island() -> void:
	if not is_node_ready(): return

	var noise_map := NoiseGenerator.generate_noise_map(size, resolution, noise_seed, noise_scale, octaves, persistance, lacunarity, offset)
	var falloff_map := FalloffGenerator.generate_falloff_map(size, resolution, falloff_start, falloff_end)

	if falloff:
		for y in resolution + 1:
			for x in resolution + 1:
				# For each point on the noise map, apply the falloff at that point
				noise_map[x + (resolution + 1) * y] = noise_map[x + (resolution + 1) * y] * falloff_map[x + (resolution + 1) * y]

	var mesh_array  = MeshGenerator.generate_mesh(size, resolution, noise_map, amplitude, render_vertices, mesh, min_height, max_height)
	
	# Unpack data from the MeshGenerator
	mesh.mesh = mesh_array[0]
	min_height = mesh_array[1]
	max_height = mesh_array[2]

	if render_mode == 0:
		# Render the island with sand and grass gradient
		var material := ShaderMaterial.new()
		var shader := preload("res://shaders/island.gdshader")

		material.set_shader(shader)
		material.set_shader_parameter("min_height", min_height)
		material.set_shader_parameter("max_height", max_height)
		material.set_shader_parameter("terrain_colour", terrain_colour)

		mesh.set_surface_override_material(0, material)
	
	# Debug falloff rendering
	elif render_mode == 1:
		mesh.set_surface_override_material(0, MaterialGenerator.generate_material_from_map(resolution, noise_map))
	
	# Debug noise rendering
	elif render_mode == 2:
		mesh.set_surface_override_material(0, MaterialGenerator.generate_material_from_map(resolution, falloff_map))
	
	# Clear previous collision and create new collision
	if mesh.get_child_count() > 0:
		mesh.get_child(0).queue_free()
	if collision:
		mesh.create_trimesh_collision()
		

# Debug clear any previous vertices
func _clear_vertices() -> void:
	if not is_node_ready(): return
	for i in mesh.get_children():
			i.free()

@tool
class_name IslandGenerator
extends Node3D

@export_category("Mesh")
@export var mesh_size := Vector2i(100,100) :
	set(value):
		mesh_size = value
		generate_island()
@export_range(0, 20, 1) var mesh_amplitude : int :
	set(value):
		mesh_amplitude = value
		generate_island()
@export var render_vertices : bool :
	set(value):
		render_vertices = value
		_clear_vertices()
		generate_island()

@export_category("Noise")
@export_range(0.01, 5, 0.01) var noise_scale : float = 0.5 :
	set(value):
		noise_scale = value
		generate_island()
@export_range(1, 10, 1) var octaves : int :
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
@export_range(0, 100, 1) var map_seed : int :
	set(value):
		map_seed = value
		generate_island()
@export var map_offset := Vector2i(0, 0):
	set(value):
		map_offset = value
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

@onready var island_mesh := %MeshInstance3D

func _ready() -> void:
	generate_island()


func generate_island() -> void:
	if not is_node_ready(): return
	
	var noise_map := NoiseGenerator.generate_noise_map(mesh_size + Vector2i.ONE, map_seed, noise_scale, octaves, persistance, lacunarity, map_offset)
	if falloff:
		var falloff_map = FalloffGenerator.generate_falloff_map(mesh_size + Vector2i.ONE, falloff_start, falloff_end)
		for y in mesh_size.y:
			for x in mesh_size.x:
				noise_map[x + mesh_size.x * y] = noise_map[x + mesh_size.x * y] - falloff_map[x + mesh_size.x * y]
	island_mesh.mesh = MeshGenerator.generate_mesh(mesh_size, noise_map, mesh_amplitude, render_vertices, island_mesh)
	island_mesh.set_surface_override_material(0, MaterialGenerator.generate_material_from_map(mesh_size, noise_map))


func _clear_vertices() -> void:
	if not is_node_ready(): return
	for i in island_mesh.get_children():
			i.free()

@tool
class_name IslandGenerator
extends Node3D

@export_category("Mesh")
@export var mesh_size := Vector2i(100,100) :
	set(value):
		mesh_size = value
		generate_island()
@export_range(0, 20, 1) var mesh_amplitude : float :
	set(value):
		mesh_amplitude = value
		generate_island()
@export var render_vertices : bool :
	set(value):
		render_vertices = value
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
@export_range(0, 1, 0.01) var persistance : float :
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
@export var map_offset := Vector2(0, 0):
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
	pass


func generate_island() -> void:
	if not is_node_ready(): return
	
	var noise_map := NoiseGenerator.generate_noise_map(mesh_size, map_seed, noise_scale)


func _clear_vertices() -> void:
	for i in get_children():
			i.free()

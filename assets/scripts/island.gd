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


@onready var mesh := $MeshInstance3D


func _ready() -> void:
	generate_island()


func generate_island() -> void:
	if not is_node_ready(): return

	var noise_map := NoiseGenerator.generate_noise_map(size,resolution,noise_seed,noise_scale,octaves,persistance,lacunarity,offset)
	mesh.mesh = MeshGenerator.generate_mesh(size,resolution,noise_map,amplitude,render_vertices,mesh)
	mesh.set_surface_override_material(0, MaterialGenerator.generate_material_from_map(resolution,noise_map))


func _clear_vertices() -> void:
	if not is_node_ready(): return
	for i in mesh.get_children():
			i.free()

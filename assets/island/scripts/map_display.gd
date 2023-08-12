@tool
class_name MapDisplay
extends Node3D

@export_category("Noise Map")
@export var map_size := Vector2(100,100) :
	set(value):
		map_size = value
		display_noise_map()
@export_range(0.01, 5, 0.01) var noise_scale : float = 0.5 :
	set(value):
		noise_scale = value
		display_noise_map()
@export_range(1, 10, 1) var octaves : int :
	set(value):
		octaves = value
		display_noise_map()
@export_range(0, 1, 0.01) var persistance : float :
	set(value):
		persistance = value
		display_noise_map()
@export_range(1, 10, 0.01) var lacunarity : float :
	set(value):
		lacunarity = value
		display_noise_map()
@export_range(0, 100, 1) var map_seed : int :
	set(value):
		map_seed = value
		display_noise_map()
@export var map_offset := Vector2(0, 0):
	set(value):
		map_offset = value
		display_noise_map()
@export_category("Colour")
@export var colour := false:
	set(value):
		colour = value
		display_noise_map()
@export var regions : Array[Resource] :
	set(value):
		regions = value
		display_noise_map()
@export_category("Mesh")
@export_range(0.0, 1.0, 0.01) var height_scale : float :
	set(value):
		height_scale = value
		display_noise_map()

@onready var mesh_instance := $MeshInstance3D
@onready var mesh_shader = preload("res://assets/island/shaders/island_mesh.gdshader")


func _ready() -> void:
	display_noise_map()


func display_noise_map() -> void:
	if not is_node_ready(): return
	
	var noise_map := NoiseGenerator.generate_noise_map(noise_scale, octaves, persistance, lacunarity, map_seed, map_offset)
# Convert noise to texture & apply colour
	var noise_texture := TextureGenerator.generate_noise_texture(noise_map, map_size.x, map_size.y, map_offset.x, map_offset.y, colour, regions)
	var texture_material := StandardMaterial3D.new()
	texture_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	texture_material.albedo_texture = noise_texture
	
	mesh_instance.set_surface_override_material(0, texture_material)
	mesh_instance.mesh.size = map_size
# Mesh
	var mesh_material := ShaderMaterial.new()
	var mesh_noise := NoiseTexture2D.new()
	mesh_noise.set_noise(noise_map)
	mesh_instance.mesh.set_material(mesh_material)
	mesh_material.set_shader(mesh_shader)
	mesh_material.set_shader_parameter("noise", mesh_noise)
	
	
# TODO: DON'T GENERATE VAR'S INSIDE display_noise_map() FOR PERFORMANCE, SET HEIGHT_SCALE FROM INSPECTOR

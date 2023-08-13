@tool
class_name TerrainGeneration
extends MeshInstance3D

@export_category("Mesh")
@export var size := Vector2(100,100) :
	set(value):
		size = value
		clear_vertices()
		generate_mesh()
@export_range(0, 20, 1) var amplitude : float :
	set(value):
		amplitude = value
		clear_vertices()
		generate_mesh()
@export var render_vertices : bool :
	set(value):
		render_vertices = value
		clear_vertices()
		generate_mesh()
@export_category("Noise")
@export_range(0.01, 5, 0.01) var noise_scale : float = 0.5 :
	set(value):
		noise_scale = value
		generate_terrain()
@export_range(1, 10, 1) var octaves : int :
	set(value):
		octaves = value
		generate_terrain()
@export_range(0, 1, 0.01) var persistance : float :
	set(value):
		persistance = value
		generate_terrain()
@export_range(1, 10, 0.01) var lacunarity : float :
	set(value):
		lacunarity = value
		generate_terrain()
@export_range(0, 100, 1) var map_seed : int :
	set(value):
		map_seed = value
		generate_terrain()
@export var map_offset := Vector2(0, 0):
	set(value):
		map_offset = value
		generate_terrain()
@export_category("Falloff")
@export var falloff : bool :
	set(value):
		falloff = value
		generate_terrain()
@export_range(0.0, 1.0, 0.001) var falloff_start : float :
	set(value):
		falloff_start = value
		generate_terrain()
		clear_vertices()
		generate_mesh()
@export_range(0.0, 1.0, 0.001) var falloff_end : float :
	set(value):
		falloff_end = value
		generate_terrain()
		clear_vertices()
		generate_mesh()

@onready var array_mesh : ArrayMesh
@onready var texture_material := StandardMaterial3D.new()
@onready var noise_map : Noise
@onready var falloff_map : Array


func _ready():
	generate_terrain()
	clear_vertices()
	generate_mesh()


func clear_vertices():
	for i in get_children():
			i.free()


func generate_mesh():
	if not is_node_ready(): return
	
	var surftool = SurfaceTool.new()
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(size.y + 1):
		for x in range(size.x + 1):
			var y = (noise_map.get_noise_2d(x, z) - falloff_map[x][z]) * amplitude * 2.5
			
			var uv = Vector2()
			uv.x = inverse_lerp(0, size.x, x)
			uv.y = inverse_lerp(0, size.y, z)
			surftool.set_uv(uv)
			
			surftool.add_vertex(Vector3(x,y,z))
			if render_vertices:
				draw_sphere(Vector3(x,y,z))
	
	var vert = 0
	for y in size.y:
		for x in size.x:
			surftool.add_index(vert + 0)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + size.x + 1)
			surftool.add_index(vert + size.x + 1)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + size.x + 2)
			vert += 1
		vert += 1
		
	surftool.generate_normals()
	array_mesh = surftool.commit()
	mesh = array_mesh


# Draws spheres at vertices
func draw_sphere(position : Vector3):
	var instance = MeshInstance3D.new()
	add_child(instance)
	instance.position = position
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	instance.mesh = sphere


func generate_terrain() -> void:
	if not is_node_ready(): return
	
	noise_map = NoiseGenerator.generate_noise_map(noise_scale, octaves, persistance, lacunarity, map_seed, map_offset)
	if falloff: falloff_map = FalloffGenerator.generate_falloff_map(size, falloff_start, falloff_end)
# Convert noise to material
	var noise_texture := TextureGenerator.generate_texture(noise_map, size.x, size.y, falloff, falloff_map)
	texture_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	texture_material.albedo_texture = noise_texture
	set_surface_override_material(0, texture_material)


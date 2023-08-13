@tool
class_name TerrainGeneration
extends MeshInstance3D

@export_category("Mesh")
@export var size := Vector2(20,20) :
	set(value):
		size = value
		clear_vert_vis()
		generate_terrain()
@export_range(0.01, 1.0, 0.01) var height_scale : float :
	set(value):
		height_scale = value
		clear_vert_vis()
		generate_terrain()
@export var render_vertices : bool :
	set(value):
		render_vertices = value
		clear_vert_vis()
		generate_terrain()
@export_category("Noise")
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

@onready var array_mesh : ArrayMesh
@onready var surftool := SurfaceTool.new()
@onready var mesh_shader = preload("res://assets/shaders/island/island_mesh.gdshader")
@onready var texture_material := StandardMaterial3D.new()
@onready var mesh_material := ShaderMaterial.new()
@onready var mesh_noise := NoiseTexture2D.new()

func _ready():
	clear_vert_vis()
	generate_terrain()
	display_noise_map()


func clear_vert_vis():
	for i in get_children():
			i.free()


func generate_terrain():
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(size.y + 1):
		for x in range(size.x + 1):
			var y = 0
			
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
func draw_sphere(pos : Vector3):
	var ins = MeshInstance3D.new()
	add_child(ins)
	ins.position = pos
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	ins.mesh = sphere

func display_noise_map() -> void:
	if not is_node_ready(): return
	
	var noise_map := NoiseGenerator.generate_noise_map(noise_scale, octaves, persistance, lacunarity, map_seed, map_offset)
# Convert noise to texture
	var noise_texture := TextureGenerator.generate_noise_texture(noise_map, size.x, size.y, map_offset.x, map_offset.y)
	texture_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	texture_material.albedo_texture = noise_texture
	
	set_surface_override_material(0, texture_material)
	mesh.size = size
# Mesh
	mesh_noise.set_noise(noise_map)
	mesh.set_material(mesh_material)
	mesh_material.set_shader(mesh_shader)
	mesh_material.set_shader_parameter("noise", mesh_noise)
	mesh_material.set_shader_parameter("height_scale", height_scale)

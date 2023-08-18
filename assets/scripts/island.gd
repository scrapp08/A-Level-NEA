@tool
extends Node3D

@export_category("Mesh")
@export_range(1, 200, 1) var size := 100 :
	set(value):
		size = value
		_clear_vertices()
		generate_island()
@export_range(1, 100, 1) var resolution := 10 :
	set(value):
		resolution = value
		_clear_vertices()
		generate_island()
@export var render_vertices := false :
	set(value):
		render_vertices = value
		_clear_vertices()
		generate_island()

@onready var mesh := $MeshInstance3D


func _ready() -> void:
	generate_island()


func generate_island() -> void:
	if not is_node_ready(): return
	
	mesh.mesh = MeshGenerator.generate_mesh(size, resolution, render_vertices, mesh)

func _clear_vertices() -> void:
	if not is_node_ready(): return
	for i in mesh.get_children():
			i.free()

class_name MeshGenerator


static func generate_mesh(size : int, resolution : int, render_vertices : bool, mesh : MeshInstance3D) -> ArrayMesh:
	var array_mesh : ArrayMesh
	var surf_tool := SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertex_count : Vector2i
	vertex_count.x = resolution + 1
	vertex_count.y = resolution + 1
	
	for z in vertex_count.y:
		for x in vertex_count.x:
			# get the percentage of the current point
			var percent := Vector2(x,z) / resolution
			# create point on mesh and offset by -0.5 to centre origin
			var point_on_mesh := Vector3((percent.x - 0.5),0,(percent.y - 0.5))
			# get vertex position
			var vertex := point_on_mesh * size
			vertex.y = 0
			
			var uv := Vector2()
			uv.x = percent.x
			uv.y = percent.y
			
			surf_tool.set_uv(uv)
			surf_tool.add_vertex(vertex)
			
			if render_vertices:
				_render_vertex_points(vertex, mesh)
	
	var vert = 0
	for y in resolution:
		for x in resolution:
			surf_tool.add_index(vert + 0)
			surf_tool.add_index(vert + 1)
			surf_tool.add_index(vert + resolution + 1)
			surf_tool.add_index(vert + resolution + 1)
			surf_tool.add_index(vert + 1)
			surf_tool.add_index(vert + resolution + 2)
			vert += 1
		vert += 1
	
	surf_tool.generate_normals()
	array_mesh = surf_tool.commit()
	return array_mesh


static func _render_vertex_points(vertex : Vector3, mesh : MeshInstance3D) -> void:
	var instance = MeshInstance3D.new()
	mesh.add_child(instance)
	instance.position = vertex
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	instance.mesh = sphere

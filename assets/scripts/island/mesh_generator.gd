class_name MeshGenerator


static func generate_mesh(mesh_size : Vector2i, noise_map : Array, amplitude : int, render_vertices : bool, mesh_instance : MeshInstance3D) -> ArrayMesh:
	var surftool = SurfaceTool.new()
	var array_mesh = ArrayMesh.new()
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertex_count : Vector2i
	vertex_count.x = mesh_size.x + 1
	vertex_count.y = mesh_size.y + 1
	
	for z in vertex_count.y:
		for x in vertex_count.x:
			var y = noise_map[x + vertex_count.x * z] * amplitude * 2.5
			
			var uv = Vector2()
			uv.x = inverse_lerp(0, mesh_size.x, x)
			uv.y = inverse_lerp(0, mesh_size.y, z)
			surftool.set_uv(uv)
			
			surftool.add_vertex(Vector3(x,y,z))
			if render_vertices:
				draw_sphere(Vector3(x,y,z), mesh_instance)
	
	var vert = 0
	for y in mesh_size.y:
		for x in mesh_size.x:
			surftool.add_index(vert + 0)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + mesh_size.x + 1)
			surftool.add_index(vert + mesh_size.x + 1)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + mesh_size.x + 2)
			vert += 1
		vert += 1
		
	surftool.generate_normals()
	array_mesh = surftool.commit()
	return array_mesh


static func draw_sphere(position : Vector3, mesh_instance : MeshInstance3D):
	var instance = MeshInstance3D.new()
	mesh_instance.add_child(instance)
	instance.position = position
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	instance.mesh = sphere

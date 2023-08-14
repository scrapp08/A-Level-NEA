class_name MeshGenerator

static func generate_mesh(size, noise_map, falloff_map, amplitude, render_vertices : bool, array_mesh):
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
	return array_mesh

static func draw_sphere(position : Vector3):
	var instance = MeshInstance3D.new()
	add_child(instance)
	instance.position = position
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	instance.mesh = sphere

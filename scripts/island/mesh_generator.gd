class_name MeshGenerator


static func generate_mesh(size : int, resolution : int, noise_map : Array, amplitude : int, render_vertices : bool, mesh : MeshInstance3D, min_height : int, max_height : int) -> Array:
	var array_mesh : ArrayMesh
	var surf_tool := SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	@warning_ignore("unassigned_variable")
	var vertex_count : Vector2i
	vertex_count.x = resolution + 1
	vertex_count.y = resolution + 1

	for z in vertex_count.y:
		for x in vertex_count.x:
			# Get the percentage of the current point
			var percent := Vector2(x,z) / resolution
			# Create point on mesh and offset by -0.5 to centre origin
			var point_on_mesh := Vector3((percent.x - 0.5),0,(percent.y - 0.5))
			# Get vertex position
			var vertex_position := point_on_mesh * size
			vertex_position.y = noise_map[x + vertex_count.x * z] * amplitude * 2.5
			
			# Set min and max height for the terrain shader
			if vertex_position.y < min_height and vertex_position.y != null:
				@warning_ignore("narrowing_conversion")
				min_height = vertex_position.y - 3
			if vertex_position.y > max_height and vertex_position.y != null:
				@warning_ignore("narrowing_conversion")
				max_height = vertex_position.y + 3

			var uv := Vector2()
			uv.x = percent.x
			uv.y = percent.y
			
			# Calculate mesh UVs
			surf_tool.set_uv(uv)
			surf_tool.add_vertex(vertex_position)
			
			# Debug render vertices
			if render_vertices:
				_render_vertex_points(vertex_position,mesh)
	
	# Add vertices to index array
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
	var array := [array_mesh, min_height, max_height]
	return array


# Debug render vertices function
static func _render_vertex_points(vertex : Vector3,mesh : MeshInstance3D) -> void:
	var instance = MeshInstance3D.new()
	mesh.add_child(instance)
	instance.position = vertex
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	instance.mesh = sphere

extends Node
class_name CeilingCreator

static  func create_from_vertices(vertices: PackedVector3Array):
	var height = vertices[0].y
	var points2d = PackedVector2Array();
	for vertex in vertices:
		points2d.append(Vector2(vertex.x, vertex.z))
	print(points2d)
	var triangles = Triangulation.triangulate(points2d)
	
	var verts = vertices
	var uvs = PackedVector2Array()
	for idx in verts.size():
		uvs.append(Vector2(verts[idx].x, verts[idx].z))
	
	var normals = PackedVector3Array()
	var normalsf = PackedVector3Array()
	for idx in verts.size():
		normals.append(Vector3.UP)
		normalsf.append(-Vector3.UP)
	
	var indices = PackedInt32Array()
	for triangle in triangles:
		for point in triangle:
			var point3d = Vector3(point.x, height, point.y)
			for idx in verts.size():
				if verts[idx].is_equal_approx(point3d):
					indices.append(idx)
	#top
	var mesh = ArrayMesh.new()
	var surface_array_top = []
	surface_array_top.resize(Mesh.ARRAY_MAX)
	surface_array_top[Mesh.ARRAY_VERTEX] = verts
	surface_array_top[Mesh.ARRAY_TEX_UV] = uvs
	surface_array_top[Mesh.ARRAY_NORMAL] = normals
	surface_array_top[Mesh.ARRAY_INDEX] = indices
	
	print(indices)
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array_top)
	
	#border
	var surface_array_border = []
	surface_array_border.resize(Mesh.ARRAY_MAX)
	var border_vertices = PackedVector3Array()
	var border_indices = PackedInt32Array()
	var border_normals = PackedVector3Array()
	var border_uvs = PackedVector2Array()
	for idx in vertices.size():
		var vert = vertices[idx]
		var vert_next = vertices[(idx+1) % vertices.size()]
		var normal = (-vert_next+vert).cross(Vector3.UP).normalized()
		border_vertices.append(Vector3(vert))
		border_vertices.append(Vector3(vert.x, vert.y - 0.2, vert.z))
		border_vertices.append(Vector3(vert_next))
		border_vertices.append(Vector3(vert_next.x, vert_next.y - 0.2, vert_next.z))
		
		var last_idx = border_vertices.size()-1
		border_indices.append_array([last_idx-3, last_idx-2, last_idx-1])
		border_indices.append_array([last_idx-1, last_idx-2, last_idx])
		for i in 4:
			border_normals.append(normal)
			border_uvs.append(Vector2.ZERO)

	surface_array_border[Mesh.ARRAY_VERTEX] = border_vertices
	surface_array_border[Mesh.ARRAY_TEX_UV] = border_uvs
	surface_array_border[Mesh.ARRAY_NORMAL] = border_normals
	surface_array_border[Mesh.ARRAY_INDEX] = border_indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array_border)
	
	#bottom
	var surface_array_bottom = []
	surface_array_bottom.resize(Mesh.ARRAY_MAX)
	var bottom_vertices = PackedVector3Array()
	var bottom_indices = PackedInt32Array()
	for vert in vertices:
		bottom_vertices.append(Vector3(vert.x, vert.y - 0.2, vert.z))
	for idx in indices.size()/3:
		bottom_indices.append(indices[idx*3+2])
		bottom_indices.append(indices[idx*3+1])
		bottom_indices.append(indices[idx*3])
		
	
	surface_array_bottom[Mesh.ARRAY_VERTEX] = bottom_vertices
	surface_array_bottom[Mesh.ARRAY_TEX_UV] = uvs
	surface_array_bottom[Mesh.ARRAY_NORMAL] = normalsf
	surface_array_bottom[Mesh.ARRAY_INDEX] = bottom_indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array_bottom)
	mesh.regen_normal_maps()
	
	return mesh
	

@tool
extends Node


@export var object: CSGPrimitive3D

func _ready() -> void:
	pass

func process_modifier(verts: PackedVector3Array, normals, uvs, indices):
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var csgmesh = CSGMesh3D.new()
	csgmesh.mesh = mesh
	
	csgmesh.add_child(object)
	var new_mesh = csgmesh.get_meshes()[1]
	verts.clear()
	verts.append_array(new_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	
	uvs.clear()
	uvs.append_array(new_mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV])
	
	normals.clear()
	normals.append_array(new_mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL])
	
	indices.clear()
	indices.append_array(new_mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX])
	

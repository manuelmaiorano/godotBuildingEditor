@tool
extends MeshInstance3D
class_name GenericMesh

@export var cmesh: ControllableMesh = null :
	set(value):
		if value != null:
			cmesh = value.duplicate(true).initialize()
			update_mesh()
		else:
			cmesh = null


func translate_vgroup(vgroup, vec: Vector3):
	cmesh.translate_vgroup(vgroup, vec)
	update_mesh()

func update_mesh():
	mesh = ArrayMesh.new()
	var surface_array = []
	for surf in cmesh.surfaces:
		surface_array.resize(Mesh.ARRAY_MAX)
		surface_array[Mesh.ARRAY_VERTEX] = surf.verts
		surface_array[Mesh.ARRAY_TEX_UV] =  surf.uvs
		surface_array[Mesh.ARRAY_NORMAL] = surf.normals
		surface_array[Mesh.ARRAY_INDEX] =  surf.indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	update_gizmos()

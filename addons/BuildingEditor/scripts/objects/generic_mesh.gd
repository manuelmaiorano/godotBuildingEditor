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

##########################controllable
func translate_vgroup(vg_name, vec: Vector3):
	var axis: Vector3 = get_axis(vg_name).abs()
	cmesh.translate_vgroup(vg_name, vec * axis)
	update_mesh()

func get_vgroups():
	return cmesh.vgroups.groups

func get_handle_point(vg_name):
	return cmesh.get_handle_point(vg_name)


func get_handle_name(handle_id):
	return cmesh.vgroups.groups[handle_id].name

func get_drag_segment(vg_name):
	var segment = []
	var pt = get_handle_point(vg_name)
	
	var axis = get_axis(vg_name)

	segment.append(global_transform * (pt - axis.abs() * pt))
	segment.append(global_transform * (pt + axis*4096))
	return segment

func get_axis(vg_name):
	var axis := Vector3.ZERO
	if vg_name.contains("mz"):
		axis[1] = -1.0
	elif vg_name.contains("mx"):
		axis[0] = -1.0
	elif vg_name.contains("my"):
		axis[2] = -1.0
	elif vg_name.contains("z"):
		axis[1] = 1.0
	elif vg_name.contains("x"):
		axis[0] = 1.0
	elif vg_name.contains("y"):
		axis[2] = 1.0

	return axis

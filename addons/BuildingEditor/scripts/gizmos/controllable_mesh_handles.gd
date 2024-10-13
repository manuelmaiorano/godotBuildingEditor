extends EditorNode3DGizmoPlugin


func _get_gizmo_name():
	return "ControllableMeshHandles"



func _has_gizmo(node):
	return node is GenericMesh


func _init():
	create_material("main", Color(1, 0, 0))
	create_handle_material("handles")


func _redraw(gizmo):
	gizmo.clear()
	var cmesh = gizmo.get_node_3d().cmesh	
	var handles = PackedVector3Array()
	var indices = []
	var i = 0

	for vg in cmesh.vgroups.groups:
		var pt = cmesh.get_handle_point(vg.name)
		handles.push_back(pt)
		indices.append(i)
		i += 1


	gizmo.add_handles(handles, get_material("handles", gizmo), indices)


func _get_handle_name(gizmo, handle_id, secondary):
	var cmesh: ControllableMesh = gizmo.get_node_3d().cmesh
	return cmesh.vgroups.groups[handle_id].name

func _get_handle_value(gizmo, handle_id, secondary):
	var cmesh: ControllableMesh = gizmo.get_node_3d().cmesh
	return cmesh.get_handle_point(cmesh.vgroups.groups[handle_id].name)

func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2):
	
	var axis := Vector3.ZERO

	var cmesh = gizmo.get_node_3d().cmesh
	var vg_name = cmesh.vgroups.groups[handle_id].name
	var pt = cmesh.get_handle_point(cmesh.vgroups.groups[handle_id].name)

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

	var n = gizmo.get_node_3d()
	var gt := n.get_global_transform()
	var gt_inverse := gt.affine_inverse()

	var origin := gt.origin
	var drag_axis := (axis * 4096) * gt_inverse
	var ray_from = camera.project_ray_origin(screen_pos)
	var ray_to = ray_from + camera.project_ray_normal(screen_pos) * 4096

	var points = Geometry3D.get_closest_points_between_segments(origin, drag_axis, ray_from, ray_to)

	if axis.x + axis.y + axis.z < 0:
		n.translate_vgroup(vg_name, points[0] + pt * axis )
	else:
		n.translate_vgroup(vg_name, points[0] - pt * axis )
	n.update_gizmos()
	
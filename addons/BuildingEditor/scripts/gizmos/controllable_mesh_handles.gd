extends EditorNode3DGizmoPlugin


func _get_gizmo_name():
	return "ControllableMeshHandles"



func _has_gizmo(node):
	return node is GenericMesh or node is Wall


func _init():
	create_material("main", Color(1, 0, 0))
	create_handle_material("handles")


func _redraw(gizmo):
	gizmo.clear()
	var node = gizmo.get_node_3d()	
	var handles = PackedVector3Array()
	var indices = []
	var i = 0

	for vg in node.get_vgroups():
		var pt = node.get_handle_point(vg.name)
		handles.push_back(pt)
		indices.append(i)
		i += 1


	gizmo.add_handles(handles, get_material("handles", gizmo), indices)


func _get_handle_name(gizmo, handle_id, secondary):
	var node = gizmo.get_node_3d()
	return node.get_handle_name(handle_id)

func _get_handle_value(gizmo, handle_id, secondary):
	var node = gizmo.get_node_3d()
	return node.get_handle_point(node.get_handle_name(handle_id))

func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2):
	
	var axis := Vector3.ZERO

	var node = gizmo.get_node_3d()
	var vg_name = node.get_handle_name(handle_id)
	var pt = node.get_handle_point(vg_name)

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
	elif node is Wall:
		axis[1] = 1.0
	else:
		return

	var gt := node.get_global_transform()
	var gt_inverse := gt.affine_inverse()

	var origin := gt.origin
	var drag_axis := (axis * 4096) * gt_inverse
	var ray_from = camera.project_ray_origin(screen_pos)
	var ray_to = ray_from + camera.project_ray_normal(screen_pos) * 4096

	var points = Geometry3D.get_closest_points_between_segments(origin, drag_axis, ray_from, ray_to)

	var pt_on_axis =  gt_inverse * points[0]

	pt_on_axis = pt_on_axis.snapped(Vector3.ONE * 0.25)

	if axis.x + axis.y + axis.z < 0:
		node.translate_vgroup(vg_name, pt_on_axis + pt * axis )
	else:
		node.translate_vgroup(vg_name, pt_on_axis - pt * axis )
	node.update_gizmos()
	
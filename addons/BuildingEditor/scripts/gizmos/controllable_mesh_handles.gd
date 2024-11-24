extends EditorNode3DGizmoPlugin


func _get_gizmo_name():
	return "ControllableMeshHandles"



func _has_gizmo(node):
	return node is GenericMesh or node is Wall or node is Ceiling


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
	
	var node = gizmo.get_node_3d()
	var vg_name = node.get_handle_name(handle_id)
	var local_handle_point = node.get_handle_point(vg_name)
	var handle_point = node.transform * local_handle_point
	
	var segment = node.get_drag_segment(vg_name)
	
	var ray_from = camera.project_ray_origin(screen_pos)
	var ray_to = ray_from + camera.project_ray_normal(screen_pos) * 4096

	var points = Geometry3D.get_closest_points_between_segments(
		segment[0], segment[1], 
		ray_from, ray_to)

	var pt_on_axis =  points[0]#gt_inverse * points[0]

	pt_on_axis = pt_on_axis.snapped(Vector3.ONE * 0.25)

	var offset = pt_on_axis - handle_point
	node.translate_vgroup(vg_name, offset)

	node.update_gizmos()
	
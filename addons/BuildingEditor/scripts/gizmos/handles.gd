extends EditorNode3DGizmoPlugin

var arrow_mesh = preload("res://addons/BuildingEditor/assets/gizmos/arrow.res")
var arrow_mat = preload("res://addons/BuildingEditor/assets/gizmos/arrow_mat.tres")



func _get_gizmo_name():
	return "ControlHandles"



func _has_gizmo(node):
	return node is Roof


func _init():
	create_material("main", Color(1, 0, 0))
	create_handle_material("handles")


func _redraw(gizmo):
	gizmo.clear()
	var roof = gizmo.get_node_3d()
	# var transform = Transform3D()
	# transform.origin = Vector3(  (roof.front + roof.back)/2, 0, roof.currentz)
	# gizmo.add_mesh(arrow_mesh, arrow_mat, transform )
	# gizmo.add_collision_triangles(arrow_mesh)
	
	var handles = PackedVector3Array()
	handles.push_back(Vector3((roof.back+roof.front)/2, roof.height, 0))
	handles.push_back(Vector3(roof.front, 0, 0))
	handles.push_back(Vector3(roof.back, 0, 0))
	handles.push_back(Vector3((roof.back+roof.front)/2, 0, roof.currentz))
	handles.push_back(Vector3((roof.back+roof.front)/2, 0, -roof.currentz))

	gizmo.add_handles(handles, get_material("handles", gizmo), [0, 1, 2, 3, 4])


func _get_handle_name(gizmo, handle_id, secondary):
	match handle_id:
		0: return "h"
		1: return "f"
		2: return "b"
		3: return "s1"
		4: return "s2"

func _get_handle_value(gizmo, handle_id, secondary):
	var n = gizmo.get_node_3d()
	match handle_id:
		0: return n.height
		1: return n.front
		2: return n.back
		3: return n.currentz
		4: return -n.currentz

func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2):
	
	var axis := Vector3.ZERO

	match handle_id:
		0: axis[1] = 1.0 
		1: axis[0] = 1.0 
		2: axis[0] = -1.0 
		3: axis[2] = 1.0 
		4: axis[2] = -1.0 

	var n = gizmo.get_node_3d()
	var gt := n.get_global_transform()
	var gt_inverse := gt.affine_inverse()

	var origin := gt.origin
	var drag_axis := (axis * 4096) * gt_inverse
	var ray_from = camera.project_ray_origin(screen_pos)
	var ray_to = ray_from + camera.project_ray_normal(screen_pos) * 4096

	var points = Geometry3D.get_closest_points_between_segments(origin, drag_axis, ray_from, ray_to)



	match handle_id:
		0: 
			var new_h = origin.distance_to(points[0]) 
			n.move_mesh("h", Vector3(0, new_h - n.height , 0))
			n.height = new_h
		1: 
			var new_f = origin.distance_to(points[0]) 
			n.move_mesh("f", Vector3(new_f - n.front , 0, 0))
			n.front = new_f
		2: 
			var new_b = -origin.distance_to(points[0]) 
			n.move_mesh("b", Vector3(new_b - n.back , 0, 0))
			n.back = new_b
		3: 
			var new_z = origin.distance_to(points[0]) 
			n.scale_mesh(Vector3(0, 0, new_z - n.currentz))
			n.currentz = new_z
		4: 
			var new_z = origin.distance_to(points[0]) 
			n.scale_mesh(Vector3(0, 0, new_z - n.currentz))
			n.currentz = new_z
	n.update_gizmos()
	
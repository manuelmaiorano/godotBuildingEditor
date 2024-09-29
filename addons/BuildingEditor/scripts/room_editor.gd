@tool
extends Node3D
class_name RoomEditor


enum EDITOR_STATE {DRAW, DELETE, CONTINUE, ADD_OPENING, PAINT, DECORATION}

@onready var points: Array[Vector3] = []
@onready var wall_instances: Array[Wall] = []
@onready var state: EDITOR_STATE = EDITOR_STATE.DRAW
@onready var handle: PositionHandle = null

@export var reset = false

@export var height = 2.4
@export var width = 0.2

@export var snap_amount = 0.5
@export var material_to_paint: StandardMaterial3D = null
@export var curr_decoration: ControllableSurf
@export var curr_open_scene: PackedScene

var rooms: Array[Room]

func set_state(new_state: EDITOR_STATE):
	state = new_state

func _process(delta: float) -> void:
	if reset:
		_on_reset()
		reset = false
		
func _on_reset():
	
	handle = null
	$Handle.queue_free()
	points = []
	wall_instances = []
	rooms = []
	for child in get_node("generated").get_children():
		child.queue_free()
	
func snap_point(point, snap_to_axis, snap_to_grid):
	var snapped_point = Vector3(point)
	if snap_to_axis and points.size() > 0:
		var rel_point = point - points.back()
		if abs(rel_point.x) < abs(rel_point.z):
			snapped_point.x = points.back().x
		else:
			snapped_point.z = points.back().z
	if snap_to_grid:
		snapped_point = snapped_point.snapped(Vector3.ONE * snap_amount)
	return snapped_point

func connect_walls(wall1, wall2):
	wall1.add_wall_connection(wall2)
	wall2.add_wall_connection(wall1)

class WallIntercData:
	var len_along_wall: float
	var is_side_out: bool
	var point_at_bottom: Vector3
	var transform: Transform3D
	var bool_origin: Vector3


func get_wall_interc_data(wall, raycast_pos, snap_to_grid = false):
	var data = WallIntercData.new()

	var tr = wall.transform
	var rayc_in_tr = tr.inverse() * raycast_pos
	if snap_to_grid:
		var snapped = rayc_in_tr.snapped(Vector3.ONE * snap_amount)
		rayc_in_tr.z = snapped.z
		raycast_pos = tr * rayc_in_tr
	
	data.point_at_bottom = Vector3(raycast_pos.x, tr.origin.y, raycast_pos.z)
	data.len_along_wall = rayc_in_tr.z
	data.is_side_out = rayc_in_tr.x < wall.width/2
	data.transform = wall.transform
	data.bool_origin = tr * Vector3(wall.width/2, 0, rayc_in_tr.z)
	return data
	

func process_event(event, raycast_result):
	match  state:
		EDITOR_STATE.DRAW:
			if event is InputEventKey:
				if event.pressed and event.keycode == KEY_C:
					create_floor(points)
					process_new_point(points[0])
					
					#wall connections
					connect_walls(wall_instances.back(), wall_instances[wall_instances.size()-2])
					connect_walls(wall_instances.back(), wall_instances[0])

					points.clear()
					wall_instances.clear()
					#rooms.append(room)
					get_rooms()
			if event is InputEventMouse:
				if !raycast_result:
					return EditorPlugin.AFTER_GUI_INPUT_PASS
				var point = raycast_result.position
				var snapped_point = snap_point(point, true, true)
				
				if event is InputEventMouseMotion:
					update_gizmo(snapped_point)
					return EditorPlugin.AFTER_GUI_INPUT_PASS
				elif event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						var coll_parent = raycast_result.collider.get_parent()
						if coll_parent is Wall:
							var wall: Wall = coll_parent

							var data: WallIntercData = get_wall_interc_data(coll_parent, raycast_result.position, true)
							update_gizmo(data.point_at_bottom)
							
							wall.add_split_len(data.len_along_wall, data.is_side_out)
							if points.size() > 0:
								process_new_point(handle.global_position)
								
								#connect walls
								connect_walls(wall_instances.back(), wall_instances[wall_instances.size()-2])
								connect_walls(wall_instances.back(), wall)
								
								points.clear()
								wall_instances.clear()

								create_floors()
								return EditorPlugin.AFTER_GUI_INPUT_STOP
							else:
								process_new_point(handle.global_position)
								wall_instances.append(wall)
								return EditorPlugin.AFTER_GUI_INPUT_STOP
								
						process_new_point(handle.global_position)
						if wall_instances.size() >= 2:
							connect_walls(wall_instances.back(), wall_instances[wall_instances.size()-2])
						return EditorPlugin.AFTER_GUI_INPUT_STOP
		EDITOR_STATE.DELETE:
			if event is InputEventMouse:
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						if !raycast_result:
							return EditorPlugin.AFTER_GUI_INPUT_PASS
						
						var coll_parent = raycast_result.collider.get_parent()
						if coll_parent is Wall:
							delete_wall_connection(coll_parent)
							create_floors()
							coll_parent.free()
							return EditorPlugin.AFTER_GUI_INPUT_STOP
						return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		EDITOR_STATE.CONTINUE:
			if event is InputEventMouse:
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						if !raycast_result:
							return EditorPlugin.AFTER_GUI_INPUT_PASS
						
						var coll_parent = raycast_result.collider.get_parent()
						if coll_parent is Wall:
							
							return EditorPlugin.AFTER_GUI_INPUT_STOP
						return EditorPlugin.AFTER_GUI_INPUT_PASS

		EDITOR_STATE.PAINT:
			if material_to_paint == null:
				return EditorPlugin.AFTER_GUI_INPUT_PASS
			if event is InputEventMouse:
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						if !raycast_result:
							return EditorPlugin.AFTER_GUI_INPUT_PASS
						
						var coll_parent = raycast_result.collider.get_parent()
						if coll_parent is Wall:
							var data = get_wall_interc_data(coll_parent, raycast_result.position)
							coll_parent.set_material(data.len_along_wall, material_to_paint, data.is_side_out)

							return EditorPlugin.AFTER_GUI_INPUT_STOP
						return EditorPlugin.AFTER_GUI_INPUT_PASS

		EDITOR_STATE.DECORATION:
			if curr_decoration == null:
				return EditorPlugin.AFTER_GUI_INPUT_PASS
			if event is InputEventMouse:
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						if !raycast_result:
							return EditorPlugin.AFTER_GUI_INPUT_PASS
						
						var coll_parent = raycast_result.collider.get_parent()
						if coll_parent is Wall:
							var data = get_wall_interc_data(coll_parent, raycast_result.position)
							coll_parent.add_decoration(data.len_along_wall, curr_decoration, data.is_side_out)

							return EditorPlugin.AFTER_GUI_INPUT_STOP
						return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		EDITOR_STATE.ADD_OPENING:
			if curr_open_scene == null:
				return EditorPlugin.AFTER_GUI_INPUT_PASS
			if event is InputEventMouse:
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						if !raycast_result:
							return EditorPlugin.AFTER_GUI_INPUT_PASS
						
						var point = raycast_result.position
						var selected_object = raycast_result.collider
						
						if selected_object.get_parent() is Wall:
							var wall_instance =  selected_object.get_parent()
							var idx = wall_instances.find(selected_object.get_parent())
							#substitute_wall(idx)

							var data = get_wall_interc_data(wall_instance, raycast_result.position)

							#get CSGMESH
							var csgmesh = wall_instance.csgmesh
							if wall_instance.csgmesh == null:
								csgmesh = CSGMesh3D.new()
								csgmesh.mesh = wall_instance.mesh
								get_node("generated").add_child(csgmesh)
								csgmesh.set_owner(self)
								csgmesh.transform = wall_instance.transform
								wall_instance.csgmesh = csgmesh

							#add instance
							var new_instance = curr_open_scene.instantiate()
							csgmesh.add_child(new_instance)
							#new_instance.transform.basis = data.transform.basis
							new_instance.global_position = data.bool_origin
							
							new_instance.set_owner(self)
							
							#get boolean
							var _boolean = new_instance.get_node("boolean")
							var csg_boolean = _boolean.duplicate()
							# #var csgbox = CSGBox3D.new()
							csgmesh.add_child(csg_boolean)
							# csg_boolean.operation = CSGShape3D.OPERATION_SUBTRACTION
							csg_boolean.global_position = _boolean.global_position
							csg_boolean.set_owner(self)
							csg_boolean.show()

							#hide wall
							wall_instance.hide()
							return EditorPlugin.AFTER_GUI_INPUT_STOP
						return EditorPlugin.AFTER_GUI_INPUT_PASS
			
		_:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_PASS
			
func update_gizmo(point):
	if !handle:
		var handle_instance = preload("res://handle.tscn").instantiate()
		add_child(handle_instance)
		handle_instance.set_owner(self)
		handle = handle_instance
		
	handle.global_position = point
	
func process_new_point(point):
	if points.size() == 0:
		points.append(point)
		create_marker(point)
		return
	if points.size() >= 2:
		var wall_instance = wall_instances.back()
		var length = points[points.size()-2].distance_to(points.back())
		var angle = PI - (point - points.back()).signed_angle_to(points.back()-points[points.size()-2], Vector3.UP)
		var new_width = width/tan(angle/2)
		if abs(angle) < 0.001:
			new_width = 0
		
		create_wall1(points.back(), point)
		wall_instance.set_c2(new_width - length)
		wall_instances.back().set_c1( -new_width)
		points.append(point)
		return
	
	create_wall1(points.back(), point)
	#create_marker(point)
	points.append(point)

func create_marker(point):
	var handle_instance = preload("res://handle.tscn").instantiate()
	get_node("generated").add_child(handle_instance)
	handle_instance.set_owner(self)
	handle_instance.global_position = point
		
func create_wall1(pointA, pointB):
	var wall_instance = Wall.new()
	get_node("generated").add_child(wall_instance)
	wall_instance.set_owner(self)
	
	wall_instance.transform = Transform3D().looking_at(pointB - pointA)
	
	wall_instance.set_len(-pointA.distance_to(pointB))
	wall_instance.set_width(width)
	
	wall_instance.global_position = pointA
	wall_instances.append(wall_instance)

func create_floor(points):
	var vertices = PackedVector3Array()
	for point in points:
		vertices.append(Vector3(point))
	var mesh = CeilingCreator.create_from_vertices(vertices)
	var meshinstance = MeshInstance3D.new()
	meshinstance.mesh = mesh
	get_node("generated").add_child(meshinstance)
	meshinstance.set_owner(self)
	meshinstance.add_to_group("floors")

func create_floors():
	var cycles = get_rooms()
	get_tree().call_group("floors", "free")
	for cycle in cycles:
		var polygon: Array[Vector2] = []
		for pt in cycle:
			polygon.append(Vector2(pt.x, pt.z))
		
		if GEOMETRY_UTILS.isClockwise(polygon):
			cycle.reverse()
		create_floor(cycle)
	
	print("Number of Rooms: %d" % get_tree().get_nodes_in_group("floors").size())
	
func get_rooms():
	var graph = {}
	var all_points = []
	
	for elem in get_node("generated").get_children():
		if not elem is Wall:
			continue
		if graph.has(elem):
			continue
		graph[elem] = []
		for neigh in elem.wall_connected:
			graph[elem].append(neigh.wall)
			all_points.append(neigh.interc_point)
	var cycles = GRAPH_UTILS.find_cycles(graph)
	#print("PTS")
	#print(graph)
	#print("C")
	#print(cycles)

	var point_sets = []
	for cycle in cycles:
		var point_set = []
		for idx in cycle.size():
			var wall1 = cycle[idx]
			var wall2 = cycle[(idx+1) % cycle.size()]
			for conn in wall1.wall_connected:
				if conn.wall == wall2:
					
					point_set.append(conn.interc_point)
					break
					
		point_sets.append(point_set)
	
	var filtered_point_sets = []
	for point_set in point_sets:
		var polygon = []
		for pt in point_set:
			polygon.append(Vector2(pt.x, pt.z))
		var skip = false
		for point in all_points:
			if GEOMETRY_UTILS.is_point_in_polygon(Vector2(point.x, point.z), polygon):
				print(Vector2(point.x, point.z))
				print("inside")
				print(polygon)
				skip = true
				break
		if skip:
			continue
				
		filtered_point_sets.append(point_set)

	var connected_pts = {}
	for point_set in filtered_point_sets:
		for idx in point_set.size():
			var p1 = point_set[idx]
			var p2 = point_set[(idx+1)%point_set.size()]
			if !connected_pts.has(p1):
				connected_pts[p1] = []
			connected_pts[p1].append(p2)
			if !connected_pts.has(p2):
				connected_pts[p2] = []
			connected_pts[p2].append(p1)

	print("conn")
	print(connected_pts)
	var filtered_point_sets1 = []
	for point_set in filtered_point_sets:
		var skip = false
		# for idx1 in point_set.size():
		# 	for idx2 in point_set.size():
		# 		if idx1 == idx2:
		# 			continue
		# 		if idx2 == (idx1+1)%point_set.size():
		# 			continue
		# 		if idx1 == (idx2+1)%point_set.size():
		# 			continue
		# 		var p1 = point_set[idx1]
		# 		var p2 = point_set[idx2]
		# 		#check connected
		# 		var filtered = connected_pts[p1].filter(func (x): x.is_equal_approx(p1))
		# 		if filtered.size() > 0:
		# 			skip = true
		for point_set2 in filtered_point_sets:
			var poly1 = []
			for point in point_set:
				poly1.append(Vector2(point.x, point.z))
			var poly2 = []
			for point in point_set2:
				poly2.append(Vector2(point.x, point.z))
			
			if GEOMETRY_UTILS.is_polygon_inside(poly1, poly2):
				skip = true
				break
		if skip:
			continue
		
		filtered_point_sets1.append(point_set)
				
	print("filtered")
	print(filtered_point_sets)
	print(point_sets.size())
	print(filtered_point_sets.size())
	print(filtered_point_sets1.size())

	return filtered_point_sets

func get_all_walls():
	var walls = []
	for elem in get_node("generated").get_children():
		if not elem is Wall:
			continue
		walls.append(elem)
	return walls

func delete_wall_connection(wall_to_del):
	for wall: Wall in get_all_walls():
		var idx = -1
		for i in wall.wall_connected.size():
			var conn = wall.wall_connected[i]
			if conn.wall == wall_to_del:
				idx = i
				break
		if idx == -1:
			continue
		wall.wall_connected.remove_at(idx)


	
	
	

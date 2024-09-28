@tool
extends Node3D
class_name RoomEditor


enum EDITOR_STATE {DRAW, DELETE, ADD_OPENING}

@onready var points: Array[Vector3] = []
@onready var wall_instances: Array[Wall] = []
@onready var state: EDITOR_STATE = EDITOR_STATE.DRAW
@onready var handle: PositionHandle = null

@export var reset = false

@export var height = 2.4
@export var width = 0.2

@export var opening_height = 2
@export var opening_width = 1.2
@export var opening_scene: PackedScene

var rooms: Array[Room]
var first_wall_coll: Wall = null

func _ready() -> void:
	pass # Replace with function body.
	
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
	
func snap_point(point):
	if points.size() == 0:
		return point
	var snapped_point = Vector3(point)
	var rel_point = point - points.back()
	if abs(rel_point.x) < abs(rel_point.z):
		snapped_point.x = points.back().x
	else:
		snapped_point.z = points.back().z
	return snapped_point

func process_event(event, raycast_result):
	match  state:
		EDITOR_STATE.DRAW:
			if event is InputEventKey:
				if event.pressed and event.keycode == KEY_C:
					create_floor(points)
					process_new_point(points[0])
					#var room = Room.new(points.slice(0, points.size()-2), wall_instances)
					
					#wall connections
					wall_instances.back().add_wall_connection(wall_instances[wall_instances.size()-2])
					wall_instances[wall_instances.size()-2].add_wall_connection(wall_instances.back())
					wall_instances.back().add_wall_connection(wall_instances[0])
					wall_instances[0].add_wall_connection(wall_instances.back())
					
					
					points.clear()
					wall_instances.clear()
					#rooms.append(room)
					get_rooms()
			if event is InputEventMouse:
				if !raycast_result:
					return EditorPlugin.AFTER_GUI_INPUT_PASS
				var point = raycast_result.position
				var snapped_point = snap_point(point)
				snapped_point = snapped_point.snapped(Vector3.ONE * 0.5)
				
				if event is InputEventMouseMotion:
					update_gizmo(snapped_point)
					return EditorPlugin.AFTER_GUI_INPUT_PASS
				elif event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						if raycast_result.collider.get_parent() is Wall:
							var wall: Wall = raycast_result.collider.get_parent() 

							var tr = wall.transform
							var rayc_in_tr = tr.inverse() * raycast_result.position
							snapped_point.y = tr.origin.y
							var point_in_tr = tr.inverse() * snapped_point
							point_in_tr.x = rayc_in_tr.x
							
							snapped_point = tr * point_in_tr
							update_gizmo(snapped_point)
							var len = point_in_tr.z
							var out = rayc_in_tr.x < wall.width/2
							
							wall.add_split_len(len, out)
							if points.size() > 0:
								process_new_point(handle.global_position)
								#var room = get_new_room(points[0], snapped_point, first_wall_coll, wall, points, wall_instances)
								
								wall_instances.back().add_wall_connection(wall)
								wall.add_wall_connection(wall_instances.back())
								wall_instances.back().add_wall_connection(wall_instances[wall_instances.size()-2])
								wall_instances[wall_instances.size()-2].add_wall_connection(wall_instances.back())
								
								points.clear()
								wall_instances.clear()
								var cycles = get_rooms()
								get_tree().call_group("floors", "queue_free")
								for cycle in cycles:
									var polygon: Array[Vector2] = []
									for pt in cycle:
										polygon.append(Vector2(pt.x, pt.z))
									
									if GEOMETRY_UTILS.isClockwise(polygon):
										cycle.reverse()
									create_floor(cycle)
								#rooms.append(room)
								return EditorPlugin.AFTER_GUI_INPUT_STOP
							else:
								
								first_wall_coll = wall
								process_new_point(handle.global_position)
								wall_instances.append(wall)
								return EditorPlugin.AFTER_GUI_INPUT_STOP
								
						process_new_point(handle.global_position)
						if wall_instances.size() >= 2:
							wall_instances.back().add_wall_connection(wall_instances[wall_instances.size()-2])
							wall_instances[wall_instances.size()-2].add_wall_connection(wall_instances.back())
						return EditorPlugin.AFTER_GUI_INPUT_STOP
		EDITOR_STATE.DELETE:
			if event is InputEventMouse:
				if !raycast_result:
					return EditorPlugin.AFTER_GUI_INPUT_PASS
				
				var point = raycast_result.position
				var selected_object = raycast_result.collider
				
				if selected_object is WallInstance:
					wall_instances.erase(selected_object)
					return EditorPlugin.AFTER_GUI_INPUT_STOP
				return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		EDITOR_STATE.ADD_OPENING:
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
							var csgmesh = wall_instance.csgmesh
							if wall_instance.csgmesh == null:
								csgmesh = CSGMesh3D.new()
								csgmesh.mesh = wall_instance.mesh
								get_node("generated").add_child(csgmesh)
								csgmesh.transform = wall_instance.transform
								wall_instance.csgmesh = csgmesh
								
							var csgbox = CSGBox3D.new()
							csgmesh.add_child(csgbox)
							csgbox.operation = CSGShape3D.OPERATION_SUBTRACTION
							csgbox.global_position = raycast_result.position
							csgmesh.set_owner(self)
							csgbox.set_owner(self)
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
				
	print("filtered")
	print(filtered_point_sets)
	print(point_sets.size())
	print(filtered_point_sets.size())

	return filtered_point_sets
		
	
	
	

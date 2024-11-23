@tool
extends Node3D
class_name RoomEditor


enum EDITOR_STATE {DRAW, DELETE, CONTINUE, SPLIT, ADD_OPENING, PAINT, DECORATION, PLACE}
enum PLACE_MODE {FURNITURE, WALL, CEILING_LAMP, SNAP}

const GROUP_WALLS = "walls_%d"
const GROUP_FLOOR = "floors_%d"
const GROUP_CEILING = "ceilings_%d"
const GROUP_ASSETS = "assets_%d"

@onready var points: Array[Vector3] = []
@onready var wall_instances: Array[Wall] = []
@onready var state: EDITOR_STATE = EDITOR_STATE.DRAW
@onready var handle: PositionHandle = null

@export var reset = false

@export var height = 2.5
@export var width = 0.2

var floor_width = 0.3

@export var snap_amount = 0.5
@export var current_floor: int = 0 :
	set(value):
		if not floors.has(value):
			floors.append(value)
		current_floor = value
		get_node("collision_helper").global_position.y = value * height #- floor_width/2
		
		hide_upper_floors(value)
		show_lower_floors(value)
		disable_collision_other_floors(value)
		enable_collision_floor(value)

@export var show_ceiling: bool = true:
	set(value):
		show_ceiling = value
		show_hide_ceiling(current_floor, value)

@export var curr_decoration: ControllableSurf
@export var curr_open_scene: PackedScene
@export var placement_mode: PLACE_MODE = PLACE_MODE.FURNITURE :
	set(value):
		if placement_mode == PLACE_MODE.SNAP:
			current_parent = null
		placement_mode = value

var current_asset_scene: PackedScene
var material_to_paint: StandardMaterial3D
var current_asset = null

var floors = [0]

func _on_asset_changed(path):
	if path.contains(".tres"):
		material_to_paint = load(path)
		return
	current_asset_scene = load(path)
	if current_asset != null:
		current_asset.free()
		current_asset = null

func set_state(new_state: EDITOR_STATE):
	if state == EDITOR_STATE.PLACE:
		if current_asset != null:
			current_asset.free()
			current_asset = null
	# elif state == EDITOR_STATE.DRAW:
	# 	get_node("collision_helper").get_child(0).disabled = false
	# 	get_node("collision_helper").position = get_node("collision_helper").position
	# elif state == EDITOR_STATE.PAINT or state == EDITOR_STATE.PLACE:
	# 	get_node("collision_helper").get_child(0).disabled = true
	# 	get_node("collision_helper").position = get_node("collision_helper").position
	state = new_state

func _process(delta: float) -> void:
	if reset:
		_on_reset()
		reset = false
		
func _on_reset():
	
	handle = null
	if has_node("Handle"):
		$Handle.queue_free()
	points = []
	wall_instances = []
	floors = [0]
	current_floor = 0
	show_ceiling = true
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


class CeilIntercData:
	var is_side_bottom: bool
	var pos: Vector3
	var normal: Vector3


func get_ceil_interc_data(ceiling, raycast_res):
	var data = CeilIntercData.new()
	data.pos = raycast_res.position
	data.normal = raycast_res.normal
	data.is_side_bottom = false
	if raycast_res.normal.dot(Vector3.UP) < 0:
		data.is_side_bottom = true
	return data

class WallIntercData:
	var len_along_wall: float
	var is_side_out: bool
	var point_at_bottom: Vector3
	var transform: Transform3D
	var bool_origin: Vector3


func get_wall_interc_data(wall, raycast_pos, snap_to_grid = false):
	var data = WallIntercData.new()

	var tr = wall.transform
	print("wall_position: %f" % tr.origin.y)
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
	
var current_transform = Transform3D()
var step_pos = Vector3()
var current_parent = null

func process_draw(event, raycast_result):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_C:
			process_new_point(points[0])
			
			#wall connections
			connect_walls(wall_instances.back(), wall_instances[wall_instances.size()-2])
			connect_walls(wall_instances.back(), wall_instances[0])

			points.clear()
			wall_instances.clear()
			#rooms.append(room)
			create_floors()
	if event is InputEventMouse:
		if !raycast_result:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		var point = raycast_result.position
		var snapped_point = snap_point(point, true, true)
		if Input.is_key_pressed(KEY_CTRL):
			snapped_point = snap_point(point, false, true)
		var coll_parent = raycast_result.collider.get_parent()
		if coll_parent is Ceiling or raycast_result.collider.name == "collision_helper":
			snapped_point.y =  current_floor * height
		
		if event is InputEventMouseMotion:
			update_gizmo(snapped_point)
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if coll_parent is Wall:
				var wall: Wall = coll_parent

				var data: WallIntercData = get_wall_interc_data(coll_parent, raycast_result.position, true)
				update_gizmo(data.point_at_bottom)
				
				wall.add_split_len(data.len_along_wall, data.is_side_out)

				if points.size() > 0:#closing internal room
					process_new_point(handle.global_position)
					
					#connect walls
					connect_walls(wall_instances.back(), wall_instances[wall_instances.size()-2])
					connect_walls(wall_instances.back(), wall)
					
					points.clear()
					wall_instances.clear()

					create_floors()
					return EditorPlugin.AFTER_GUI_INPUT_STOP
				else:#starting internal room
					process_new_point(handle.global_position)
					wall_instances.append(wall)
					return EditorPlugin.AFTER_GUI_INPUT_STOP
					
			process_new_point(handle.global_position)
			if wall_instances.size() >= 2:
				connect_walls(wall_instances.back(), wall_instances[wall_instances.size()-2])
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func process_delete(event, raycast_result):
	if not event is InputEventMouse:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if !raycast_result:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		var coll_parent = raycast_result.collider.get_parent()
		if coll_parent is Wall:
			delete_wall_connection(coll_parent)
			create_floors()
			coll_parent.free()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func process_continue(event, raycast_result):
	if not event is InputEventMouse:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if !raycast_result:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		var coll_parent = raycast_result.collider.get_parent()
		if coll_parent is Wall:
			var point = get_open_end(coll_parent)
			if point == null:
				return EditorPlugin.AFTER_GUI_INPUT_PASS
			update_gizmo(point)
			wall_instances.append(coll_parent)
			process_new_point(point)
			state = EDITOR_STATE.DRAW
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func process_split(event, raycast_result):
	if not event is InputEventMouse:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if !raycast_result:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var point = raycast_result.position
	var snapped_point = snap_point(point, true, true)
	if Input.is_key_pressed(KEY_CTRL):
		snapped_point = snap_point(point, false, true)

	var coll_parent = raycast_result.collider.get_parent()
	if coll_parent is Ceiling or raycast_result.collider.name == "collision_helper":
		snapped_point.y =  current_floor * height
	
	if event is InputEventMouseMotion:
		update_gizmo(snapped_point)
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if coll_parent is Wall:
			var wall: Wall = coll_parent

			var data: WallIntercData = get_wall_interc_data(coll_parent, raycast_result.position, true)
			update_gizmo(data.point_at_bottom)
			
			wall.add_split_len(data.len_along_wall, data.is_side_out)
			
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func process_paint(event, raycast_result):
	if material_to_paint == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouse and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if !raycast_result:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		var coll_parent = raycast_result.collider.get_parent()
		if coll_parent is Wall:
			var data = get_wall_interc_data(coll_parent, raycast_result.position)
			coll_parent.set_material(data.len_along_wall, material_to_paint, data.is_side_out)

			return EditorPlugin.AFTER_GUI_INPUT_STOP
		if coll_parent is Ceiling:
			coll_parent.set_material(material_to_paint)

			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func process_dec(event, raycast_result):
	if curr_decoration == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouse and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if !raycast_result:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		var coll_parent = raycast_result.collider.get_parent()
		if coll_parent is Wall:
			var data = get_wall_interc_data(coll_parent, raycast_result.position)
			coll_parent.add_decoration(data.len_along_wall, curr_decoration, data.is_side_out)

			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func process_opening(event, raycast_result):
	if curr_open_scene == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouse and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if !raycast_result:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		var point = raycast_result.position
		var selected_object = raycast_result.collider
		var coll_parent = selected_object.get_parent()
		
		if coll_parent is Wall:
			var wall_instance = coll_parent

			var data = get_wall_interc_data(wall_instance, raycast_result.position)

			wall_instance.add_opening(curr_open_scene, data.len_along_wall)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func process_place(event, raycast_result):
	if current_asset_scene == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if current_asset == null:
		current_asset = current_asset_scene.instantiate()
		add_new_element(current_asset, GROUP_ASSETS % current_floor, current_parent)
		current_asset.transform = current_transform
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_R and current_asset != null:
			current_asset.rotate(Vector3.UP, deg_to_rad(45))
			
			return EditorPlugin.AFTER_GUI_INPUT_STOP  
		if event.pressed and event.keycode == KEY_KP_ADD and placement_mode == PLACE_MODE.SNAP:
			var _step_pos = current_asset.transform.origin - current_transform.origin
			if _step_pos.length_squared() > 0:
				step_pos = _step_pos

			current_transform.origin += step_pos
			current_asset = null
			return EditorPlugin.AFTER_GUI_INPUT_PASS  

	if event is InputEventMouse:
		if event is InputEventMouseMotion:
			if raycast_result == null:
				return EditorPlugin.AFTER_GUI_INPUT_PASS
			return move_object_to_place(raycast_result)
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if !raycast_result:
				return EditorPlugin.AFTER_GUI_INPUT_PASS
			var coll_parent = raycast_result.collider.get_parent()
			if not (coll_parent is Wall) and current_parent != null:
				current_asset.reparent(get_node("generated"))
				current_transform = current_asset.global_transform
				current_asset = null
				current_parent = null
				return EditorPlugin.AFTER_GUI_INPUT_STOP 
			current_transform = current_asset.transform
			current_asset = null
			
			return EditorPlugin.AFTER_GUI_INPUT_STOP 
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func move_object_to_place(raycast_result):
	var coll_parent = raycast_result.collider.get_parent()
	match placement_mode:
		PLACE_MODE.FURNITURE:
			if coll_parent is Ceiling or raycast_result.collider.name == "collision_helper":
				current_asset.global_position = raycast_result.position
				return EditorPlugin.AFTER_GUI_INPUT_PASS
		PLACE_MODE.WALL:
			if coll_parent is Wall:
				current_asset.global_position = raycast_result.position
				current_asset.global_transform = current_asset.global_transform.looking_at(raycast_result.position+ raycast_result.normal)
				return EditorPlugin.AFTER_GUI_INPUT_PASS
		PLACE_MODE.CEILING_LAMP:
			if coll_parent is Ceiling:
				current_asset.global_position = raycast_result.position
				current_asset.global_position.y += height
				return EditorPlugin.AFTER_GUI_INPUT_PASS
		PLACE_MODE.SNAP:
			current_asset.global_position = raycast_result.position.snapped(Vector3.ONE * snap_amount)
			if coll_parent is Wall:
				#TODO: parent to wall, adjust transform
				var data = get_wall_interc_data(coll_parent, raycast_result.position)
				current_asset.reparent(coll_parent)
				current_parent = coll_parent
				current_asset.transform = Transform3D()
				current_asset.global_position = raycast_result.position.snapped(Vector3.ONE * snap_amount)
				if not data.is_side_out:
					current_asset.transform.origin.x = coll_parent.width
				else: 
					current_asset.rotate(Vector3.UP, deg_to_rad(180))
					current_asset.transform.origin.x = 0
			return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func process_event(event, raycast_result):
	match  state:
		EDITOR_STATE.DRAW:
			return process_draw(event, raycast_result)

		EDITOR_STATE.DELETE:
			return process_delete(event, raycast_result)
		
		EDITOR_STATE.CONTINUE:
			return process_continue(event, raycast_result)

		EDITOR_STATE.SPLIT:
			return process_split(event, raycast_result)

		EDITOR_STATE.PAINT:
			return process_paint(event, raycast_result)

		EDITOR_STATE.DECORATION:
			return process_dec(event, raycast_result)
		
		EDITOR_STATE.ADD_OPENING:
			return process_opening(event, raycast_result)

		EDITOR_STATE.PLACE:
			return process_place(event, raycast_result)       
			
		_:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
	
			
func update_gizmo(point):
	if !handle:
		var handle_instance = preload("res://addons/BuildingEditor/scenes/gizmos/handle.tscn").instantiate()
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
		
		create_wall(points.back(), point)
		wall_instance.set_c2(new_width - length)
		wall_instances.back().set_c1( -new_width)
		points.append(point)
		return
	
	create_wall(points.back(), point)
	#create_marker(point)
	points.append(point)

func create_marker(point):
	var handle_instance = preload("res://addons/BuildingEditor/scenes/gizmos/handle.tscn").instantiate()
	get_node("generated").add_child(handle_instance)
	handle_instance.set_owner(self)
	handle_instance.global_position = point
		
func create_wall(pointA, pointB):
	var wall_instance = Wall.new(height)
	add_new_element(wall_instance, GROUP_WALLS % current_floor)
	
	wall_instance.transform = Transform3D().looking_at(pointB - pointA)
	
	wall_instance.set_len(-pointA.distance_to(pointB))
	wall_instance.set_width(width)
	
	wall_instance.global_position = pointA
	wall_instances.append(wall_instance)

func create_floor(points):
	var vertices = PackedVector3Array()
	for point in points:
		vertices.append(Vector3(point))

	var floor = Ceiling.new(points, false)
	add_new_element(floor, GROUP_FLOOR % current_floor)
	
	return floor


func create_ceiling(points):
	var vertices = PackedVector3Array()
	for point in points:
		vertices.append(Vector3(point))

	var ceiling = Ceiling.new(points, true)
	add_new_element(ceiling, GROUP_CEILING % current_floor)
	return ceiling

func add_new_element(elem, group = null, parent = null):
	if parent != null:
		parent.add_child(elem)
	else:
		get_node("generated").add_child(elem)
	elem.set_owner(self)
	if group != null:
		elem.add_to_group(group)

func clear_floor(number):
	get_tree().call_group(GROUP_FLOOR % number, "free")
	get_tree().call_group(GROUP_CEILING % number, "free")

func disable_collision_other_floors(number):
	for floor in floors:
		if floor == number:
			continue
		for elem in get_tree().get_nodes_in_group(GROUP_WALLS % floor):
			elem.set_collision(true)
		for elem in get_tree().get_nodes_in_group(GROUP_CEILING % floor):
			elem.set_collision(true)
		for elem in get_tree().get_nodes_in_group(GROUP_FLOOR % floor):
			elem.set_collision(true)

func enable_collision_floor(number):

	for elem in get_tree().get_nodes_in_group(GROUP_WALLS % number):
		elem.set_collision(false)
	for elem in get_tree().get_nodes_in_group(GROUP_CEILING % number):
		elem.set_collision(false)
	for elem in get_tree().get_nodes_in_group(GROUP_FLOOR % number):
		elem.set_collision(false)


func hide_upper_floors(number):
	for floor in floors:
		if floor > number:
			for elem in get_tree().get_nodes_in_group(GROUP_WALLS % floor):
				elem.hide()
			for elem in get_tree().get_nodes_in_group(GROUP_CEILING % floor):
				elem.hide()
			for elem in get_tree().get_nodes_in_group(GROUP_FLOOR % floor):
				elem.hide()


func show_lower_floors(number):
	for floor in floors:
		if floor <= number:
			for elem in get_tree().get_nodes_in_group(GROUP_WALLS % floor):
				elem.show()
			for elem in get_tree().get_nodes_in_group(GROUP_CEILING % floor):
				elem.show()
			for elem in get_tree().get_nodes_in_group(GROUP_FLOOR % floor):
				elem.show()
		

func show_hide_ceiling(number, show):
	for elem in get_tree().get_nodes_in_group(GROUP_CEILING % number): #+ get_tree().get_nodes_in_group(GROUP_FLOOR % number):
		if not show:
			elem.hide()
			elem.set_collision(true)
			continue
	
		elem.show()
		elem.set_collision(false)

func create_floors():
	# for room in rooms:
	# 	room.free()
	# rooms.clear()
	clear_floor(current_floor)
	var cycles = get_rooms()
	for cycle in cycles:
		var polygon: Array[Vector2] = []
		for pt in cycle:
			polygon.append(Vector2(pt.x, pt.z))
		
		if GEOMETRY_UTILS.isClockwise(polygon):
			cycle.reverse()
		
		var floor = create_floor(cycle)
		var ceiling = create_ceiling(cycle)
		ceiling.global_position.y =  height
		# add_new_element(room)
		#rooms.append(room)
	show_hide_ceiling(current_floor, show_ceiling)
	print("Number of Rooms: %d" % get_tree().get_nodes_in_group(GROUP_CEILING % current_floor).size())
	
func get_rooms():
	var graph = {}
	var all_points = []
	
	for elem in get_all_walls():
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
	return get_tree().get_nodes_in_group(GROUP_WALLS % current_floor)

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

func get_open_end(wall):
	var st_connected = false
	var end_connected = false
	for i in wall.wall_connected.size():
		var conn = wall.wall_connected[i]
		if conn.interc_point.is_equal_approx(wall.get_start_pt()):
			st_connected = true
			continue
		if conn.interc_point.is_equal_approx(wall.get_end_pt()):
			end_connected = true
			continue

	if st_connected and end_connected:
		return null
	if st_connected:
		return wall.get_end_pt()
	return wall.get_start_pt()
		


	
	
	

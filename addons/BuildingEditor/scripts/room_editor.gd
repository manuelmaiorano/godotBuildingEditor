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
					var vertices = PackedVector3Array()
					for point in points:
						vertices.append(Vector3(point))
					var mesh = CeilingCreator.create_from_vertices(vertices)
					var meshinstance = MeshInstance3D.new()
					meshinstance.mesh = mesh
					get_node("generated").add_child(meshinstance)
					meshinstance.set_owner(self)
					process_new_point(points[0])
					var room = Room.new(points.slice(0, points.size()-2), wall_instances)
					points.clear()
					wall_instances.clear()
					rooms.append(room)
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
							var wall = raycast_result.collider.get_parent() 
							#TODO: add split point check if inside or out
							
							if points.size() > 0:
								var room = Room.new([], [])
								points.clear()
								rooms.append(room)
								
						process_new_point(handle.global_position)
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
	wall_instance.set_width(0.2)
	
	wall_instance.global_position = pointA
	wall_instances.append(wall_instance)
	
func get_new_room(pointA, pointB, wallA, wallB):
	var roomA
	var roomB
	for room: Room in rooms:
		if room.walls.has(wallA):
			roomA = room
		if room.walls.has(wallB):
			roomB = room
	
	#
#func create_wall(pointA, pointB):
	#var wall_instance = preload("res://wall.tscn").instantiate()
	#get_node("generated").add_child(wall_instance)
	#wall_instance.set_owner(self)
	#wall_instance.transform = Transform3D().looking_at(pointB - pointA)
	#
	#wall_instance.get_node("height/Handle").position.y = height
	#wall_instance.get_node("length/Handle").position.z = -pointA.distance_to(pointB)
	#wall_instance.get_node("width/Handle").position.x = 0.2
	#
	#
	#wall_instance.global_position = pointA
	#wall_instances.append(wall_instance)
	#
#func substitute_wall(idx):
	#var wall_instance = wall_instances[idx]
	#var op_instance = preload("res://door_opening.tscn").instantiate()
	#get_node("generated").add_child(op_instance)
	#op_instance.set_owner(self)
	#op_instance.transform = wall_instance.transform
	#
	#op_instance.get_node("height/Handle").position.y = height
	#op_instance.get_node("length/Handle").position.z = wall_instance.get_node("length/Handle").position.z
	#op_instance.get_node("width/Handle").position.x = 0.2
	#op_instance.get_node("c2/Handle").position.z = wall_instance.get_node("c2/Handle").position.z
	#op_instance.get_node("c1/Handle").position.z = wall_instance.get_node("c1/Handle").position.z
	#wall_instances[idx] = op_instance
	#wall_instance.queue_free()
	
	
	

@tool
extends EditorPlugin

const RAY_LENGTH = 10.0
var node_to_edit = null
var import_plugin

var points = []
var menu

const GizmoPlugin = preload("res://addons/BuildingEditor/scripts/gizmos/handles.gd")
var gizmo_plugin = GizmoPlugin.new()

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	#add_custom_type("Wall", "MeshInstance3D", preload("res://addons/BuildingEditor/create_wall.gd"), preload("res://icon.svg"))
	import_plugin = preload("res://addons/BuildingEditor/scripts/import_scripts/import_vg.gd").new()
	add_import_plugin(import_plugin)
	add_node_3d_gizmo_plugin(gizmo_plugin)
	if menu:
		return

	menu = preload("res://addons/BuildingEditor/scenes/Menu.tscn").instantiate()
	
	menu.get_node("DrawBtn").toggled.connect( \
		func(pressed): _on_btn_press(RoomEditor.EDITOR_STATE.DRAW, pressed))
	
	menu.get_node("DelBtn").toggled.connect( \
		func(pressed): _on_btn_press(RoomEditor.EDITOR_STATE.DELETE, pressed))
	
	menu.get_node("ContinueBtn").toggled.connect( \
		func(pressed): _on_btn_press(RoomEditor.EDITOR_STATE.CONTINUE, pressed))
	
	menu.get_node("OpeningBtn").toggled.connect( \
		func(pressed): _on_btn_press(RoomEditor.EDITOR_STATE.ADD_OPENING, pressed))
		
	menu.get_node("PaintBtn").toggled.connect( \
		func(pressed): _on_btn_press(RoomEditor.EDITOR_STATE.PAINT, pressed))
		
	menu.get_node("DecorationBtn").toggled.connect( \
		func(pressed): _on_btn_press(RoomEditor.EDITOR_STATE.DECORATION, pressed))

	add_control_to_container( \
		EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, menu)
	menu.hide()



func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	#remove_custom_type("Wall")
	remove_import_plugin(import_plugin)
	import_plugin = null
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	if !menu:
		return

	remove_control_from_container( \
	EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, menu)

	menu.free()
	menu = null
	
func _handles(object: Object) -> bool:
	return object is RoomEditor
	
func _edit(object: Object) -> void:
	if !object:
		menu.hide()
		return
	
	node_to_edit = object
	menu.show()
	
func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent):
	var result = null
	if event is InputEventMouse:
		
		result = _perform_raycast(event.position, viewport_camera)
	return node_to_edit.process_event(event, result)

func _perform_raycast(screen_pos: Vector2, camera):
	# Get the current editor viewport
	var viewport = EditorInterface.get_editor_viewport_3d()


	if camera == null:
		return null

	# Convert the mouse screen position to a ray
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_direction = camera.project_ray_normal(screen_pos)

	# Define the maximum ray distance
	var ray_length = 1000.0

	# Perform raycast
	var space_state = viewport.find_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	var result = space_state.intersect_ray(query)

	if !result:
		return null

	return result
	
func _on_btn_press(state, pressed):
	if not node_to_edit:
		return
	if pressed:
		node_to_edit.set_state(state)

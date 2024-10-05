@tool
extends MeshInstance3D
class_name Roof

@export var contr_mesh: ControllableSurf

var surfaces : Array[ControllableSurf] = []

var height = 1
var front = 1
var back = -1
var currentz = 1

func _ready() -> void:
	contr_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/roof.res").duplicate(true).initialize()
	mesh = contr_mesh.mesh
	contr_mesh.initialize()
	# get_node("front").position_changed.connect(func (d): move_mesh("f", d))
	# get_node("height").position_changed.connect(func (d): move_mesh("h", d))
	# get_node("side").position_changed.connect(func (d): scale_mesh(d))
	# get_node("back").position_changed.connect(func (d): move_mesh("b", d))

func _init() -> void:
	pass


func scale_mesh(vec: Vector3):
	contr_mesh.scalez((vec.z+currentz)/currentz)
	currentz += vec.z
	update_mesh()

func move_mesh(vgroup, vec: Vector3):
	contr_mesh.translate_vgroup(vgroup, vec)
	update_mesh()

func update_mesh():
	surfaces.clear()
	surfaces.append(contr_mesh)
	mesh = ArrayMesh.new()
	var surface_array = []
	for surf in surfaces:
		surface_array.resize(Mesh.ARRAY_MAX)
		surface_array[Mesh.ARRAY_VERTEX] = surf.verts
		surface_array[Mesh.ARRAY_TEX_UV] =  surf.uvs
		surface_array[Mesh.ARRAY_NORMAL] = surf.normals
		surface_array[Mesh.ARRAY_INDEX] =  surf.indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	update_gizmos()

func gen_array_mesh():
	mesh = ArrayMesh.new()
	surfaces.clear()
	gen_roof()
	
	var surface_array = []
	for surf in surfaces:
		surface_array.resize(Mesh.ARRAY_MAX)
		surface_array[Mesh.ARRAY_VERTEX] = surf.verts
		surface_array[Mesh.ARRAY_TEX_UV] =  surf.uvs
		surface_array[Mesh.ARRAY_NORMAL] = surf.normals
		surface_array[Mesh.ARRAY_INDEX] =  surf.indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	#update_collision()

		
func gen_roof():
	
	var front = get_node("front").position.x
	var height = get_node("height").position.y
	var zscale = get_node("side").position.z
	var back = get_node("back").position.x

	var dict = {"h": Vector3(0, height, 0), 
				"f": Vector3(front, 0, 0), 
				"b": Vector3(back, 0, 0)
				}
	var surf = contr_mesh.gen_new_surf(dict)
	surf.scalez(zscale)
	surfaces.append(surf)

func set_height(h):
	height = h
	gen_array_mesh()
	
func set_font(f):
	front = f
	gen_array_mesh()
	
func set_back(b):
	back = b
	gen_array_mesh()
	
func update_collision():
	if get_children().size() == 0:
		create_trimesh_collision()
		return
	get_child(0).free()
	create_trimesh_collision()


func set_collision(disabled):
	get_child(0).get_child(0).disabled = disabled

	
	

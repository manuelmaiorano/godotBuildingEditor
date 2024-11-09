@tool
extends MeshInstance3D
class_name WallDecoration

@export var contr_mesh: ControllableSurf

var surfaces : Array[ControllableSurf] = []
var c1 = 0
var c2 = 0
var rotationy = 0
var transl = Vector3.ZERO


func _init(_mesh: ControllableSurf) -> void:
	contr_mesh = _mesh.duplicate(true).initialize()


	
func gen_array_mesh():
	mesh = ArrayMesh.new()
	surfaces.clear()
	gen()

	var surface_array = []
	for surf in surfaces:
		surface_array.resize(Mesh.ARRAY_MAX)
		surface_array[Mesh.ARRAY_VERTEX] = surf.verts
		surface_array[Mesh.ARRAY_TEX_UV] =  surf.uvs
		surface_array[Mesh.ARRAY_NORMAL] = surf.normals
		surface_array[Mesh.ARRAY_INDEX] =  surf.indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	if has_csgmesh():
		get_csgmesh().mesh = mesh
		mesh = null
	#update_collision()

func gen():
	var dict = {"c1": Vector3(0, 0, c1), "c2": Vector3(0, 0, c2)}
	var new_msh = contr_mesh.gen_new_surf(dict)
	new_msh.rotatey(rotationy)
	new_msh.translate(transl)

	surfaces.append(new_msh)


func set_roty(_r):
	rotationy = _r
	gen_array_mesh()


func set_translation(_t):
	transl = _t
	gen_array_mesh()
	
func set_c1(_c1):
	c1 = _c1
	gen_array_mesh()
	

func set_c2(_c2):
	c2 = _c2
	gen_array_mesh()

#################collision
func update_collision():
	if has_csgmesh():
		return

func set_collision(disabled):
	if has_csgmesh():
		get_child(0).use_collision = not disabled
		return

	get_child(0).get_child(0).disabled = disabled
	if not disabled:
		update_collision()

#########################boolean
func add_opening(_boolean: MovableBooleanShape):

	var csgmesh = null
	if not has_csgmesh():
		csgmesh = CSGMesh3D.new()
		add_child(csgmesh)
		csgmesh.set_owner(get_parent().get_parent())
		csgmesh.name = "csgmesh"
		csgmesh.mesh = mesh
		csgmesh.use_collision = true
	csgmesh = get_csgmesh()

	#get boolean
	var csg_boolean = _boolean.duplicate()
	csg_boolean.set_process(false)
	_boolean.connected.append(csg_boolean)
	csgmesh.add_child(csg_boolean)
	csg_boolean.global_position = _boolean.global_position
	csg_boolean.set_owner(self)
	csg_boolean.show()


func has_csgmesh():
	return has_node("csgmesh")



func get_csgmesh():
	return get_node("csgmesh")

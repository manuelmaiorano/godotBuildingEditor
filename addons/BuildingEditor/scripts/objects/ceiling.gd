@tool
extends MeshInstance3D
class_name Ceiling



var material
var points = []


var csgmesh = null
var isTop = false

func _init(_points, _isTop) -> void:
	points = _points
	isTop = _isTop
	material = StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	gen_array_mesh(isTop)

func gen_array_mesh(isTop):
	mesh = CeilingCreator.create_from_vertices(points, isTop)

	mesh.surface_set_material(0, material)
	update_collision()
		


func set_material(mat):
	material = mat
	gen_array_mesh(isTop)

##############################################collision
func update_collision():
	if has_csgmesh():
		return
	var st_body = get_static_body()
	if st_body == null:
		create_trimesh_collision()
		return
	st_body.free()
	create_trimesh_collision()

func set_collision(disabled):
	if has_csgmesh():
		get_csgmesh().use_collision = not disabled
		return

	var st_body = get_static_body()
	st_body.get_child(0).disabled = disabled
	if not disabled:
		update_collision()

func get_static_body():
	for child in get_children():
		if child is StaticBody3D:
			return child
	return null

#################################boolean
func has_csgmesh():
	return has_node("csgmesh")


func get_booleans():
	var booleans = []
	if has_csgmesh():
		var csgmesh = get_csgmesh()
		for elem in csgmesh.get_children():
			if elem is CSGPrimitive3D:
				booleans.append(elem)

	return booleans

func get_csgmesh():
	return get_node("csgmesh")

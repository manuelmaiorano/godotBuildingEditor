@tool
extends MeshInstance3D
class_name Ceiling



var material
var points = []
var h_offsets: Array[float] = []


var csgmesh = null
var isTop = false

func _init(_points, _isTop) -> void:
	points = _points
	isTop = _isTop
	for _i in points.size():
		h_offsets.append(0.0)
	material = StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	gen_array_mesh()

func gen_array_mesh():
	mesh = CeilingCreator.create_from_vertices(points, 
		h_offsets, isTop)

	mesh.surface_set_material(0, material)
	update_collision()
		


func set_material(mat):
	material = mat
	gen_array_mesh()

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

##########################controllable

func translate_vgroup(vgroup, vec: Vector3):
	h_offsets[int(vgroup)] += vec.y
	gen_array_mesh()

func get_vgroups():
	var vgs = []
	for idx in points.size():
		var vg = VertexGroup.new()
		vg.name = str(idx)
		vgs.append(vg)
	return vgs

func get_handle_point(vg_name):
	var point = points[int(vg_name)] + Vector3(0, h_offsets[int(vg_name)], 0)
	return point

func get_handle_name(handle_id):
	return str(handle_id)

func get_drag_segment(vg_name):
	var segment = []
	var pt = points[int(vg_name)]
	segment.append(Vector3(pt.x, 0.0, pt.z))
	segment.append(Vector3(pt.x, 4096, pt.z))
	return segment
	

@tool
extends MeshInstance3D
class_name Ceiling



var material_top = null
var material_bottom = null
var points = []


var csgmesh = null

func _init(_points) -> void:
	points = _points
	gen_array_mesh()

func gen_array_mesh():
	mesh = CeilingCreator.create_from_vertices(points)

	if material_bottom != null:
		mesh.surface_set_material(1, material_bottom)
	
	if material_top != null:
		mesh.surface_set_material(0, material_top)

	update_collision()
		

func update_collision():
	if get_children().size() == 0:
		create_trimesh_collision()
		return
	get_child(0).free()
	create_trimesh_collision()

func set_material(mat, is_side_bottom = false):
	if is_side_bottom:
		material_bottom = mat
	else:
		material_top = mat
	gen_array_mesh()

	

func set_collision(disabled):
	get_child(0).get_child(0).disabled = disabled

	
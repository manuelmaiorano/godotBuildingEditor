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
	update_collision()

		

func update_collision():
	if get_children().size() == 0:
		create_trimesh_collision()
		return
	get_child(0).free()
	create_trimesh_collision()
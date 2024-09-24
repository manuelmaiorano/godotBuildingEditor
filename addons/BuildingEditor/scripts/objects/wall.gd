@tool
extends MeshInstance3D
class_name Wall


@export var border_mesh: ControllableSurf
@export var wall_in_mesh: ControllableSurf
@export var wall_out_mesh: ControllableSurf

var surfaces : Array[ControllableSurf] = []
var split_pts_in: Array[float] = []
var split_pts_out: Array[float] = []
var width = 0.2
var height = 2.4

var csgmesh = null

func _init() -> void:
	split_pts_in = [0, 1]
	split_pts_out = [0, 1]
	border_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/border.res").initialize()
	wall_in_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/Inner.res").initialize()
	wall_out_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/outer.res").initialize()
	
func gen_array_mesh():
	mesh = ArrayMesh.new()
	surfaces.clear()
	gen_wall()
	gen_wall(true)
	gen_border()
	var surface_array = []
	for surf in surfaces:
		surface_array.resize(Mesh.ARRAY_MAX)
		surface_array[Mesh.ARRAY_VERTEX] = surf.verts
		surface_array[Mesh.ARRAY_TEX_UV] =  surf.uvs
		surface_array[Mesh.ARRAY_NORMAL] = surf.normals
		surface_array[Mesh.ARRAY_INDEX] =  surf.indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	update_collision()
		
func gen_border():
	var dict = {"w": Vector3(width, 0, 0), 
				"l": Vector3(0, 0, split_pts_out[split_pts_out.size()-1] ), 
				"h": Vector3(0, height, 0),
				"c1": Vector3(0, 0, split_pts_in[0] ),
				"c2": Vector3(0, 0, split_pts_in[split_pts_in.size()-1] ), 
				}
	var surf = border_mesh.gen_new_surf(dict)
	surfaces.append(surf)
		
func gen_wall(out = false):
	var split_pts = split_pts_in
	var msh = wall_in_mesh
	if out:
		split_pts = split_pts_out
		msh = wall_out_mesh
	for idx in range(1, split_pts.size()):
		
		var c1 = split_pts[idx-1]
		var c2 = split_pts[idx]
		var dict = {"c1": Vector3(0, 0, c1), "c2": Vector3(0, 0, c2), "w": Vector3(width, 0, 0), "h": Vector3(0, height, 0)}
				
		var surf = msh.gen_new_surf(dict)
		surfaces.append(surf)
		
func add_split_len(pt, out = false):
	var arr = split_pts_in
	if out:
		arr = split_pts_out
		
	for idx in arr.size():
		if arr[idx] < pt:
			arr.insert(idx, pt)
			break
	gen_array_mesh()

func set_len(len):
	split_pts_in[split_pts_in.size()-1] = len
	split_pts_out[split_pts_out.size()-1] = len
	gen_array_mesh()

func set_width(w):
	width = w
	gen_array_mesh()

func set_height(h):
	height = h
	gen_array_mesh()
	
func set_c1(c1):
	split_pts_in[0] = c1
	gen_array_mesh()
	

func set_c2(c2):
	split_pts_in[split_pts_in.size()-1] = c2
	gen_array_mesh()
	
func update_collision():
	if get_children().size() == 0:
		create_trimesh_collision()
		return
	get_child(0).free()
	create_trimesh_collision()
	
	
	

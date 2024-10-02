@tool
extends MeshInstance3D
class_name Wall

class WallConnection:
	var wall: Wall
	var interc_point: Vector3

@export var border_mesh: ControllableSurf
@export var wall_in_mesh: ControllableSurf
@export var wall_out_mesh: ControllableSurf

var surfaces : Array[ControllableSurf] = []
var split_pts_in: Array[float] = []
var split_pts_out: Array[float] = []
var width = 0.2
var height = 2.4

var materials_in = []
var materials_out = []

var decorations_in = []
var decorations_out = []

var csgmesh = null

var wall_connected: Array[WallConnection]

func _init() -> void:
	split_pts_in = [0, 1]
	split_pts_out = [0, 1]
	materials_in = [StandardMaterial3D.new()]
	materials_out = [StandardMaterial3D.new()]
	decorations_in = [null]
	decorations_out = [null]
	border_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/border.res").duplicate(true).initialize()
	wall_in_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/Inner.res").duplicate(true).initialize()
	wall_out_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/outer.res").duplicate(true).initialize()
	
func gen_array_mesh():
	mesh = ArrayMesh.new()
	surfaces.clear()
	gen_wall()
	gen_wall(true)
	gen_border()
	gen_dec()
	gen_dec(true)
	var surface_array = []
	for surf in surfaces:
		surface_array.resize(Mesh.ARRAY_MAX)
		surface_array[Mesh.ARRAY_VERTEX] = surf.verts
		surface_array[Mesh.ARRAY_TEX_UV] =  surf.uvs
		surface_array[Mesh.ARRAY_NORMAL] = surf.normals
		surface_array[Mesh.ARRAY_INDEX] =  surf.indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

	var all_mats = materials_in.duplicate()
	all_mats.append_array(materials_out)
	
	for idx in all_mats.size():
		var mat = all_mats[idx]
		mesh.surface_set_material(idx, mat)
	
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

func gen_dec(out = false):
	var split_pts = split_pts_in
	var decs = decorations_in
	if out:
		split_pts = split_pts_out
		decs = decorations_out
	for idx in range(1, split_pts.size()):
		var dec = decs[idx-1]
		if dec == null:
			continue
		var c1 = split_pts[idx-1]
		var c2 = split_pts[idx]
		var dict = {"c1": Vector3(0, 0, c1), "c2": Vector3(0, 0, c2)}
		if out:
			dict = {"c1": Vector3(0, 0, 0), "c2": Vector3(0, 0, c2-c1)}
		
		
		var surf = dec.gen_new_surf(dict)
		if out:
			surf.rotatey(180)
			surf.translate(Vector3(0, 0, c2))
		if not out:
			surf.translate(Vector3(width, 0, 0))
		surfaces.append(surf)
		
func add_split_len(pt, out = false):
	var arr = split_pts_in
	var mat_arr = materials_in
	var dec_arr = decorations_in
	if out:
		arr = split_pts_out
		mat_arr = materials_out
		dec_arr = decorations_out
		
	for idx in arr.size():
		if arr[idx] < pt:
			arr.insert(idx, pt)
			break
	mat_arr.append(StandardMaterial3D.new())
	dec_arr.append(null)
			
	gen_array_mesh()

func set_material(pt, mat, out = false):
	var arr = split_pts_in
	var mat_arr = materials_in
	if out:
		arr = split_pts_out
		mat_arr = materials_out
		
	var idx_to_set = -1
	for idx in arr.size():
		if arr[idx] < pt:
			idx_to_set = idx-1
			break
			
	mat_arr[idx_to_set] = mat
	gen_array_mesh()

func add_decoration(pt, dec: ControllableSurf, out = false):
	var arr = split_pts_in
	var dec_arr = decorations_in
	if out:
		arr = split_pts_out
		dec_arr = decorations_out
		
	var idx_to_set = -1
	for idx in arr.size():
		if arr[idx] < pt:
			idx_to_set = idx-1
			break

	dec_arr[idx_to_set] = dec.duplicate().initialize()
	gen_array_mesh()
	
func add_wall_connection(wall: Wall):
	var conn = WallConnection.new()
	conn.wall = wall
	
	var strt = get_start_pt()
	var end = get_end_pt()
	
	var x1 = strt.x
	var y1 = strt.z
	
	var x2 = end.x
	var y2 = end.z
	
	strt = wall.get_start_pt()
	end = wall.get_end_pt()
	
	var x3 = strt.x
	var y3 = strt.z
	
	var x4 = end.x
	var y4 = end.z
	
	var det = (x1-x2)*(y3-y4)-(y1-y2)*(x3-x4)
	var px = ( (x1*y2 -y1*x2)*(x3-x4)-(x1-x2)*(x3*y4-y3*x4) )/det
	var py = ( (x1*y2 -y1*x2)*(y3-y4)-(y1-y2)*(x3*y4-y3*x4) )/det
	
	conn.interc_point = Vector3(px, transform.origin.y, py)
	
	wall_connected.append(conn)

func get_start_pt():
	var vec = Vector3(0, 0, split_pts_out.back())
	return transform * vec

func get_end_pt():
	var vec = Vector3(0, 0, 0)
	return transform * vec

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

func set_collision(disabled):
	
	get_child(0).get_child(0).disabled = disabled
	if not disabled:
		update_collision()



	
	
	

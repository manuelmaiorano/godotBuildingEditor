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
var h_pts_in: Array[float] = []
var h_pts_out: Array[float] = []
var width = 0.2
var height = 2.5

var materials_in = []
var materials_out = []

var decorations_in = []
var decorations_out = []

var csgmesh = null

var wall_connected: Array[WallConnection]

func _init(_height) -> void:
	height = _height
	split_pts_in = [0, 1]
	split_pts_out = [0, 1]
	h_pts_in = [height, height]
	h_pts_out = [height, height]
	materials_in = [StandardMaterial3D.new()]
	materials_out = [StandardMaterial3D.new()]
	decorations_in = [[]]
	decorations_out = [[]]
	border_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/border.res").duplicate(true).initialize()
	wall_in_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/Inner.res").duplicate(true).initialize()
	wall_out_mesh = preload("res://addons/BuildingEditor/resources/controllableMeshes/outer.res").duplicate(true).initialize()
	
func gen_array_mesh():
	mesh = ArrayMesh.new()
	surfaces.clear()
	gen_wall()
	gen_wall(true)
	gen_border()
	update_dec()
	update_dec(true)
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
	
	if has_node("csgmesh"):
		get_node("csgmesh").mesh = mesh
		mesh = null
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
	var h_vals = h_pts_in
	var msh = wall_in_mesh
	if out:
		split_pts = split_pts_out
		h_vals = h_pts_out
		msh = wall_out_mesh
	for idx in range(1, split_pts.size()):
		
		var c1 = split_pts[idx-1]
		var c2 = split_pts[idx]
		var dict = {"c1": Vector3(0, 0, c1), "c2": Vector3(0, 0, c2), "w": Vector3(width, 0, 0), "h": Vector3(0, height, 0)}
				
		var surf = msh.gen_new_surf(dict)

		surf.seth_vgroup("c1", h_vals[idx-1])
		surf.seth_vgroup("c2", h_vals[idx])

		surfaces.append(surf)

func update_dec(out = false):
	var split_pts = split_pts_in
	var decs = decorations_in
	if out:
		split_pts = split_pts_out
		decs = decorations_out
	for idx in range(1, split_pts.size()):
		var decorations = decs[idx-1]
		if decorations.size() == 0:
			continue
		var c1 = split_pts[idx-1]
		var c2 = split_pts[idx]

		for dec in decorations:
			if out:
				dec.set_c1(0)
				dec.set_c2(c2-c1)
				dec.set_roty(180)
				dec.set_translation(Vector3(0, 0, c2))
			else:
				dec.set_c1(c1)
				dec.set_c2(c2)
				dec.set_translation(Vector3(width, 0, 0))

		
func add_split_len(pt, out = false):
	var arr = split_pts_in
	var mat_arr = materials_in
	var dec_arr = decorations_in
	var h_arr = h_pts_in
	if out:
		arr = split_pts_out
		mat_arr = materials_out
		dec_arr = decorations_out
		h_arr = h_pts_out
		
	for idx in arr.size():
		if arr[idx] < pt:
			arr.insert(idx, pt)
			h_arr.insert(idx, height)
			break
	mat_arr.append(StandardMaterial3D.new())
	dec_arr.append([])
			
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

	var wall_dec = WallDecoration.new(dec)
	add_child(wall_dec)
	dec_arr[idx_to_set].append(wall_dec)
	for boolean in get_booleans():
		wall_dec.add_opening(boolean)

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

func add_opening(opening_scene, len_along_wall):

	#free collision
	var st_body = get_static_body()
	if not has_csgmesh() and st_body != null:
		st_body.free()

	var csgmesh = null
	if not has_csgmesh():
		csgmesh = CSGMesh3D.new()
		add_child(csgmesh)
		csgmesh.set_owner(get_parent().get_parent())
		csgmesh.name = "csgmesh"
		csgmesh.mesh = mesh
		csgmesh.use_collision = true
	csgmesh = get_csgmesh()

	#insatnciate
	var new_instance = opening_scene.instantiate()
	csgmesh.add_child(new_instance)
	new_instance.position = Vector3(width/2, 0, len_along_wall)
	new_instance.set_owner(self)

	#get boolean
	var _boolean = new_instance.get_node("boolean")
	var csg_boolean = _boolean.duplicate()
	csgmesh.add_child(csg_boolean)
	csg_boolean.global_position = _boolean.global_position
	csg_boolean.set_owner(self)
	csg_boolean.show()

	for decorations in decorations_in:
		for dec in decorations:
			dec.add_opening(_boolean)
	
	for decorations in decorations_out:
		for dec in decorations:
			dec.add_opening(_boolean)

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

####################collision
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

#####################boolean
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

func get_static_body():
	for child in get_children():
		if child is StaticBody3D:
			return child
	return null

##########################controllable

func translate_vgroup(vgroup, vec: Vector3):
	var allpts = split_pts_in + split_pts_out
	var idx = int(vgroup)
	if idx < split_pts_in.size():
		h_pts_in[idx] += vec.y
	else :
		h_pts_out[idx-split_pts_in.size()] += vec.y

	gen_array_mesh()


func get_vgroups():
	var allpts = split_pts_in + split_pts_out
	var vgs = []
	for idx in allpts.size():
		var vg = VertexGroup.new()
		vg.name = str(idx)
		vgs.append(vg)
	return vgs

func get_handle_point(vg_name):
	var allpts = split_pts_in + split_pts_out
	var idx = int(vg_name)
	var pt 
	if idx < split_pts_in.size():
		pt = Vector3(width, h_pts_in[idx], split_pts_in[idx])
	else:
		idx -= split_pts_in.size()
		pt = Vector3(0, h_pts_out[idx], split_pts_out[idx])
	return pt


func get_handle_name(handle_id):
	return str(handle_id)
	

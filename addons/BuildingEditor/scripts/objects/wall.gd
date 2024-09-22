extends MeshInstance3D
class_name Wall


@export var border_mesh: ControllableSurf
@export var wall_in_mesh: ControllableSurf
@export var wall_out_mesh: ControllableSurf

@export var vgroups: VertexGroups

var surfaces : Array[ArrayMesh]
var split_pts_in: Array[float]
var split_pts_out: Array[float]

func _ready() -> void:
	split_pts_in = [0, 1]
	split_pts_out = [0, 1]
		
func gen_array_mesh():
	mesh = ArrayMesh.new()
	gen_wall()
	gen_wall(true)
	var surface_array = []
	for surf in surfaces:
		surface_array.resize(Mesh.ARRAY_MAX)
		surface_array[Mesh.ARRAY_VERTEX] = surf.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		surface_array[Mesh.ARRAY_TEX_UV] =  surf.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		surface_array[Mesh.ARRAY_NORMAL] = surf.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
		surface_array[Mesh.ARRAY_INDEX] =  surf.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
		
func gen_wall(out = false):
	var split_pts = split_pts_in
	if out:
		split_pts = split_pts_out
	for idx in range(1, split_pts.size()):
		var c1 = split_pts[idx-1]
		var c2 = split_pts[idx]
		var surf = wall_in_mesh.get_new_surf({"c1": Vector3(0, 0, c1), "c2": Vector3(0, 0, c2), "h": Vector3(0, 0, 2.4)})
		surfaces.append(surf)
		
func add_split_len(pt, out = false):
	var arr = split_pts_in
	if out:
		arr = split_pts_out
		
	for idx in arr.size():
		if arr[idx] < len:
			arr.insert(idx, pt)
			break
	gen_array_mesh()
	

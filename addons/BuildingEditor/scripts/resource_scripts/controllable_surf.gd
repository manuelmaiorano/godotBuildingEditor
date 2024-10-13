@tool
extends  Resource
class_name  ControllableSurf

@export var mesh: ArrayMesh
@export var vgroups: VertexGroups


@export var verts = PackedVector3Array()
@export var uvs = PackedVector2Array()
@export var normals = PackedVector3Array()
@export var indices = PackedInt32Array()
#
#func _init(_mesh = null, _vgroups = null):
	#mesh = _mesh   
	#vgroups = _vgroups
	#print("mesh")
	#if mesh != null:
		#verts = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		#uvs = mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		#normals = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
		#indices = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]

func initialize():
	verts = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	uvs = mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	normals = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	indices = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	return self
	
func gen_new_surf(vgroup2pos):
	var new_surf = self.duplicate(true)
	for vgroup in vgroup2pos:
		var pos = vgroup2pos[vgroup]
		new_surf.move_vgroup(vgroup, pos)
	return new_surf

func move_vgroup(name, pos: Vector3):
	for group in vgroups.groups:
		if group.name != name:
			continue
		for idx in verts.size():
			if idx in group.indices:
				if not is_zero_approx(pos.x):
					verts[idx].x = pos.x
				if not is_zero_approx(pos.y):
					verts[idx].y = pos.y
				if not is_zero_approx(pos.z):
					verts[idx].z = pos.z
			uvs[idx] = Vector2(verts[idx].z, verts[idx].y)


func translate_vgroup(name, delta: Vector3):
	for group in vgroups.groups:
		if group.name != name:
			continue
		for idx in verts.size():
			if idx in group.indices:
				verts[idx] += delta
			uvs[idx] = Vector2(verts[idx].z, verts[idx].y)

func translate(pos: Vector3):
	
	for idx in verts.size():
		verts[idx] += pos


func rotatey(angle_deg: float):
	
	for idx in verts.size():
		verts[idx] = verts[idx].rotated( Vector3.UP, deg_to_rad(angle_deg))
		normals[idx] = normals[idx].rotated( Vector3.UP, deg_to_rad(angle_deg))

func scalez(val: float):
	for idx in verts.size():
		verts[idx].z *= val

func shear_vgroup(name, angle_deg: float):
	for group in vgroups.groups:
		if group.name != name:
			continue
		for idx in verts.size():
			if idx in group.indices:
				verts[idx].z = 0


func has_group(vg_name):
	for vg in vgroups.groups:
		if vg.name == vg_name:
			return true

	return false



func get_handle_pt(vg_name):
	var sum = Vector3()
	var len = 0
	for vg in vgroups.groups:
		if vg.name == vg_name:
			len = vg.indices.size()
			for idx in verts.size():
				if idx in vg.indices:
					sum += verts[idx]


	return sum/len
		

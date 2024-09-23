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

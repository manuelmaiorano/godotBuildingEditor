extends MeshInstance3D
class_name Wall


@export var original_mesh: ArrayMesh
@export var reset: bool = false

@export var vgroups: VertexGroups

var surfaces : Array[SurfaceData]

class SurfaceData:
	var verts : PackedVector3Array
	var uvs : PackedVector2Array
	var normals : PackedVector3Array
	var indices : PackedInt32Array

func _ready() -> void:
	for idx in range(original_mesh.get_surface_count()):
		var data = SurfaceData.new()
		
		data.verts = original_mesh.surface_get_arrays(idx)[Mesh.ARRAY_VERTEX]
		data.uvs = original_mesh.surface_get_arrays(idx)[Mesh.ARRAY_TEX_UV]
		data.normals = original_mesh.surface_get_arrays(idx)[Mesh.ARRAY_NORMAL]
		data.indices = original_mesh.surface_get_arrays(idx)[Mesh.ARRAY_INDEX]
		
		

func set_length(len):
	pass

func set_width(width):
	pass
	
func set_height(height):
	pass
	
func set_angle1(angle):
	pass

func set_angle2(angle):
	pass

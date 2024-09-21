@tool
extends MeshInstance3D
class_name WallInstance

@export var original_mesh: ArrayMesh
@export var reset: bool = false

@onready var verts = PackedVector3Array()
@onready var uvs = PackedVector2Array()
@onready var normals = PackedVector3Array()
@onready var indices = PackedInt32Array()
@onready var csgmesh = null

func _ready() -> void:
	
	_on_reset()
	for child in get_children():
		if child.has_signal("modifier_update"):
			child.modifier_update.connect(_on_modifiers_update)

func _on_reset():
	
	verts = original_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	uvs = original_mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	normals = original_mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	indices = original_mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	generate_mesh()
	
	for child in get_children():
		if child.has_method("_on_reset"):
			child._on_reset()

func _on_modifiers_update():
	for child in get_children():
		if child.has_method("process_modifier"):
			child.process_modifier(verts, normals, uvs, indices)
	generate_mesh()
	
func generate_mesh():
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if reset:
		_on_reset()
		reset = false
		

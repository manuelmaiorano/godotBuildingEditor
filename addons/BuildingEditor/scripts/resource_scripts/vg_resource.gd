
extends Resource
class_name VertexGroup 

@export var surf_name: String
@export var name: String
@export var indices: Array[int]

func _init(name = "", indices = []):
	name = name
	indices = indices

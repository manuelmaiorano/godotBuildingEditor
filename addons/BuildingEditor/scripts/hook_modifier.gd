@tool
extends Node3D

signal modifier_update

@export var object: PositionHandle
@export var vgroups: VertexGroups
@export var vgroup_name: String

@onready var sel_indices = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_reset()

	object.position_changed.connect(_on_pos_changed)

func _on_pos_changed():
	modifier_update.emit()
	
func _on_reset():
	object._on_reset()
	sel_indices = []
	for g in vgroups.groups:
		if g.name == vgroup_name:
			for index in g.indices:
				sel_indices.append(index)
	
func process_modifier(verts, normals, uvs, indices):
	for i in verts.size():
		if i in sel_indices:
			if abs(object.delta_pos.x) > 0.01:
				verts[i].x = object.position.x
			if abs(object.delta_pos.y) > 0.01:
				verts[i].y = object.position.y
			if abs(object.delta_pos.z) > 0.01:
				verts[i].z = object.position.z
		uvs[i] = Vector2(verts[i].z, verts[i].y)


		

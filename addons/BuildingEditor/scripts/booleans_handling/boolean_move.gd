@tool
extends Node3D
class_name  MovableBooleanShape


var connected = []



var current_pos 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_pos = global_position
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_pos == null:
		current_pos = global_position
	if global_position.distance_to(current_pos) > 0.01:
		current_pos = global_position
		for node in connected:
			node.global_transform = global_transform

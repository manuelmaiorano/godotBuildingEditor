@tool
extends Marker3D
class_name PositionHandle

var current_pos 
@onready var delta_pos = Vector3.ZERO
signal position_changed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_pos = position
	
func _on_reset():
	position = Vector3.ZERO
	delta_pos = Vector3.ZERO
	current_pos = Vector3.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if position.distance_to(current_pos) > 0.01:
		delta_pos = position-current_pos
		delta_pos = delta_pos.normalized()
		current_pos = position
		position_changed.emit()

extends Node
class_name Room


var walls: Array[Wall]
var points: Array[Vector3]

func _init(_points: Array[Vector3], _walls:  Array[Wall]) -> void:
	points = _points
	walls = _walls
	

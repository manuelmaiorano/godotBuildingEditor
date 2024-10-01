
@tool
extends Node3D
class_name Room


var floor: MeshInstance3D
var ceiling: MeshInstance3D

var points

@export var room_height: float = 0
@export var ceil_height: float = 0
@export var hide_ceiling: bool :
	set(value):
		hide_ceiling = value
		if value:
			_on_hide()
		else :
			_on_show()

@export var hide_floor: bool :
	set(value):
		hide_floor = value
		if value:
			_on_hide(true)
		else :
			_on_show(true)


func _init(_pts, _floor, _ceiling, _ceil_h) -> void:
	points = _pts
	print("ROOM")
	print(_pts[0].y)
	room_height = _pts[0].y
	floor = _floor
	ceiling = _ceiling
	ceil_height = _ceil_h
	ceiling.global_position.y =  ceil_height


func _on_hide(is_floor = false):
	if is_floor:
		floor.hide()
		return
	ceiling.hide()


func _on_show(is_floor = false):
	if is_floor:
		floor.show()
		return
	ceiling.show()

	

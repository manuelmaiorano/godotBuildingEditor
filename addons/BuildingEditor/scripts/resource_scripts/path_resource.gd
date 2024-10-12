@tool
extends Resource
class_name PathResource

@export var asset_path: String

func _init( _path = "") -> void:
	asset_path = _path
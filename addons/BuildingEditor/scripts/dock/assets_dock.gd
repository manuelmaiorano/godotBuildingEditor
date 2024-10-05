@tool
extends Control

signal asset_changed(asset_path)

var path_to_assets: String = "res://scenes/furniture/"
var btn_group: ButtonGroup = preload("res://addons/BuildingEditor/scenes/button_group.tres")

func _ready() -> void:
	create_buttons()
	btn_group.pressed.connect(_on_pressed)

func _on_pressed(btn):
	asset_changed.emit(path_to_assets + btn.text)


func create_buttons() -> void:
	var dir = DirAccess.open(path_to_assets)
	print(dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				if file_name.contains(".tscn"):
					print("Found file: " + file_name)
					BuildingEditor.get_preview(path_to_assets + file_name, self, "create_asset_button", file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")


func create_asset_button(path: String, preview: Texture2D, thumbnail: Texture2D, userdata):
	
	add_btn(userdata, preview)


func add_btn(asset_name: String, thumbnail: Texture2D):
	var btn = preload("res://addons/BuildingEditor/scenes/dock/asset_btn.tscn").instantiate()
	btn.toggle_mode = true
	btn.button_group = btn_group
	btn.set_data(asset_name, thumbnail)
	$ScrollContainer/HFlowContainer.add_child(btn)

func connect_signal(callable):
	if not is_connected(asset_changed.get_name(), callable):
		connect(asset_changed.get_name(), callable)

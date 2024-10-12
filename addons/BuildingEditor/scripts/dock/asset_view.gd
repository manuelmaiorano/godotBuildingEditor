@tool
extends ScrollContainer
class_name AssetView

var dir_path: String
var extension: String
var btn_group: ButtonGroup = preload("res://addons/BuildingEditor/scenes/button_group.tres")

func _ready():
	create_tab()

func create_tab() -> void:
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.contains(extension):
				print("Found file: " + dir_path + file_name)
				BuildingEditor.get_preview(dir_path + file_name, self, "create_asset_button", file_name)
			file_name = dir.get_next()


func create_asset_button(path: String, preview: Texture2D, thumbnail: Texture2D, userdata):
	add_btn(userdata, preview)


func add_btn(asset_name: String, thumbnail: Texture2D):
	var btn = preload("res://addons/BuildingEditor/scenes/dock/asset_btn.tscn").instantiate()
	btn.toggle_mode = true
	btn.button_group = btn_group
	btn.set_data(asset_name, thumbnail)
	$HFlowContainer.add_child(btn)

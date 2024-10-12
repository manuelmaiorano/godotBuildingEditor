@tool
extends Control

signal asset_changed(asset_path)

var scenes_path: String = ""
var materials_path: String = ""
var btn_group: ButtonGroup = preload("res://addons/BuildingEditor/scenes/button_group.tres")

var mat_tab
var scenes_tab

func _ready() -> void:
	create_tabs(scenes_path)
	create_tabs(materials_path, false)
	mat_tab = $HSplitContainer/TabContainer/Materials
	scenes_tab = $HSplitContainer/TabContainer/Scenes
	btn_group.pressed.connect(_on_pressed)

func _on_pressed(btn):
	if scenes_tab == null:
		return
	var tab_name = ""
	if $HSplitContainer/TabContainer.current_tab == 0:
		tab_name = scenes_tab.get_child(scenes_tab.current_tab).name
		asset_changed.emit(scenes_path +  tab_name + "/" + btn.text)
	else:
		tab_name = mat_tab.get_child(mat_tab.current_tab).name
		asset_changed.emit(materials_path  +  tab_name + "/" + btn.text)

func create_tabs(path, is_scenes = true) -> void:
	var dir = DirAccess.open(path)

	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var view = preload("res://addons/BuildingEditor/scenes/dock/asset_view.tscn").instantiate()
			view.name = file_name
			view.dir_path = path + file_name + "/"
			if is_scenes:
				view.extension = ".tscn"
				$HSplitContainer/TabContainer/Scenes.add_child(view)
			else:
				view.extension = ".tres"
				$HSplitContainer/TabContainer/Materials.add_child(view)
		file_name = dir.get_next()

func connect_signal(callable):
	if not is_connected(asset_changed.get_name(), callable):
		connect(asset_changed.get_name(), callable)


func _on_scenes_path_set(txt) -> void:
	scenes_path = txt
	print(scenes_path)
	for child in $HSplitContainer/TabContainer/Scenes.get_children():
		child.free()

	create_tabs(scenes_path)


func _on_mats_path_set(txt) -> void:
	materials_path = txt
	for child in $HSplitContainer/TabContainer/Materials.get_children():
		child.free()

	create_tabs(materials_path, false)

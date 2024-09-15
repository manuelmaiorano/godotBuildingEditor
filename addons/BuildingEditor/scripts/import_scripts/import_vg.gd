@tool
extends EditorImportPlugin


enum Presets { DEFAULT }

func _get_import_order() -> int:
	return 0

func _get_priority() -> float:
	return 2
	
func _get_preset_count():
	return Presets.size()

func _get_preset_name(preset_index):
	match preset_index:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown"
			
func _get_import_options(path, preset_index):
	match preset_index:
		_:
			return []

func _get_option_visibility(path, option_name, options):
	return true

func _get_importer_name():
	return "buildingeditor.vertex_groups"

func _get_visible_name():
	return "Vertex Groups"
	
func _get_recognized_extensions():
	return ["vgps"]
	
func _get_save_extension():
	return "tres"
	
func _get_resource_type():
	return "VertexGroups"
	
func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()

	var vgroups = VertexGroups.new()
	var lines = file.get_as_text()

	for line in lines.split("\n"):
		if line == "":
			continue
		var splitted = line.split(":")
		
		var name = splitted[0]
		var indices_str = splitted[1].split(",")

		var indices: Array[int] = []
		for idx in indices_str:
			indices.append(int(idx))

		
		var vgroup = VertexGroup.new()
		vgroup.name = name
		vgroup.indices = indices
		vgroups.groups.append(vgroup)
	print(vgroups)

	
	return ResourceSaver.save(vgroups, "%s.%s" % [save_path, _get_save_extension()])

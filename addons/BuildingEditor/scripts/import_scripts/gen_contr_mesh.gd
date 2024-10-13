@tool # Needed so it runs in editor.
extends EditorScenePostImport

var root = null
var vgroups: VertexGroups
var surfaces: Array[ControllableSurf] = []
@export var save_surf = false

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	# Change all node names to "modified_[oldnodename]"
	root = scene
	var path_to_vgroups
	
	var idx = get_source_file().length() - get_source_file().reverse().find("/")
	var path = get_source_file().substr(0, idx) + "gps.vgps"
	vgroups = load(path)
	iterate(scene)
	var cmesh = ControllableMesh.new()
	cmesh.surfaces = surfaces
	var res = ResourceSaver.save(cmesh, "res://addons/BuildingEditor/resources/controllableMeshes/%s.res" % scene.name)
	return scene # Remember to return the imported scene

# Recursive function that is called on every node
# (for demonstration purposes; EditorScenePostImport only requires a `_post_import(scene)` function).
func iterate(node: Node):
	if node != null:
		if node is MeshInstance3D:
			var res_surf = ControllableSurf.new()
			res_surf.mesh = node.mesh
			var vgs = VertexGroups.new()
			print("  " + node.name)
			for group in vgroups.groups:
				print(group.surf_name)
				print(group.name)
				if group.surf_name == node.name:
					vgs.groups.append(group.duplicate(true))
			res_surf.vgroups = vgs
			surfaces.append(res_surf)
			#var res = ResourceSaver.save(res_surf, "res://addons/BuildingEditor/resources/controllableMeshes/%s.res" % node.name)
		for child in node.get_children():
			iterate(child)

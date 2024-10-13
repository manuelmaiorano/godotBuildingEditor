@tool
extends  Resource
class_name  ControllableMesh

@export var surfaces: Array[ControllableSurf]

var vgroups: VertexGroups

func initialize():
	vgroups = VertexGroups.new()
	for surf in surfaces:
		surf.initialize()
		for s_vgroup in surf.vgroups.groups:
			var found = false
			for vgroup in vgroups.groups:
				if vgroup.name == s_vgroup.name:
					found = true
					break
			
			if not found:
				vgroups.groups.append(s_vgroup.duplicate(true))
	
	return self

func get_handle_point(vg_name: String):
	for vg in vgroups.groups:
		if vg.name == vg_name:
			for surf in surfaces:
				if surf.has_group(vg_name):
					return surf.get_handle_pt(vg_name)
	return null

func translate_vgroup(name, delta: Vector3):
	for surf in surfaces:
		surf.translate_vgroup(name, delta)
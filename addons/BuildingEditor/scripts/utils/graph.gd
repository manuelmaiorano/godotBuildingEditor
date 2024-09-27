@tool
extends EditorScript
class_name GRAPH_UTILS

#var graph = {}


# Main function to find all cycles in the graph
static func find_cycles(graph) -> Array:
	var stack = []
	var blocked = []
	var block_map = {}
	var cycles = []
	var start_vertex = null
	
	cycles.clear()
	# Start from each vertex in the graph
	for vertex in graph.keys():
		start_vertex = vertex
		blocked.clear()
		block_map.clear()
		for k in graph.keys():
			block_map[k] = []
		_find_cycles(graph, stack, blocked, start_vertex, cycles, block_map, vertex)
		_remove_vertex(graph, vertex)
		
	var minimal_cycles = []
	
	for _cycle in cycles:
		if _cycle.size() == 3:
			continue
		var cycle = _cycle.slice(0, _cycle.size()-1)
		var already_in_minimal = false
		for minimal in minimal_cycles:
			if same_elem(minimal, cycle):
				already_in_minimal = true
				break
		if already_in_minimal:
			continue
		minimal_cycles.append(cycle)
	return minimal_cycles

# Recursive function to find cycles
static func _find_cycles(graph, stack, blocked, start_vertex, cycles, block_map, v) -> bool:
	var found_cycle = false
	stack.append(v)
	blocked.append(v)

	for w in graph[v]:
		if w == start_vertex:
			# Found a cycle
			var cycle = stack.duplicate()
			cycle.append(start_vertex)
			cycles.append(cycle)
			found_cycle = true
		elif w not in blocked:
			if _find_cycles(graph, stack, blocked, start_vertex, cycles, block_map, w):
				found_cycle = true

	if found_cycle:
		_unblock(blocked, block_map, v)
	else:
		for neighbor in graph[v]:
			block_map[neighbor].append(v)

	stack.pop_back()
	return found_cycle

# Unblocks the vertex and its dependencies
static func _unblock(blocked, block_map, v) -> void:
	blocked.erase(v)
	while block_map[v].size() > 0:
		var w = block_map[v].pop_back()
		if w in blocked:
			_unblock(blocked, block_map, w)

# Removes a vertex from the graph
static func _remove_vertex(graph, v) -> void:
	var new_graph = {}
	for key in graph.keys():
		if key != v:
			new_graph[key] = []
			for neighbor in graph[key]:
				if neighbor != v:
					new_graph[key].append(neighbor)
	graph = new_graph

# Example Usage
func _run():
	# Define a graph as an adjacency list (directed graph)
	var graph = {
		0: [1, 3],
		1: [0, 2, 6],
		2: [1,  5],
		3: [0, 4],
		4: [3, 5],
		5: [4, 2, 6, 7],
		6: [1, 5],
		7: [5]
	}
	
	print(find_cycles(graph))
	
static func same_elem(arr1, arr2):
	for v in arr1:
		if not (v in arr2):
			return false
	for v in arr2:
		if not (v in arr1):
			return false
	return true

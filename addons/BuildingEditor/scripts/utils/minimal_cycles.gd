@tool
extends EditorScript

var graph = {}
var stack = []
var blocked = []
var block_map = {}
var cycles = []
var start_vertex = null


# Main function to find all cycles in the graph
func find_cycles() -> Array:
	cycles.clear()
	# Start from each vertex in the graph
	for vertex in graph.keys():
		start_vertex = vertex
		blocked.clear()
		block_map.clear()
		for k in graph.keys():
			block_map[k] = []
		_find_cycles(vertex)
		_remove_vertex(vertex)
	return cycles

# Recursive function to find cycles
func _find_cycles(v: int) -> bool:
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
			if _find_cycles(w):
				found_cycle = true

	if found_cycle:
		_unblock(v)
	else:
		for neighbor in graph[v]:
			block_map[neighbor].append(v)

	stack.pop_back()
	return found_cycle

# Unblocks the vertex and its dependencies
func _unblock(v: int) -> void:
	blocked.erase(v)
	while block_map[v].size() > 0:
		var w = block_map[v].pop_back()
		if w in blocked:
			_unblock(w)

# Removes a vertex from the graph
func _remove_vertex(v: int) -> void:
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
	graph = {
		0: [1, 3],
		1: [0, 2, 6],
		2: [1, 3, 5],
		3: [0, 2, 4],
		4: [3, 5],
		5: [4, 2, 6, 7],
		6: [1, 5],
		7: [5]
	}
	
	#graph = {
		#0: [1, 6, 5],
		#1: [0, 2],
		#2: [1, 3],
		#3: [2, 4, 6],
		#4: [3, 5],
		#5: [6, 0, 4],
		#6: [0, 5, 3]
	#}

	var found_cycles = find_cycles()

	var minimal_cycles = []
	
	for _cycle in found_cycles:
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
	print(minimal_cycles)
	
	#var fin_cycles = []
	#for cycle in minimal_cycles:
		#var skip = false
		#for cycle2 in minimal_cycles:
			#if same_elem(cycle, cycle2):
				#continue
			#if contains(cycle, cycle2):
				#skip = true
				#break
		#if skip:
			#continue
		#fin_cycles.append(cycle)
	#
	#for cycle in fin_cycles:
		#print("Cycle found:", cycle)
	
func same_elem(arr1, arr2):
	for v in arr1:
		if not (v in arr2):
			return false
	for v in arr2:
		if not (v in arr1):
			return false
	return true
	
func contains(arr1, arr2):
	for v in arr2:
		if v not in arr1:
			return false
	return true

func difference(arr1, arr2):
	var only_in_arr1 = []
	for v in arr1:
		if not (v in arr2):
			only_in_arr1.append(v)
	return only_in_arr1

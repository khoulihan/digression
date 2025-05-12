@tool
extends RefCounted


## Emitted when a graph is opened for the first time.
signal graph_opened(graph: OpenGraph)
## Emitted when a graph is edited.
signal graph_edited(graph: OpenGraph)
## Emitted when a graph is closed.
signal graph_closed(graph: OpenGraph)
## Emitted when the list of open graphs changes.
signal list_changed()


const OpenGraph = preload("OpenGraph.gd")

const Logging = preload("../../utility/Logging.gd")


## A collection of the currently open graphs.
var open_graphs: Array[OpenGraph]

## A stack of graphs that have been opened as subgraphs.
var graph_stack: Array[OpenGraph]

## The currently edited graph. Setting this clears the graph stack.
var current: OpenGraph:
	get:
		if len(graph_stack) > 0:
			return graph_stack[-1]
		return null
	set(value):
		graph_stack.clear()
		graph_stack.append(value)


var _logger = Logging.get_editor_logger()


## Request that a graph be opened for editing, optionally as a sub-graph of the 
## currently edited graph.
func request_open(graph: DigressionDialogueGraph, as_subgraph: bool = false) -> void:
	if graph == current:
		return
	graph.set_meta("_as_subgraph", as_subgraph)
	EditorInterface.edit_resource(graph)


## Request that a parent of the current graph be reopened for editing.
func request_open_parent(parent_index: int) -> void:
	var graph := graph_stack[parent_index]
	graph.graph.set_meta("_parent_index", parent_index)
	EditorInterface.edit_resource(graph.graph)


## Open the specified graph.
func open_graph(graph: DigressionDialogueGraph, path: String) -> OpenGraph:
	if graph.has_meta("_parent_index"):
		var i: int = graph.get_meta("_parent_index")
		graph.remove_meta("_parent_index")
		return _open_subgraph_parent(i)
		
	var as_subgraph: bool = graph.get_meta("_as_subgraph", false)
	if graph.has_meta("_as_subgraph"):
		graph.remove_meta("_as_subgraph")
	var existing := _find_existing(graph)
	if existing:
		_set_graph_as_current(existing, as_subgraph)
		graph_edited.emit(existing)
		return existing
	var o := OpenGraph.new(graph, path)
	self.open_graphs.append(o)
	_set_graph_as_current(o, as_subgraph)
	graph_opened.emit(o)
	graph_edited.emit(o)
	list_changed.emit()
	return o


## Return a collection of the graphs matching the provided filter string.
func filter(f: String) -> Array[OpenGraph]:
	var filtered: Array[OpenGraph] = []
	if f == "":
		filtered.append_array(open_graphs)
	else:
		for g in open_graphs:
			if g.graph.name.containsn(f) or g.graph.display_name.containsn(f):
				filtered.append(g)
	
	return filtered


func move_up(graph: OpenGraph) -> void:
	var index := open_graphs.find(graph)
	if index == 0:
		return
	open_graphs.remove_at(index)
	open_graphs.insert(index - 1, graph)
	list_changed.emit()


func move_down(graph: OpenGraph) -> void:
	var index := open_graphs.find(graph)
	if index == len(open_graphs) - 1:
		return
	open_graphs.remove_at(index)
	open_graphs.insert(index + 1, graph)
	list_changed.emit()


func sort() -> void:
	open_graphs.sort_custom(_sort_by_name)
	list_changed.emit()


func close_graph(graph: OpenGraph) -> void:
	var index := open_graphs.find(graph)
	open_graphs.remove_at(index)
	if self.current == graph:
		self.current = null
	graph_closed.emit(graph)
	list_changed.emit()


func close_all() -> void:
	if len(open_graphs) == 0:
		return
	self.current = null
	for graph in open_graphs.duplicate():
		open_graphs.remove_at(
			open_graphs.find(graph)
		)
		graph_closed.emit(graph)
	list_changed.emit()


func close_others(exception: OpenGraph) -> void:
	if len(open_graphs) == 1:
		return
	if self.current != exception:
		self.current = null
	for graph in open_graphs.duplicate():
		if exception == graph:
			continue
		open_graphs.remove_at(
			open_graphs.find(graph)
		)
		graph_closed.emit(graph)
	list_changed.emit()


func _sort_by_name(a: OpenGraph, b: OpenGraph) -> bool:
	if a.graph.name.is_empty() and b.graph.name.is_empty():
		return true
	if a.graph.name.is_empty() and not b.graph.name.is_empty():
		return false
	if not a.graph.name.is_empty() and b.graph.name.is_empty():
		return true
	return a.graph.name.naturalnocasecmp_to(b.graph.name) < 0


func _set_graph_as_current(o: OpenGraph, as_subgraph: bool = false) -> void:
	if as_subgraph:
		self.graph_stack.push_back(o)
	else:
		self.current = o


func _open_subgraph_parent(parent_index: int) -> OpenGraph:
	var graph = graph_stack[parent_index]
	if not graph in open_graphs:
		open_graphs.append(graph)
		list_changed.emit()
	graph_stack.resize(parent_index + 1)
	graph_edited.emit(graph)
	return graph


func _find_existing(graph: DigressionDialogueGraph) -> OpenGraph:
	for og in open_graphs:
		if og.graph == graph:
			return og
	return null

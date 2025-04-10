@tool
extends ItemList


signal graph_selected(graph)


const OpenGraph = preload("res://addons/hyh.digression/editor/DialogueGraphEditor.gd").OpenGraph
const GRAPH_ICON = preload("res://addons/hyh.digression/icons/icon_chat.svg")
const UNNAMED_GRAPH = "Unnamed Graph"


var _graph_list : Array[OpenGraph]
var _current_filter : String = ""
var _filtered : Array[OpenGraph]


func _ready() -> void:
	self.item_selected.connect(_on_item_selected)


func clear_list() -> void:
	_graph_list = []
	self.clear()


func populate(graphs: Array[OpenGraph]) -> void:
	self.clear_list()
	_graph_list.append_array(graphs)
	_graph_list.sort()
	self.filter(_current_filter)


func select_graph(name: String) -> void:
	self.deselect_all()
	if self.item_count == 0 or name == "":
		return
	for index in range(0, self.item_count):
		if self.get_item_text(index) == name:
			self.select(index)
			return


func select_first_graph() -> void:
	if self.item_count > 0:
		self.select(0)
		_on_item_selected(0)


func filter(f: String) -> void:
	_filtered = []
	_current_filter = f
	if f == "":
		_filtered.append_array(_graph_list)
	else:
		for g in _graph_list:
			if g.graph.name.containsn(f) or g.graph.display_name.containsn(f):
				_filtered.append(g)
	
	self.clear()
	for graph in _filtered:
		var new_index = self.add_item(_item_text_for_graph(graph), GRAPH_ICON)
		self.set_item_metadata(new_index, graph)
		self.set_item_tooltip(new_index, graph.path)


func _item_text_for_graph(graph: OpenGraph) -> String:
	return _get_name(graph.graph)


# TODO: This is duplicated code.
func _get_name(graph: DigressionDialogueGraph) -> String:
	var display_name = graph.display_name
	var name = graph.name
	if name == null or name == "":
		name = "unnamed"
	if display_name == null or display_name == "":
		display_name = UNNAMED_GRAPH
	return "%s (%s)" % [display_name, name]


func _on_item_selected(index: int) -> void:
	graph_selected.emit(self.get_item_metadata(index))

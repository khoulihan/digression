@tool
extends ItemList


const OpenGraphManager = preload("../../open_graphs/OpenGraphManager.gd")
const OpenGraph = OpenGraphManager.OpenGraph
const GRAPH_ICON = preload("res://addons/hyh.digression/icons/icon_chat.svg")
const UNNAMED_GRAPH = "Unnamed Graph"


var _manager: OpenGraphManager
var _current_filter : String = ""
var _filtered : Array[OpenGraph]


func _ready() -> void:
	self.item_selected.connect(_on_item_selected)


## Configure the list for the provided OpenGraphManager.
func configure(manager: OpenGraphManager) -> void:
	_manager = manager
	_manager.graph_opened.connect(_on_manager_changed)
	_manager.graph_closed.connect(_on_manager_changed)
	_manager.graph_edited.connect(_on_manager_changed)


## Clear the list
func clear_list() -> void:
	self.clear()


## Select the first graph with the specified name.
func select_graph(name: String) -> void:
	self.deselect_all()
	if self.item_count == 0 or name == "":
		return
	for index in range(0, self.item_count):
		if self.get_item_metadata(index).graph.name == name:
			self.select(index)
			return


## Select the graph with the specified resource path.
func select_graph_by_resource_path(path: String) -> void:
	self.deselect_all()
	if self.item_count == 0 or path == "":
		return
	for index in range(0, self.item_count):
		if self.get_item_metadata(index).graph.resource_path == path:
			self.select(index)
			return


## Select the first graph in the list. This is primarily used when the filter
## control is submitted.
func select_first_graph() -> void:
	if self.item_count > 0:
		self.select(0)
		_on_item_selected(0)


## Set the current filter and refresh the control.
func filter(f: String) -> void:
	_current_filter = f
	_refresh()


func _refresh() -> void:
	_filtered = _manager.filter(_current_filter)
	
	self.clear()
	for g in _filtered:
		var new_index = self.add_item(_item_text_for_graph(g), GRAPH_ICON)
		self.set_item_metadata(new_index, g)
		self.set_item_tooltip(new_index, g.path)


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


func _on_manager_changed(graph: Variant) -> void:
	# TODO: Could update the list in a more targeted way...
	_refresh()
	select_graph_by_resource_path(graph.graph.resource_path)


func _on_item_selected(index: int) -> void:
	var g := self.get_item_metadata(index) as OpenGraph
	_manager.request_open(g.graph)

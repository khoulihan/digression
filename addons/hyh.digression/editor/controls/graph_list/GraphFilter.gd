@tool
extends VBoxContainer


signal graph_selected(graph: OpenGraph)
signal toggle_panel_requested


const GraphList = preload("./GraphList.gd")
const OpenGraphManager = preload("../../open_graphs/OpenGraphManager.gd")
const OpenGraph = OpenGraphManager.OpenGraph


@onready var _filter: LineEdit = $GraphFilter
@onready var _list: GraphList = $MC/GraphList


## Configure the interface for the provided OpenGraphManager.
func configure(manager: OpenGraphManager) -> void:
	_list.configure(manager)


## Clear the list and filter.
func clear_list() -> void:
	_filter.clear()
	_list.clear()


func _on_graph_filter_text_changed(new_text: String) -> void:
	_list.filter(new_text)


func _on_graph_filter_text_submitted(new_text: String) -> void:
	if _list.item_count > 0:
		_list.grab_focus()
		_list.select_first_graph()


func _on_graph_list_toggle_panel_requested() -> void:
	toggle_panel_requested.emit()

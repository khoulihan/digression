@tool
extends HBoxContainer
## Control for showing a breadcrumb path of edited graphs in the graph editor.


const OpenGraphManager = preload("../open_graphs/OpenGraphManager.gd")
const OpenGraph = preload("../open_graphs/OpenGraph.gd")

const ARROW_ICON = preload("../../icons/icon_tree_arrow_right.svg")
const UNNAMED_GRAPH = "Unnamed Graph"


var _graph_manager: OpenGraphManager


## The navigability of breadcrumbs.
@export var navigable: bool = true:
	get:
		return navigable
	set(value):
		navigable = value
		for child in self.get_children():
			if child is LinkButton:
				child.disabled = not value


## Configure the control to use the provided OpenGraphManager.
func configure(manager: OpenGraphManager) -> void:
	_graph_manager = manager
	_graph_manager.graph_closed.connect(_on_manager_graph_closed)
	_graph_manager.graph_edited.connect(_on_manager_graph_edited)


## Clear all breadcrumbs.
func clear() -> void:
	_remove_existing()


func _refresh() -> void:
	_remove_existing()
	for graph_index in range(len(_graph_manager.graph_stack)):
		var graph = _graph_manager.graph_stack[graph_index]
		var is_current = graph_index == len(_graph_manager.graph_stack) - 1
		if not is_current:
			var button = LinkButton.new()
			if is_current:
				button.underline = LinkButton.UNDERLINE_MODE_NEVER
			else:
				button.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
			button.text = _get_button_text(graph, is_current)
			button.pressed.connect(
				_button_pressed.bind(graph_index)
			)
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			button.disabled = not self.navigable
			if not self.navigable:
				button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			self.add_child(button)
			var arrow = TextureRect.new()
			arrow.texture = ARROW_ICON
			arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			self.add_child(arrow)
		else:
			var label = Label.new()
			label.text = _get_button_text(graph, is_current)
			label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			label.add_theme_color_override("font_color", Color.WHITE)
			self.add_child(label)


func _button_pressed(index: int):
	_graph_manager.request_open_parent(index)


func _remove_existing() -> void:
	for child in self.get_children():
		if child is LinkButton:
			child.pressed.disconnect(_button_pressed)
		self.remove_child(child)


func _get_button_text(open_graph, is_current):
	if is_current:
		return _get_name(open_graph)
	var display_name = open_graph.graph.display_name
	var name = open_graph.graph.name
	if display_name != null and not display_name.is_empty():
		return display_name
	if name != null and not name.is_empty():
		return name
	return UNNAMED_GRAPH


func _get_name(open_graph):
	var display_name = open_graph.graph.display_name
	var name = open_graph.graph.name
	if name == null or name == "":
		name = "unnamed"
	if display_name == null or display_name == "":
		display_name = UNNAMED_GRAPH
	return "%s (%s)" % [display_name, name]


func _on_manager_graph_closed(graph: OpenGraph) -> void:
	if _graph_manager.current == null:
		clear()
	else:
		_refresh()


func _on_manager_graph_edited(graph: OpenGraph) -> void:
	_refresh()

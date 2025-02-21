@tool
extends HBoxContainer
## Control for showing a breadcrumb path of edited graphs in the graph editor.


signal graph_open_requested(index)

const ARROW_ICON = preload("../../icons/icon_tree_arrow_right.svg")
const UNNAMED_GRAPH = "Unnamed Graph"

## The navigability of breadcrumbs.
@export var navigable: bool = true:
	get:
		return navigable
	set(value):
		navigable = value
		for child in self.get_children():
			if child is LinkButton:
				child.disabled = not value


## Populate the control from a stacj of graphs.
func populate(graph_stack):
	_remove_existing()
	for graph_index in range(len(graph_stack)):
		var graph = graph_stack[graph_index]
		var is_current = graph_index == len(graph_stack) - 1
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
			


## Clear all breadcrumbs.
func clear():
	_remove_existing()


func _button_pressed(index):
	graph_open_requested.emit(index)


func _remove_existing():
	for child in self.get_children():
		if child is LinkButton:
			child.pressed.disconnect(_button_pressed)
		self.remove_child(child)


func _get_button_text(graph, is_current):
	if is_current:
		return _get_name(graph)
	var display_name = graph.display_name
	var name = graph.name
	if display_name != null and not display_name.is_empty():
		return display_name
	if name != null and not name.is_empty():
		return name
	return UNNAMED_GRAPH


func _get_name(graph):
	var display_name = graph.display_name
	var name = graph.name
	if name == null or name == "":
		name = "unnamed"
	if display_name == null or display_name == "":
		display_name = UNNAMED_GRAPH
	return "%s (%s)" % [display_name, name]

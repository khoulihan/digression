@tool
extends VBoxContainer
## The graph editor UI.

#region Signals

signal graph_edited(graph)
signal current_graph_modified()
signal previewable()
signal not_previewable()

#endregion

#region Constants

# Manager classes
const AnchorManager = preload("./open_graphs/AnchorManager.gd")
const OpenGraphManager = preload("./open_graphs/OpenGraphManager.gd")
const OpenGraph = OpenGraphManager.OpenGraph

# Control types
const DialogueGraphEditControl = preload("./controls/DialogueGraphEditControl.gd")
const AnchorFilter = preload("./controls/anchor_list/AnchorFilter.gd")
const GraphFilter = preload("./controls/graph_list/GraphFilter.gd")
const GraphBreadcrumbs = preload("./controls/GraphBreadcrumbs.gd")

# Utility classes.
const Dialogs = preload("./dialogs/Dialogs.gd")
const Logging = preload("../utility/Logging.gd")

# Resource graph nodes.
const GraphNodeBase = preload("../resources/graph/GraphNodeBase.gd")

# Resources required by UI controls
const BACK_ARROW_ICON = preload("res://addons/hyh.digression/icons/icon_back.svg")
const FORWARD_ARROW_ICON = preload("res://addons/hyh.digression/icons/icon_forward.svg")

#endregion

#region Variable declarations

var _graph_manager: OpenGraphManager
var _current_graph_type
var _resource_clipboard

# Anchor manager
var _anchor_manager: AnchorManager

var _logger := Logging.get_editor_logger()

# Nodes
@onready var _graph_edit: DialogueGraphEditControl = $HS/MC/VB/MC/GraphEdit
@onready var _maximised_node_editor = $HS/MC/VB/MC/MaximisedNodeEditor
@onready var _graph_popup = $GraphContextMenu
@onready var _breadcrumbs: GraphBreadcrumbs = $HS/MC/VB/BottomBar/GraphBreadcrumbs
@onready var _anchor_filter: AnchorFilter = $HS/LeftSidebar/AnchorFilter
@onready var _graph_filter: GraphFilter = $HS/LeftSidebar/GraphFilter
@onready var _left_sidebar := $HS/LeftSidebar
@onready var _left_sidebar_toggle := $HS/MC/VB/BottomBar/ToggleSidebarButton
@onready var _graph_type_label: Label = $HS/MC/VB/BottomBar/GraphTypeLabel
@onready var _graph_type_separator: VSeparator = $HS/MC/VB/BottomBar/GraphTypeSeparator

#endregion


#region Built-in virtual methods

func _init():
	_graph_manager = OpenGraphManager.new()
	_graph_manager.graph_closed.connect(_on_graph_manager_graph_closed)
	_graph_manager.graph_opened.connect(_on_graph_manager_graph_opened)
	_graph_manager.graph_edited.connect(_on_graph_manager_graph_edited)
	_graph_manager.graph_changed.connect(_on_graph_manager_graph_changed)
	_anchor_manager = AnchorManager.new()


func _ready():
	_update_preview_button_state()
	_graph_filter.configure(_graph_manager)
	_anchor_filter.configure(_anchor_manager)
	_graph_edit.configure(_anchor_manager)
	_breadcrumbs.configure(_graph_manager)
	_set_graph_type_label()
	# Create clipboard
	_resource_clipboard = ResourceClipboard.new()

#endregion


#region Public interface

## Sets the theme for the editor.
func set_theme(selected_theme: Theme) -> void:
	_graph_edit.theme = selected_theme


## Returns the currently edited graph resource.
func get_edited_graph():
	if _graph_manager.current == null:
		return null
	return _graph_manager.current.graph


## Edit the specified graph.
func edit_graph(object, path):
	_logger.debug("Attempting to edit path " + path)
	_graph_manager.open_graph(object, path)


## Clear the currently edited graph from the editor.
func clear():
	_graph_edit.clear()
	_graph_manager.current = null
	_anchor_manager.clear()
	_set_graph_type_label()
	_update_preview_button_state()


## Save the currently edited graph.
func perform_save():
	_logger.trace("perform_save()")
	if _graph_manager.current == null:
		return
	
	_graph_edit.update_edited_graph()
	_graph_manager.save_current()
	_set_dirty(false)

#endregion


#region Graph edit signal handlers

func _on_graph_edit_graph_modified() -> void:
	current_graph_modified.emit()

#endregion


#region Maximised node editor signal handlers

func _on_maximised_node_editor_restore_requested() -> void:
	_restore_maximised_node()


func _on_maximised_node_editor_modified(resource_node: GraphNodeBase) -> void:
	_graph_edit.update_node(resource_node)


func _on_maximised_node_editor_delete_request(resource_node: Resource) -> void:
	_graph_edit.remove_node(resource_node)
	_restore_maximised_node()


func _restore_maximised_node() -> void:
	_maximised_node_editor.visible = false
	_graph_edit.visible = true
	_graph_edit.redraw(true)

#endregion


#region Node signals

func _on_graph_edit_anchor_node_selected(node_name):
	_anchor_filter.select_anchor(node_name)


func _on_graph_edit_node_maximise_requested(node) -> void:
	_maximised_node_editor.visible = true
	_graph_edit.visible = false
	_maximised_node_editor.configure_for_node(
		_graph_manager.current.graph as DigressionDialogueGraph,
		node
	)


func _on_graph_edit_sub_graph_edit_requested(
	graph: DigressionDialogueGraph,
	path: String
):
	_graph_manager.request_open(graph, true)


func _on_graph_edit_display_filesystem_path_requested(path):
	EditorInterface.get_file_system_dock().navigate_to_path(
		_strip_resource_id(
			path
		)
	)


func _strip_resource_id(path: String) -> String:
	if not path.contains("::"):
		return path
	var index := path.find("::")
	return path.substr(0, index)


func _on_graph_edit_save_requested() -> void:
	if _graph_manager.current:
		_graph_manager.save_current()

#endregion


#region UI Signals


func _on_anchor_filter_anchor_selected(name: String) -> void:
	_graph_edit.focus_anchor(name)


func _on_toggle_sidebar_button_toggled(toggled_on: bool) -> void:
	_left_sidebar.visible = not toggled_on
	_left_sidebar_toggle.icon = FORWARD_ARROW_ICON if toggled_on else BACK_ARROW_ICON


func _on_graph_manager_graph_closed(graph: OpenGraph) -> void:
	if _graph_manager.current == null:
		clear()


func _on_graph_manager_graph_opened(graph: OpenGraph) -> void:
	# Probably nothing to do here actually, the important signal is `graph_edited`
	pass


func _on_graph_filter_save_requested(graph: OpenGraph) -> void:
	_graph_manager.save(graph)


func _on_graph_filter_save_as_requested(graph: OpenGraph) -> void:
	var path := await Dialogs.select_file_for_save(
		["*.tres", "Digression Graph Resource Files"],
		self,
		"Save Dialogue Graph Resource",
		EditorFileDialog.ACCESS_RESOURCES,
	)
	if not path.is_empty():
		_graph_manager.save_as(graph, path)


func _on_graph_edit_sub_graph_save_as_requested(graph: DigressionDialogueGraph) -> void:
	var path := await Dialogs.select_file_for_save(
		["*.tres", "Digression Graph Resource Files"],
		self,
		"Save Dialogue Graph Resource",
		EditorFileDialog.ACCESS_RESOURCES,
	)
	if not path.is_empty():
		_graph_manager.save_subgraph_as(graph, path)


func _on_graph_manager_graph_edited(graph: OpenGraph) -> void:
	_current_graph_type = graph.graph.graph_type
	_anchor_manager.configure(graph.graph)
	_graph_edit.edit_graph(graph)
	_graph_edit.restore_scroll_offset(
		graph.scroll_offset,
		graph.zoom
	)
	_set_graph_type_label()
	_update_preview_button_state()


func _on_graph_manager_graph_changed(graph: OpenGraph) -> void:
	if graph == _graph_manager.current:
		_set_graph_type_label()


func _on_graph_filter_toggle_panel_requested() -> void:
	_left_sidebar_toggle.button_pressed = !_left_sidebar_toggle.button_pressed

#endregion


#region UI state

func _update_preview_button_state():
	if _graph_manager.current == null:
		not_previewable.emit()
	else:
		previewable.emit()


func _set_dirty(val):
	_graph_manager.current.dirty = val
	current_graph_modified.emit()


func _set_graph_type_label():
	if _graph_manager.current == null:
		_graph_type_separator.visible = false
		_graph_type_label.text = ""
	else:
		_graph_type_separator.visible = true
		_graph_type_label.text = _graph_manager.current.graph.graph_type.capitalize()

#endregion


#region Internal classes

class ResourceClipboard:
	signal changed(value)
	var contents:
		get:
			return contents
		set(value):
			contents = value
			changed.emit(contents)


#endregion

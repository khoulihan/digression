@tool
extends VBoxContainer
## The graph editor UI.

#region Signals

## Emitted when saving the graph has been requested.
signal save_requested(object, path)
signal expand_button_toggled(button_pressed)
signal variable_select_dialog_state_changed(favourites, recent)
signal display_filesystem_path_requested(path)
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

#endregion


#region Built-in virtual methods

func _init():
	_graph_manager = OpenGraphManager.new()
	_graph_manager.graph_closed.connect(_on_graph_manager_graph_closed)
	_graph_manager.graph_opened.connect(_on_graph_manager_graph_opened)
	_graph_manager.graph_edited.connect(_on_graph_manager_graph_edited)
	_anchor_manager = AnchorManager.new()


func _ready():
	_update_preview_button_state()
	_graph_filter.configure(_graph_manager)
	_anchor_filter.configure(_anchor_manager)
	_graph_edit.configure(_anchor_manager)
	_breadcrumbs.configure(_graph_manager)
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
	_update_preview_button_state()


## Save the currently edited graph.
func perform_save():
	_logger.trace("perform_save()")
	if _graph_manager.current == null:
		return
	
	_graph_edit.update_edited_graph()
	save_requested.emit(
		_graph_manager.current.graph,
		_graph_manager.current.path,
	)
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
		node.node_resource
	)


func _on_graph_edit_sub_graph_edit_requested(
	graph: DigressionDialogueGraph,
	path: String
):
	_graph_manager.request_open(graph, true)


func _on_graph_edit_display_filesystem_path_requested(path):
	display_filesystem_path_requested.emit(path)


# TODO: Need to implement this. The save process is a bit up in the air now.
func _on_graph_edit_save_requested() -> void:
	if _graph_manager.current:
		save_requested.emit(
			_graph_manager.current.graph,
			_graph_manager.current.path
		)

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


func _on_graph_manager_graph_edited(graph: OpenGraph) -> void:
	_current_graph_type = graph.graph.graph_type
	_anchor_manager.configure(graph.graph)
	_graph_edit.edit_graph(graph)
	_graph_edit.restore_scroll_offset(
		graph.scroll_offset,
		graph.zoom
	)
	_update_preview_button_state()

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

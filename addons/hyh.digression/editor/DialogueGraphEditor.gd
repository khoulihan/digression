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

#region Enums

enum GraphNodeTypes {
	DIALOGUE,
	MATCH_BRANCH,
	IF_BRANCH,
	CHOICE,
	SET,
	ACTION,
	SUB_GRAPH,
	RANDOM,
	COMMENT,
	JUMP,
	ANCHOR,
	ROUTING,
	REPEAT,
	EXIT,
}

enum GraphPopupMenuItems {
	ADD_TEXT_NODE,
	ADD_MATCH_BRANCH_NODE,
	ADD_IF_BRANCH_NODE,
	ADD_CHOICE_NODE,
	ADD_SET_NODE,
	ADD_ACTION_NODE,
	ADD_SUB_GRAPH_NODE,
	ADD_RANDOM_NODE,
	SEPARATOR_1,
	ADD_COMMENT_NODE,
	SEPARATOR_2,
	ADD_JUMP_NODE,
	ADD_ANCHOR_NODE,
	ADD_ROUTING_NODE,
	ADD_REPEAT_NODE,
	ADD_EXIT_NODE,
}

enum GraphPopupMenuBounds {
	LOWER_BOUND = GraphPopupMenuItems.ADD_TEXT_NODE,
	UPPER_BOUND = GraphPopupMenuItems.ADD_EXIT_NODE
}

enum NodeCreationMode {
	NORMAL,
	CONNECTED,
	DUPLICATION,
	PASTE
}

enum ConnectionTypes {
	NORMAL,
	JUMP,
}

#endregion

#region Constants

# Manager classes
const AnchorManager = preload("./open_graphs/AnchorManager.gd")
const OpenGraphManager = preload("./open_graphs/OpenGraphManager.gd")

# Control types
const AnchorFilter = preload("./controls/anchor_list/AnchorFilter.gd")

# Utility classes.
const Dialogs = preload("dialogs/Dialogs.gd")
const DigressionSettings = preload("../settings/DigressionSettings.gd")
const Logging = preload("../utility/Logging.gd")
const TranslationKey = preload("../utility/TranslationKey.gd")
const DigressionTheme = preload("./themes/DigressionTheme.gd")

# Resource graph nodes.
const GraphNodeBase = preload("../resources/graph/GraphNodeBase.gd")
const DialogueNode = preload("../resources/graph/DialogueNode.gd")
const MatchBranchNode = preload("../resources/graph/MatchBranchNode.gd")
const IfBranchNode = preload("../resources/graph/IfBranchNode.gd")
const DialogueChoiceNode = preload("../resources/graph/DialogueChoiceNode.gd")
const VariableSetNode = preload("../resources/graph/VariableSetNode.gd")
const ActionNode = preload("../resources/graph/ActionNode.gd")
const SubGraph = preload("../resources/graph/SubGraph.gd")
const RandomNode = preload("../resources/graph/RandomNode.gd")
const CommentNode = preload("../resources/graph/CommentNode.gd")
const JumpNode = preload("../resources/graph/JumpNode.gd")
const AnchorNode = preload("../resources/graph/AnchorNode.gd")
const RoutingNode = preload("../resources/graph/RoutingNode.gd")
const RepeatNode = preload("../resources/graph/RepeatNode.gd")
const EntryPointAnchorNode = preload("../resources/graph/EntryPointAnchorNode.gd")
const ExitNode = preload("../resources/graph/ExitNode.gd")

# Editor node classes.
const EditorDialogueNode = preload("./nodes/EditorDialogueNode.gd")
const EditorMatchBranchNode = preload("./nodes/EditorMatchBranchNode.gd")
const EditorIfBranchNode = preload("./nodes/EditorIfBranchNode.gd")
const EditorChoiceNode = preload("./nodes/EditorChoiceNode.gd")
const EditorSetNode = preload("./nodes/EditorSetNode.gd")
const EditorGraphNodeBase = preload("./nodes/EditorGraphNodeBase.gd")
const EditorActionNode = preload("./nodes/EditorActionNode.gd")
const EditorSubGraphNode = preload("./nodes/EditorSubGraphNode.gd")
const EditorRandomNode = preload("./nodes/EditorRandomNode.gd")
const EditorCommentNode = preload("./nodes/EditorCommentNode.gd")
const EditorJumpNode = preload("./nodes/EditorJumpNode.gd")
const EditorAnchorNode = preload("./nodes/EditorAnchorNode.gd")
const EditorRoutingNode = preload("./nodes/EditorRoutingNode.gd")
const EditorRepeatNode = preload("./nodes/EditorRepeatNode.gd")
const EditorEntryPointAnchorNode = preload("./nodes/EditorEntryPointAnchorNode.gd")
const EditorExitNode = preload("./nodes/EditorExitNode.gd")

# Editor node scenes.
const EditorDialogueNodeScene = preload("./nodes/EditorDialogueNode.tscn")
const EditorMatchBranchNodeScene = preload("./nodes/EditorMatchBranchNode.tscn")
const EditorIfBranchNodeScene = preload("./nodes/EditorIfBranchNode.tscn")
const EditorChoiceNodeScene = preload("./nodes/EditorChoiceNode.tscn")
const EditorSetNodeScene = preload("./nodes/EditorSetNode.tscn")
const EditorGraphNodeBaseScene = preload("./nodes/EditorGraphNodeBase.tscn")
const EditorActionNodeScene = preload("./nodes/EditorActionNode.tscn")
const EditorSubGraphNodeScene = preload("./nodes/EditorSubGraphNode.tscn")
const EditorRandomNodeScene = preload("./nodes/EditorRandomNode.tscn")
const EditorCommentNodeScene = preload("./nodes/EditorCommentNode.tscn")
const EditorJumpNodeScene = preload("./nodes/EditorJumpNode.tscn")
const EditorAnchorNodeScene = preload("./nodes/EditorAnchorNode.tscn")
const EditorRoutingNodeScene = preload("./nodes/EditorRoutingNode.tscn")
const EditorRepeatNodeScene = preload("./nodes/EditorRepeatNode.tscn")
const EditorEntryPointAnchorNodeScene = preload("./nodes/EditorEntryPointAnchorNode.tscn")
const EditorExitNodeScene = preload("./nodes/EditorExitNode.tscn")

# Resources required by UI controls
const BACK_ARROW_ICON = preload("res://addons/hyh.digression/icons/icon_back.svg")
const FORWARD_ARROW_ICON = preload("res://addons/hyh.digression/icons/icon_forward.svg")

#endregion

#region Variable declarations

var _open_graphs: Array[OpenGraph]
var _edited: OpenGraph
# This is for recording a stack of edited subgraphs
# It is cleared when a graph is edited in the scene tree or filesystem
var _graph_stack
var _current_graph_type
var _resource_clipboard

# State variables for carrying out user actions.
var _last_popup_position
var _pending_connection_from
var _pending_connection_from_port
var _node_creation_mode
var _node_for_popup
var _sub_graph_editor_node_for_assignment
var _sub_graph_edit_requested

# Anchor manager
var _anchor_manager: AnchorManager

# Dialogue types for the current graph
var _dialogue_types

# Choice types for the current graph
var _choice_types

# Copy & paste
var _copied_nodes
var _scroll_on_copy

var _logger := Logging.get_editor_logger()

# Nodes
@onready var _graph_edit = $HS/MC/VB/MC/GraphEdit
@onready var _maximised_node_editor = $HS/MC/VB/MC/MaximisedNodeEditor
@onready var _graph_popup = $GraphContextMenu
@onready var _breadcrumbs = $HS/MC/VB/BottomBar/GraphBreadcrumbs
@onready var _anchor_filter: AnchorFilter = $HS/LeftSidebar/AnchorFilter
@onready var _graph_filter := $HS/LeftSidebar/GraphVB/GraphFilter
@onready var _graph_list := $HS/LeftSidebar/GraphVB/MC/GraphList
@onready var _left_sidebar := $HS/LeftSidebar
@onready var _left_sidebar_toggle := $HS/MC/VB/BottomBar/ToggleSidebarButton

#endregion


#region Built-in virtual methods

func _init():
	_open_graphs = []
	_anchor_manager = AnchorManager.new()
	_graph_stack = Array()
	ProjectSettings.settings_changed.connect(_on_settings_changed)


func _ready():
	_breadcrumbs.populate([])
	
	_update_preview_button_state()
	
	_anchor_filter.configure(_anchor_manager)
	
	# Create clipboard
	_resource_clipboard = ResourceClipboard.new()

#endregion


#region Public interface

## Sets the theme for the editor.
func set_theme(selected_theme: Theme) -> void:
	_graph_edit.theme = selected_theme


## Returns the currently edited graph resource.
func get_edited_graph():
	if _edited == null:
		return null
	return _edited.graph


## Edit the specified graph.
func edit_graph(object, path):
	_update_edited_graph()
	var edited
	_logger.debug("Attempting to edit path " + path)
	for graph in _open_graphs:
		if graph.graph == object:
			edited = graph
			break
	if edited == null:
		_logger.debug("Opening graph for first time")
		edited = OpenGraph.new()
		edited.graph = object
		edited.path = path
		edited.dirty = false
		edited.zoom = 1.0
		edited.scroll_offset = Vector2(0, 0)
		_open_graphs.append(edited)
	if _edited != null:
		_edited.graph.changed.disconnect(
			_on_edited_resource_changed
		)
	if not _sub_graph_edit_requested:
		_graph_stack.clear()
	_edited = edited
	_graph_stack.append(_edited.graph)
	_sub_graph_edit_requested = false
	_current_graph_type = _edited.graph.graph_type
	_edited.graph.changed.connect(
		_on_edited_resource_changed
	)
	_dialogue_types = _get_dialogue_types_for_graph_type(
		_edited.graph.graph_type
	)
	_choice_types = _get_choice_types_for_graph_type(
		_edited.graph.graph_type
	)
	_anchor_manager.configure(_edited.graph)
	_graph_list.populate(_open_graphs)
	_draw_edited_graph()
	_breadcrumbs.populate(_graph_stack)
	_update_preview_button_state()


## Clear the currently edited graph from the editor.
func clear():
	_clear_displayed_graph()
	if _edited != null:
		_edited.graph.changed.disconnect(
			_on_edited_resource_changed
		)
	_edited = null
	_breadcrumbs.populate([])
	_anchor_manager.clear()
	_update_preview_button_state()


## Save the currently edited graph.
func perform_save():
	_logger.trace("perform_save()")
	if _edited == null:
		return
	
	_update_edited_graph()
	save_requested.emit(
		_edited.graph,
		_edited.path,
	)
	_set_dirty(false)

#endregion


#region Graph signal handlers

func _on_edited_resource_changed():
	_logger.debug("Graph resource changed")
	_update_node_characters()
	# Only want to do this if the type has actually changed
	if _edited.graph.graph_type != _current_graph_type:
		_current_graph_type = _edited.graph.graph_type
		_dialogue_types = _get_dialogue_types_for_graph_type(
			_current_graph_type
		)
		_choice_types = _get_choice_types_for_graph_type(
			_current_graph_type
		)
		_draw_edited_graph(true)
	_breadcrumbs.populate(_graph_stack)
	current_graph_modified.emit()

#endregion


#region Graph edit signal handlers

func _on_graph_edit_connection_request(from, from_slot, to, to_slot):
	_logger.debug(
		"Connection request from %s, %s to %s, %s" % [
			from, from_slot, to, to_slot
		]
	)
	var connections = _graph_edit.get_connection_list()
	for connection in connections:
		if connection["from_node"] == from and connection["from_port"] == from_slot:
			# We only allow one outgoing connection from any port.
			return

	_graph_edit.connect_node(from, from_slot, to, to_slot)
	var from_node = _graph_edit.get_node(NodePath(from))
	var to_node = _graph_edit.get_node(NodePath(to))
	from_node.connected_to_node.emit(
		from_slot,
		to_node.node_resource.id,
	)
	# I think setting the dirty flag is supposed to allow the save to be
	# actioned later, when switching away from the graph for example. But
	# that wasn't happening...
	_set_dirty(true)
	perform_save()


func _on_graph_edit_disconnection_request(from, from_slot, to, to_slot):
	_logger.debug(
		"Disconnection request from %s, %s to %s, %s" % [
			from, from_slot, to, to_slot
		]
	)
	_graph_edit.disconnect_node(from, from_slot, to, to_slot)
	var from_node = _graph_edit.get_node(NodePath(from))
	from_node.disconnected.emit(from_slot)
	_set_dirty(true)
	perform_save()


func _on_graph_edit_end_node_move():
	_logger.debug("Graph node moved")
	_set_dirty(true)
	perform_save()


func _on_graph_edit_scroll_offset_changed(offset):
	if _edited == null:
		return
		
	_edited.zoom = _graph_edit.zoom
	_edited.scroll_offset = Vector2(_graph_edit.scroll_offset)
	# This would be debug but it is highly verbose
	_logger.trace(
		"Saved scroll offset and zoom: %s, %s" % [
			_edited.scroll_offset,
			_edited.zoom
		]
	)


func _on_graph_edit_duplicate_nodes_request():
	_create_duplicate_nodes(
		_get_selected_nodes()
	)


func _on_graph_breadcrumbs_graph_open_requested(index):
	_sub_graph_edit_requested = true
	var graph = _graph_stack[index]
	_graph_stack.resize(index)
	graph_edited.emit(graph)


func _on_graph_edit_paste_nodes_request():
	if _copied_nodes != null:
		_paste_nodes(_copied_nodes)


func _on_graph_edit_connection_to_empty(from_node, from_port, release_position):
	if not _edited:
		return
		
	_node_creation_mode = NodeCreationMode.CONNECTED
	_pending_connection_from = from_node
	_pending_connection_from_port = from_port
	_last_popup_position = _convert_popup_position(release_position)
	_graph_popup.position = get_screen_transform() * release_position
	_set_graph_popup_option_states()
	_graph_popup.popup()


func _on_graph_edit_copy_nodes_request():
	var copied_nodes = _get_selected_nodes()
	_copied_nodes = _get_node_states(copied_nodes)
	_scroll_on_copy = {
		"offset": _graph_edit.scroll_offset,
		"zoom": _graph_edit.zoom
	}


func _on_graph_edit_popup_request(p_position):
	if _edited:
		_node_creation_mode = NodeCreationMode.NORMAL
		_last_popup_position = _convert_popup_position(p_position)
		_graph_popup.position = get_screen_transform() * p_position
		_set_graph_popup_option_states()
		_graph_popup.popup()


func _on_graph_edit_focus_entered():
	_on_edited_resource_changed()

#endregion


#region Maximised node editor signal handlers

func _on_maximised_node_editor_restore_requested() -> void:
	_restore_maximised_node()


func _on_maximised_node_editor_modified(resource_node: GraphNodeBase) -> void:
	# TODO: Find the editor node corresponding to the provided resource node
	# and update it. May need to add a new method for this. Then, do the same
	# stuff as if the change had been made in the graph editor.
	var editor_node = _get_editor_node_for_graph_node(resource_node)
	editor_node.configure_for_node(_edited.graph, resource_node)


func _on_maximised_node_editor_delete_request(resource_node: Resource) -> void:
	var editor_node = _get_editor_node_for_graph_node(resource_node)
	_remove_nodes([editor_node.name])
	_restore_maximised_node()


func _restore_maximised_node() -> void:
	_maximised_node_editor.visible = false
	_graph_edit.visible = true
	_draw_edited_graph(true)

#endregion


#region Context menu signal handlers

func _on_graph_popup_index_pressed(index):
	_create_new_node_and_add(
		_node_type_for_menu_index(index),
		_node_creation_mode,
		_last_popup_position
	)
	_set_dirty(true)
	perform_save()


func _node_type_for_menu_index(index: GraphPopupMenuItems) -> GraphNodeTypes:
	match index:
		GraphPopupMenuItems.ADD_TEXT_NODE:
			return GraphNodeTypes.DIALOGUE
		GraphPopupMenuItems.ADD_MATCH_BRANCH_NODE:
			return GraphNodeTypes.MATCH_BRANCH
		GraphPopupMenuItems.ADD_IF_BRANCH_NODE:
			return GraphNodeTypes.IF_BRANCH
		GraphPopupMenuItems.ADD_CHOICE_NODE:
			return GraphNodeTypes.CHOICE
		GraphPopupMenuItems.ADD_SET_NODE:
			return GraphNodeTypes.SET
		GraphPopupMenuItems.ADD_ACTION_NODE:
			return GraphNodeTypes.ACTION
		GraphPopupMenuItems.ADD_SUB_GRAPH_NODE:
			return GraphNodeTypes.SUB_GRAPH
		GraphPopupMenuItems.ADD_RANDOM_NODE:
			return GraphNodeTypes.RANDOM
		GraphPopupMenuItems.ADD_COMMENT_NODE:
			return GraphNodeTypes.COMMENT
		GraphPopupMenuItems.ADD_JUMP_NODE:
			return GraphNodeTypes.JUMP
		GraphPopupMenuItems.ADD_ANCHOR_NODE:
			return GraphNodeTypes.ANCHOR
		GraphPopupMenuItems.ADD_ROUTING_NODE:
			return GraphNodeTypes.ROUTING
		GraphPopupMenuItems.ADD_REPEAT_NODE:
			return GraphNodeTypes.REPEAT
		GraphPopupMenuItems.ADD_EXIT_NODE:
			return GraphNodeTypes.EXIT
	_logger.error("Menu index did not correspond to graph node type: %s" % index)
	return GraphNodeTypes.DIALOGUE


func _on_graph_popup_hide():
	_logger.debug("Hiding graph popup")

#endregion


#region Graph context menu

func _set_graph_popup_option_states():
	match _node_creation_mode:
		NodeCreationMode.NORMAL:
			_set_all_graph_popup_disabled(false)
		NodeCreationMode.CONNECTED:
			_set_graph_popup_option_states_for_connected_creation()


func _set_graph_popup_option_states_for_connected_creation():
	_logger.debug("Pending connection from: %s" % _pending_connection_from)
	var from_node = _graph_edit.get_node(NodePath(_pending_connection_from))
	if from_node.get_output_port_type(
		_pending_connection_from_port
	) == ConnectionTypes.NORMAL:
		_set_all_graph_popup_disabled(false)
		_graph_popup.set_item_disabled(
			GraphPopupMenuItems.ADD_ANCHOR_NODE,
			true
		)
	else:
		_set_all_graph_popup_disabled(true)
		_graph_popup.set_item_disabled(
			GraphPopupMenuItems.ADD_ANCHOR_NODE,
			false
		)
	_graph_popup.set_item_disabled(
		GraphPopupMenuItems.ADD_COMMENT_NODE,
		true
	)


func _set_all_graph_popup_disabled(state):
	# TODO: Not great to use the current first and last elements here.
	for option in range(
		GraphPopupMenuBounds.LOWER_BOUND,
		GraphPopupMenuBounds.UPPER_BOUND + 1
	):
		_graph_popup.set_item_disabled(option, state)

#endregion


#region Node signals

func _connect_node_signals(node):
	node.removing_slot.connect(
		_on_node_removing_slot.bind(
			node.name
		)
	)
	node.delete_request.connect(
		_on_node_delete_request.bind(
			node.name
		)
	)
	node.modified.connect(
		_on_node_modified.bind(
			node.name
		)
	)
	node.maximise_requested.connect(
		_on_node_maximise_requested.bind(node)
	)
	if node is EditorSubGraphNode:
		node.sub_graph_open_requested.connect(
			_on_sub_graph_node_open_requested.bind(
				node
			)
		)
		node.display_filesystem_path_requested.connect(
			_on_sub_graph_node_display_filesystem_path_requested
		)
	if node is EditorJumpNode:
		node.destination_chosen.connect(
			_on_jump_node_destination_chosen.bind(
				node
			)
		)
	if node is EditorAnchorNode:
		node.node_selected.connect(
			_on_anchor_node_selected.bind(
				node
			)
		)


func _on_anchor_node_selected(node):
	_anchor_filter.select_anchor(node.node_resource.name)


func _on_node_removing_slot(slot, node_name):
	_logger.debug("Removal of slot %s on node %s requested" % [slot, node_name])
	var connections = _graph_edit.get_connection_list()
	for connection in connections:
		_process_connection_for_slot_removal(
			connection,
			slot,
			node_name,
		)
	_set_dirty(true)


func _on_node_delete_request(node_name):
	var nodes_to_remove := []
	if not node_name is Array:
		nodes_to_remove.append(node_name)
	else:
		nodes_to_remove.append_array(node_name)
	if _any_node_is_entry_point(nodes_to_remove):
		await Dialogs.show_error("The entry point node cannot be removed.")
		return
	var nodes_text = "this node"
	if len(nodes_to_remove) > 1:
		nodes_text = "these nodes"
	var dialog_text = "Are you sure you want to remove %s? This action cannot be undone." % nodes_text
	if await Dialogs.request_confirmation(dialog_text):
		_remove_nodes(nodes_to_remove)


func _any_node_is_entry_point(nodes) -> bool:
	for n in nodes:
		var node = _graph_edit.get_node(NodePath(n))
		if node is EditorEntryPointAnchorNode:
			return true
	return false


func _on_node_modified(node_name):
	var editor_node = _graph_edit.get_node(NodePath(node_name))
	if editor_node != null:
		if editor_node is EditorAnchorNode:
			_anchor_manager.configure(_edited.graph)
			_populate_anchor_destinations()
		var res = editor_node.node_resource
		# TODO: Would like to include a flag with this signal to indicate if
		# connections have been modified, to avoid recreating them unnecessarily.
		_clear_connections_for_node(res)
		_create_connections_for_node(res)
	perform_save()


func _on_node_maximise_requested(node) -> void:
	_maximised_node_editor.visible = true
	_graph_edit.visible = false
	_maximised_node_editor.configure_for_node(
		_edited.graph as DigressionDialogueGraph,
		node.node_resource
	)


func _on_sub_graph_node_open_requested(graph, editor_node):
	_sub_graph_edit_requested = true
	graph_edited.emit(graph)


func _on_sub_graph_node_display_filesystem_path_requested(path):
	display_filesystem_path_requested.emit(path)


func _on_jump_node_destination_chosen(destination_id, node):
	_logger.debug("Jump destination %s chosen for node %s" % [
		destination_id, node
	])
	node.node_resource.next = destination_id
	_draw_edited_graph(true)

#endregion


#region UI Signals


func _on_anchor_filter_anchor_selected(name: String) -> void:
	var anchor := _anchor_manager.get_anchor_by_name(name)
	var node = _get_editor_node_for_graph_node(_get_graph_node_by_id(anchor.id))
	_graph_edit.set_selected(node)
	var offset_to_node = (node.position_offset * _graph_edit.zoom)
	var centre_to_node = (_graph_edit.size / 2.0)
	var centre_node = ((node.size * _graph_edit.zoom) / 2.0)
	_graph_edit.scroll_offset = offset_to_node - centre_to_node + centre_node


func _on_graph_filter_text_changed(new_text: String) -> void:
	_graph_list.filter(new_text)


func _on_graph_filter_text_submitted(new_text: String) -> void:
	if _graph_list.item_count > 0:
		_graph_list.grab_focus()
		_graph_list.select_first_graph()


func _on_graph_list_graph_selected(graph: Variant) -> void:
	edit_graph(graph.graph, graph.path)


func _on_toggle_sidebar_button_toggled(toggled_on: bool) -> void:
	_left_sidebar.visible = not toggled_on
	_left_sidebar_toggle.icon = FORWARD_ARROW_ICON if toggled_on else BACK_ARROW_ICON

#endregion


#region Dialogue and choice types

func _get_dialogue_types_for_graph_type(graph_type):
	var all_types = DigressionSettings.get_dialogue_types()
	var allowed_types = []
	for dt in all_types:
		if graph_type in dt['allowed_in_graph_types']:
			allowed_types.append(dt)
	return allowed_types


func _get_choice_types_for_graph_type(graph_type):
	var all_types = DigressionSettings.get_choice_types()
	var allowed_types = []
	for ct in all_types:
		if graph_type in ct['allowed_in_graph_types']:
			allowed_types.append(ct)
	return allowed_types


func _get_default_dialogue_type():
	for t in _dialogue_types:
		if _edited.graph.graph_type in t['default_in_graph_types']:
			return t
	return null


func _get_default_choice_type():
	for t in _choice_types:
		if _edited.graph.graph_type in t['default_in_graph_types']:
			return t
	return null


func _set_default_dialogue_type_for_node(new_graph_node):
	var default_dialogue_type = _get_default_dialogue_type()
	if default_dialogue_type != null:
		var ddtd = default_dialogue_type as Dictionary
		new_graph_node.dialogue_type = ddtd['name']


func _set_default_choice_type_for_node(new_graph_node):
	var default_choice_type = _get_default_choice_type()
	if default_choice_type != null:
		var dctd = default_choice_type as Dictionary
		new_graph_node.choice_type = dctd['name']

#endregion


#region Graph drawing, editing and saving

func _create_new_node_and_add(
	node_type: GraphNodeTypes,
	node_creation_mode: NodeCreationMode,
	editor_position: Vector2,
	initial_state = {}
) -> GraphNode:
	var new_graph_node := _create_graph_node(node_type)
	_configure_graph_node_state(
		new_graph_node,
		initial_state,
		editor_position,
	)
	
	var new_editor_node := _instantiate_editor_node_and_add(new_graph_node)
	
	_edited.graph.nodes[new_graph_node.id] = new_graph_node
	
	_anchor_manager.configure(_edited.graph)
	_populate_anchor_destinations()
	
	_connect_new_editor_node_if_necessary(
		new_editor_node,
		node_creation_mode,
	)
	return new_editor_node


func _create_graph_node(node_type: GraphNodeTypes) -> GraphNodeBase:
	var new_graph_node
	
	match node_type:
		GraphNodeTypes.DIALOGUE:
			new_graph_node = DialogueNode.new()
			_set_default_dialogue_type_for_node(new_graph_node)
			new_graph_node.set_initial_translation_key(
				TranslationKey.generate(
					_edited.graph.name,
					"dialogue",
				)
			)
		GraphNodeTypes.MATCH_BRANCH:
			new_graph_node = MatchBranchNode.new()
		GraphNodeTypes.IF_BRANCH:
			new_graph_node = IfBranchNode.new()
		GraphNodeTypes.CHOICE:
			new_graph_node = DialogueChoiceNode.new()
			_set_default_dialogue_type_for_node(new_graph_node.dialogue)
			_set_default_choice_type_for_node(new_graph_node)
			new_graph_node.dialogue.set_initial_translation_key(
				TranslationKey.generate(
					_edited.graph.name,
					"choicedialogue",
				)
			)
		GraphNodeTypes.SET:
			new_graph_node = VariableSetNode.new()
		GraphNodeTypes.ACTION:
			new_graph_node = ActionNode.new()
		GraphNodeTypes.SUB_GRAPH:
			new_graph_node = SubGraph.new()
		GraphNodeTypes.RANDOM:
			new_graph_node = RandomNode.new()
		GraphNodeTypes.COMMENT:
			new_graph_node = CommentNode.new()
		GraphNodeTypes.JUMP:
			new_graph_node = JumpNode.new()
		GraphNodeTypes.ANCHOR:
			new_graph_node = AnchorNode.new()
			new_graph_node.name = _generate_anchor_name()
		GraphNodeTypes.ROUTING:
			new_graph_node = RoutingNode.new()
		GraphNodeTypes.REPEAT:
			new_graph_node = RepeatNode.new()
		GraphNodeTypes.EXIT:
			new_graph_node = ExitNode.new()
	
	return new_graph_node


func _configure_graph_node_state(
	new_graph_node,
	initial_state,
	editor_position,
):
	new_graph_node.id = _edited.graph.get_next_id()
	for property in initial_state:
		if property in new_graph_node and property not in ["offset"]:
			new_graph_node.set(
				property, 
				_deep_copy(initial_state[property])
			)
	new_graph_node.offset = editor_position


func _configure_editor_node_state(
	new_editor_node,
	new_graph_node
):
	new_editor_node.theme = DigressionTheme.get_theme()
	_populate_dependencies(new_editor_node)
	new_editor_node.configure_for_node(_edited.graph, new_graph_node)


func _connect_new_editor_node_if_necessary(
	new_editor_node,
	node_creation_mode
):
	if node_creation_mode == NodeCreationMode.CONNECTED:
		_logger.debug(
			"Auto-connecting new node from %s, %s" % [
				_pending_connection_from,
				_pending_connection_from_port,
			]
		)
		_graph_edit.connection_request.emit(
			_pending_connection_from,
			_pending_connection_from_port,
			new_editor_node.name,
			0,
		)


func _process_connection_for_slot_removal(
	connection,
	slot,
	node_name
):
	var from_node = connection["from_node"]
	var from_port = connection["from_port"]
	var to_node = connection["to_node"]
	var to_port = connection["to_port"]
	
	if from_node == node_name and from_port == slot:
		# This one just gets removed
		_graph_edit.disconnect_node(
			from_node,
			from_port,
			to_node,
			to_port
		)
	elif from_node == node_name and from_port > slot:
		# Remove and reconnect to slot + 1
		_graph_edit.disconnect_node(
			from_node,
			from_port,
			to_node,
			to_port
		)
		_graph_edit.connect_node(
			from_node,
			from_port - 1,
			to_node,
			to_port
		)


func _remove_nodes(nodes):
	_logger.debug(
		"Removal of node(s) {nodes} confirmed.".format({
			"nodes": nodes
		})
	)
	var connections = _graph_edit.get_connection_list()
	for n in nodes:
		_remove_node(n, connections)
	_ensure_graph_has_root()
	_set_dirty(true)
	_anchor_manager.configure(_edited.graph)
	_populate_anchor_destinations()


func _remove_node(n, connections):
	# This line is throwing an error now - cannot convert from StringName to NodePath
	var node = _graph_edit.get_node(NodePath(n))
	for connection in connections:
		if connection["from_node"] == n or connection["to_node"] == n:
			# This one just gets removed
			_remove_connection_for_node(
				connection,
			)
	
	if node.node_resource == _edited.graph.root_node:
		_edited.graph.root_node = null
	_edited.graph.nodes.erase(node.node_resource.id)
	_graph_edit.remove_child(node)


func _remove_connection_for_node(connection):
	var from_node_name = connection["from_node"]
	var from_port = connection["from_port"]
	_graph_edit.disconnect_node(
		from_node_name,
		from_port,
		connection["to_node"],
		connection["to_port"]
	)
	var from_node = _graph_edit.get_node(
		NodePath(from_node_name)
	)
	from_node.disconnected.emit(from_port)


## Update the UI to reflect changes in the underlying graph resource
func _draw_edited_graph(retain_selection=false):
	# Store the selection. Storing the editor nodes is no good as they are
	# about to be destroyed, so we need to get the Ids of the underlying
	# resources. This is skipped when switching graphs otherwise the selection
	# is inappropriate.
	var selected_node_ids = []
	if _edited != null and retain_selection:
		var selected_nodes = _get_selected_nodes()
		for n in selected_nodes:
			selected_node_ids.append(n.node_resource.id)

	# Clear the existing graph
	_clear_displayed_graph()

	if _edited == null:
		return

	# Now create and configure the display nodes
	for node in _edited.graph.nodes.values():
		var editor_node := _instantiate_editor_node_and_add(node)
		
		if node.id in selected_node_ids:
			editor_node.selected = true

	# Second pass to create connections
	for node in _edited.graph.nodes.values():
		_create_connections_for_node(node)
	
	if _edited.scroll_offset != null:
		_graph_edit.zoom = _edited.zoom
		# This was a deferred set previously, not sure why. It didn't seem
		# like it was actually being called.
		#_graph_edit.set_deferred("scroll_offset", _edited.scroll_offset)
		_graph_edit.scroll_offset = Vector2(_edited.scroll_offset)
		_logger.trace(
			"Restored scroll offset and zoom %s, %s from saved %s, %s" % [
				_graph_edit.scroll_offset,
				_graph_edit.zoom,
				_edited.scroll_offset,
				_edited.zoom
			]
		)


func _instantiate_editor_node_and_add(graph_node: GraphNodeBase) -> EditorGraphNodeBase:
	var editor_node := _instantiate_editor_node_for_graph_node(graph_node)
	_graph_edit.add_child(editor_node)
	_configure_editor_node_state(editor_node, graph_node)
	if graph_node == _edited.graph.root_node:
		editor_node.is_root = true
	_connect_node_signals(editor_node)
	return editor_node


func _instantiate_editor_node_for_graph_node(node) -> EditorGraphNodeBase:
	var editor_node
	
	if node is DialogueNode:
		editor_node = EditorDialogueNodeScene.instantiate()
	elif node is MatchBranchNode:
		editor_node = EditorMatchBranchNodeScene.instantiate()
	elif node is IfBranchNode:
		editor_node = EditorIfBranchNodeScene.instantiate()
	elif node is VariableSetNode:
		editor_node = EditorSetNodeScene.instantiate()
	elif node is DialogueChoiceNode:
		editor_node = EditorChoiceNodeScene.instantiate()
	elif node is ActionNode:
		editor_node = EditorActionNodeScene.instantiate()
	elif node is SubGraph:
		editor_node = EditorSubGraphNodeScene.instantiate()
	elif node is RandomNode:
		editor_node = EditorRandomNodeScene.instantiate()
	elif node is CommentNode:
		editor_node = EditorCommentNodeScene.instantiate()
	elif node is JumpNode:
		editor_node = EditorJumpNodeScene.instantiate()
	elif node is RoutingNode:
		editor_node = EditorRoutingNodeScene.instantiate()
	elif node is RepeatNode:
		editor_node = EditorRepeatNodeScene.instantiate()
	elif node is EntryPointAnchorNode:
		editor_node = EditorEntryPointAnchorNodeScene.instantiate()
	elif node is AnchorNode:
		editor_node = EditorAnchorNodeScene.instantiate()
	elif node is ExitNode:
		editor_node = EditorExitNodeScene.instantiate()
	
	editor_node.theme = DigressionTheme.get_theme()
	return editor_node


func _populate_dependencies(editor_node: EditorGraphNodeBase) -> void:
	if editor_node.has_method('populate_characters'):
		editor_node.populate_characters(_edited.graph.characters)
	if editor_node.has_method('set_dialogue_types'):
		editor_node.set_dialogue_types(_dialogue_types)
	if editor_node.has_method('set_choice_types'):
		editor_node.set_choice_types(_choice_types)
	if editor_node.has_method('populate_destinations'):
		editor_node.populate_destinations(_anchor_manager.get_anchor_map_by_id())
	if editor_node.has_method('set_resource_clipboard'):
		editor_node.set_resource_clipboard(_resource_clipboard)


func _create_connections_for_node(node):
	var connections: Array[int] = node.get_connections()
	if not connections.any(_is_connected):
		return
	var editor_node = _get_editor_node_for_graph_node(node)
	for index in range(0, len(connections)):
		if not _is_connected(connections[index]):
			continue
		var to = _get_editor_node_for_graph_node(
			_edited.graph.nodes[
				connections[index]
			]
		)
		_logger.debug("Adding connection %s port %s to %s port %s" % [
			editor_node.name,
			index,
			to.name,
			0
		])
		_graph_edit.connect_node(
			editor_node.name,
			index,
			to.name,
			0
		)


# TODO: This should probably accept the editor node directly instead of having
# to fetch it
func _clear_connections_for_node(node):
	# This method operates on the connections established by the editor node,
	# NOT the ones implied by the resource node.
	var editor_node = _get_editor_node_for_graph_node(node)
	var connections_list = _graph_edit.get_connection_list()
	for index in range(0, len(connections_list)):
		var connection = connections_list[index]
		if not connection['from_node'] == editor_node.name:
			continue
		_logger.debug("Removing connection %s port %s to %s port %s" % [
			connection['from_node'],
			connection['from_port'],
			connection['to_node'],
			connection['to_port']
		])
		_graph_edit.disconnect_node(
			connection['from_node'],
			connection['from_port'],
			connection['to_node'],
			connection['to_port']
		)


func _is_connected(node_id: int) -> bool:
	return node_id != -1


func _set_dirty(val):
	_edited.dirty = val
	current_graph_modified.emit()


func _get_editor_node_for_graph_node(n):
	for node in _get_graph_edit_children():
		if node is EditorGraphNodeBase:
			if node.node_resource == n:
				return node
	return null


func _get_graph_node_by_id(id):
	return _edited.graph.nodes.get(id)


func _clear_displayed_graph():
	_graph_edit.clear_connections()
	var graph_nodes = _get_graph_edit_children()
	for node in graph_nodes:
		_logger.debug("Removing node %s" % node.name)
		_graph_edit.remove_child(node)
		node.queue_free()


## Update the graph resources from the current state of the UI.
func _update_edited_graph():
	if _edited == null:
		return
	
	_logger.trace("_update_edited_graph(): %s" % _edited.graph.name)
	
	for node in _get_graph_edit_children():
		node.persist_changes_to_node()
		# Clobber all relationships - they will be recreated if they still exist
		node.clear_node_relationships()
	var connections = _graph_edit.get_connection_list()
	for connection in connections:
		_update_resource_graph_for_connection(connection)


func _update_resource_graph_for_connection(connection):
	var from = _graph_edit.get_node(NodePath(connection["from_node"]))
	var from_slot = connection["from_port"]
	var to = _graph_edit.get_node(NodePath(connection["to_node"]))
	var from_dialogue_node = from.node_resource
	var to_dialogue_node = to.node_resource
	from_dialogue_node.connect_to_node(from_slot, to_dialogue_node.id)


func _update_node_characters():
	_logger.debug("Updating node characters")
	for node in _get_graph_edit_children():
		if node.has_method("populate_characters"):
			node.populate_characters(_edited.graph.characters)


func _populate_anchor_destinations():
	_logger.debug("Populating anchor destinations")
	for node in _get_graph_edit_children():
		if node.has_method("populate_destinations"):
			node.populate_destinations(
				_anchor_manager.get_anchor_map_by_id()
			)


func _generate_anchor_name():
	return "%s%s" % [
		DigressionDialogueGraph.NEW_ANCHOR_PREFIX,
		_edited.graph.get_next_anchor_number(),
	]


## Sets the first Entry point node as root if there is currently no root node.
## This should be redundant now as there should only be one entry point, and
## it should not be possible to remove it...
func _ensure_graph_has_root() -> void:
	if _edited.graph.root_node != null:
		return
	var children = _get_graph_edit_children()
	for child in children:
		if not _editor_node_can_be_root(child):
			continue
		child.is_root = true
		_edited.graph.root_node = child.node_resource
		return


func _editor_node_can_be_root(n) -> bool:
	return n is EditorEntryPointAnchorNode


func _on_settings_changed() -> void:
	# The main thing we need to be looking for at the moment is if the theme
	# was changed.
	if DigressionTheme.has_theme_changed():
		_logger.trace("Updating nodes after theme update")
		_update_theme_on_nodes()


func _update_theme_on_nodes() -> void:
	for node: GraphNode in _get_graph_edit_children():
		node.theme = DigressionTheme.get_theme()

#endregion


#region UI state

func _update_preview_button_state():
	if _edited == null:
		not_previewable.emit()
	else:
		previewable.emit()

#endregion


#region Copy & paste, duplicate

func _get_selected_nodes():
	var selected_nodes = []
	for node in _get_graph_edit_children():
		if node is EditorEntryPointAnchorNode:
			continue
		if node.selected:
			selected_nodes.append(node)
	return selected_nodes


func _create_duplicate_nodes(nodes_to_duplicate):
	var new_nodes = {}
	for n in nodes_to_duplicate:
		if n is EditorEntryPointAnchorNode:
			continue
		var node_state = _get_node_state(n)
		var duplicated_node = _create_new_node_and_add(
			node_state["_node_type"],
			NodeCreationMode.DUPLICATION,
			n.position_offset + Vector2(150, 150),
			node_state
		)
		new_nodes[node_state["_original_id"]] = duplicated_node
	
	_create_connections_for_copied_nodes(new_nodes)
	_anchor_manager.configure(_edited.graph)
	_populate_anchor_destinations()
		
	_deselect_all()
	_select_nodes(new_nodes.values())
	# Redraw the graph while retaining the selection
	_draw_edited_graph(true)


# The difference between this method and the duplication method is that this
# one has to work with node state dictionaries that were saved earlier, while
# the duplication method works directly from the nodes.
func _paste_nodes(nodes_to_paste):
	var new_nodes = {}
	for n in nodes_to_paste:
		# TODO: Need a new way to determine position
		var pasted_node = _create_new_node_and_add(
			n["_node_type"],
			NodeCreationMode.PASTE,
			n["offset"] + Vector2(200, 200),
			n
		)
		new_nodes[n["_original_id"]] = pasted_node
	
	_create_connections_for_copied_nodes(new_nodes)
	_anchor_manager.configure(_edited.graph)
	_populate_anchor_destinations()
	
	_deselect_all()
	_select_nodes(new_nodes.values())
	# Redraw the graph while retaining the selection
	_draw_edited_graph(true)


func _create_connections_for_copied_nodes(new_nodes):
	# Need to find any references to this id in the next and branches
	# properties of the new nodes.
	for original_id in new_nodes.keys():
		for pasted in new_nodes.values():
			var id = new_nodes[original_id].node_resource.id
			var pasted_res = pasted.node_resource
			if pasted_res.next == original_id:
				_logger.debug(
					"Updating next link for copied node %s from %s to %s" % [
						pasted_res.id, pasted_res.next, id
					]
				)
				# Update to the new id.
				pasted_res.next = id
				
			if "branches" in pasted_res:
				for b in range(len(pasted_res.branches)):
					if pasted_res.branches[b] == original_id:
						_logger.debug(
							"Updating branch link for copied node %s from %s to %s" % [
								pasted_res.id, original_id, id
							]
						)
						pasted_res.branches[b] = id
			elif "choices" in pasted_res:
				for b in range(len(pasted_res.choices)):
					if pasted_res.choices[b].next == original_id:
						_logger.debug(
							"Updating choice link for copied node %s from %s to %s" % [
								pasted_res.id, original_id, id
							]
						)
						pasted_res.choices[b].next = id


func _deselect_all():
	for node in _get_graph_edit_children():
		node.selected = false


func _select_nodes(nodes):
	for node in nodes:
		node.selected = true


func _get_node_states(nodes):
	var node_states = []
	for node in nodes:
		node_states.append(
			_get_node_state(
				node
			)
		)
	return node_states


func _get_node_state(node):
	var initial_state = {}
	var graph_node = node.node_resource
	var properties = graph_node.get_property_list()
	
	for property in properties:
		# `name` is excluded so that copied anchor nodes will have new
		# names generated.
		if property["name"] not in ["id", "name"]: # Previously omitted "offset" as well...
			initial_state[property["name"]] = _deep_copy(
				graph_node.get(property["name"])
			)
	
	# Also need to store the node type
	initial_state["_node_type"] = _node_type_for_node(node)
	# Required for duplicating the connections
	initial_state["_original_id"] = graph_node.id
	
	return initial_state


func _node_type_for_node(node: GraphNode) -> GraphNodeTypes:
	if node is EditorActionNode:
		return GraphNodeTypes.ACTION
	elif node is EditorMatchBranchNode:
		return GraphNodeTypes.MATCH_BRANCH
	elif node is EditorIfBranchNode:
		return GraphNodeTypes.IF_BRANCH
	elif node is EditorDialogueNode:
		return GraphNodeTypes.DIALOGUE
	elif node is EditorSetNode:
		return GraphNodeTypes.SET
	elif node is EditorSubGraphNode:
		return GraphNodeTypes.SUB_GRAPH
	elif node is EditorChoiceNode:
		return GraphNodeTypes.CHOICE
	elif node is EditorRandomNode:
		return GraphNodeTypes.RANDOM
	elif node is EditorCommentNode:
		return GraphNodeTypes.COMMENT
	elif node is EditorJumpNode:
		return GraphNodeTypes.JUMP
	elif node is EditorAnchorNode:
		return GraphNodeTypes.ANCHOR
	elif node is EditorRoutingNode:
		return GraphNodeTypes.ROUTING
	elif node is EditorRepeatNode:
		return GraphNodeTypes.REPEAT
	elif node is EditorExitNode:
		return GraphNodeTypes.EXIT
	return GraphNodeTypes.DIALOGUE

#endregion


#region Utility functions

## Deep copies arrays and dictionaries. Just returns anything else.
func _deep_copy(obj):
	if obj == null:
		return obj
	if obj is Array or obj is Dictionary:
		return obj.duplicate(true)
	return obj


func _convert_popup_position(release_position):
	# This works pretty well - node appears slightly below and to the right of 
	# the click location so much like where a popup menu would appear. It was
	# determined by trial and error.
	return (release_position / _graph_edit.zoom) + \
		(_graph_edit.scroll_offset / _graph_edit.zoom)


func _get_graph_edit_children() -> Array:
	var c = _graph_edit.get_children()
	# Should not be getting these, but in 4.3 a "_connection_layer" node is
	# being returned and removing it crashes the editor, while other operations
	# on it fail because it is not one of our nodes.
	return c.filter(func(child): return not child.name.begins_with("_"))

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


class OpenGraph:
	var graph : DigressionDialogueGraph
	var path
	var dirty
	var zoom
	var scroll_offset

#endregion

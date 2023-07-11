@tool
extends VBoxContainer

## Emitted when saving the graph has been requested.
signal save_requested(object, path)
signal expand_button_toggled(button_pressed)

# Utility classes.
const Logging = preload("../utility/Logging.gd")
const TranslationKey = preload("../utility/TranslationKey.gd")

# Resource graph nodes.
const DialogueTextNode = preload("../resources/graph/DialogueTextNode.gd")
const BranchNode = preload("../resources/graph/BranchNode.gd")
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

# Editor node classes.
const EditorTextNodeClass = preload("./nodes/EditorTextNode.gd")
const EditorBranchNodeClass = preload("./nodes/EditorBranchNode.gd")
const EditorChoiceNodeClass = preload("./nodes/EditorChoiceNode.gd")
const EditorSetNodeClass = preload("./nodes/EditorSetNode.gd")
const EditorGraphNodeBaseClass = preload("./nodes/EditorGraphNodeBase.gd")
const EditorActionNodeClass = preload("./nodes/EditorActionNode.gd")
const EditorSubGraphNodeClass = preload("./nodes/EditorSubGraphNode.gd")
const EditorRandomNodeClass = preload("./nodes/EditorRandomNode.gd")
const EditorCommentNodeClass = preload("./nodes/EditorCommentNode.gd")
const EditorJumpNodeClass = preload("./nodes/EditorJumpNode.gd")
const EditorAnchorNodeClass = preload("./nodes/EditorAnchorNode.gd")
const EditorRoutingNodeClass = preload("./nodes/EditorRoutingNode.gd")
const EditorRepeatNodeClass = preload("./nodes/EditorRepeatNode.gd")

# Editor node scenes.
const EditorTextNode = preload("./nodes/EditorTextNode.tscn")
const EditorBranchNode = preload("./nodes/EditorBranchNode.tscn")
const EditorChoiceNode = preload("./nodes/EditorChoiceNode.tscn")
const EditorSetNode = preload("./nodes/EditorSetNode.tscn")
const EditorGraphNodeBase = preload("./nodes/EditorGraphNodeBase.tscn")
const EditorActionNode = preload("./nodes/EditorActionNode.tscn")
const EditorSubGraphNode = preload("./nodes/EditorSubGraphNode.tscn")
const EditorRandomNode = preload("./nodes/EditorRandomNode.tscn")
const EditorCommentNode = preload("./nodes/EditorCommentNode.tscn")
const EditorJumpNode = preload("./nodes/EditorJumpNode.tscn")
const EditorAnchorNode = preload("./nodes/EditorAnchorNode.tscn")
const EditorRoutingNode = preload("./nodes/EditorRoutingNode.tscn")
const EditorRepeatNode = preload("./nodes/EditorRepeatNode.tscn")


class OpenGraph:
	var graph
	var path
	var dirty
	var zoom
	var scroll_offset


enum GraphPopupMenuItems {
	ADD_TEXT_NODE,
	ADD_BRANCH_NODE,
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
}

enum GraphPopupMenuBounds {
	LOWER_BOUND = GraphPopupMenuItems.ADD_TEXT_NODE,
	UPPER_BOUND = GraphPopupMenuItems.ADD_REPEAT_NODE
}

enum NodePopupMenuItems {
	SET_ROOT
}

enum ConfirmationActions {
	REMOVE_NODE,
	REMOVE_CHARACTER,
	CLOSE_GRAPH
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

var _open_graphs
var _edited
var _current_graph_type

# Nodes
var _save_dialog
var _open_graph_dialog
var _open_sub_graph_dialog
var _open_character_dialog
@onready var _graph_edit = $MarginContainer/GraphEdit
@onready var _cutscene_name = $MenuBar/CutsceneName
@onready var _graph_popup = $GraphContextMenu
@onready var _node_popup = $NodePopupMenu
@onready var _confirmation_dialog = $ConfirmationDialog
@onready var _error_dialog = $ErrorDialog

# State variables for carrying out user actions.
var _last_popup_position
var _pending_connection_from
var _pending_connection_from_port
var _node_creation_mode
var _confirmation_action
var _node_to_remove
var _node_for_popup
var _sub_graph_editor_node_for_assignment

# Anchor maps
# TODO: One of these is not actually required.
var _anchors_by_name = {}
var _anchor_names_by_id = {}

# Dialogue types for the current graph
var _dialogue_types

# Copy & paste
var _copied_nodes
var _scroll_on_copy

var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


func _init():
	_open_graphs = Array()


func _ready():
	# Set up editor
	_graph_edit.popup_request.connect(
		_graph_popup_requested
	)
	
	# Refresh the graph when we receive input focus, in case the resource
	# has been changed externally
	_graph_edit.focus_entered.connect(
		_edited_resource_changed
	)
	
	_graph_edit.gui_input.connect(_graph_gui_input)

	# Context menu
	_graph_popup.index_pressed.connect(
		_graph_popup_index_pressed
	)
	_graph_popup.popup_hide.connect(
		_graph_popup_hidden
	)
	_node_popup.index_pressed.connect(
		_node_popup_index_pressed
	)

	# Confirmation dialog
	_confirmation_dialog.confirmed.connect(
		_action_confirmed
	)

	# Set up save dialog
	_save_dialog = EditorFileDialog.new()
	_save_dialog.add_filter("*.tres")
	_save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_save_dialog.mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	self.add_child(_save_dialog)
	_save_dialog.file_selected.connect(
		_file_selected
	)

	# Set up Open dialogs
	_open_graph_dialog = EditorFileDialog.new()
	_open_graph_dialog.add_filter("*.tres")
	_open_graph_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_open_graph_dialog.mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	self.add_child(_open_graph_dialog)
	_open_graph_dialog.file_selected.connect(
		_graph_file_selected_for_opening
	)

	_open_sub_graph_dialog = EditorFileDialog.new()
	_open_sub_graph_dialog.add_filter("*.tres")
	_open_sub_graph_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_open_sub_graph_dialog.mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	self.add_child(_open_sub_graph_dialog)
	_open_sub_graph_dialog.file_selected.connect(
		_sub_graph_file_selected_for_opening
	)

	# TODO: I think this is not required any more...
	#_open_character_dialog = EditorFileDialog.new()
	#_open_character_dialog.add_filter("*.tres")
	#_open_character_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	#_open_character_dialog.mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	#self.add_child(_open_character_dialog)
	#_open_character_dialog.file_selected.connect(
	#	_character_file_selected_for_opening
	#)


func _get_dialogue_types_for_graph_type(graph_type):
	var all_types = ProjectSettings.get_setting(
		'cutscene_graph_editor/dialogue_types'
	)
	var allowed_types = []
	for dt in all_types:
		if graph_type in dt['allowed_in_graph_types']:
			allowed_types.append(dt)
	return allowed_types


func edit_graph(object, path):
	_update_edited_graph()
	var edited
	Logger.debug("Attempting to edit path " + path)
	for graph in _open_graphs:
		if graph.graph == object:
			edited = graph
			break
	if edited == null:
		Logger.debug("Opening graph for first time")
		edited = OpenGraph.new()
		edited.graph = object
		edited.path = path
		edited.dirty = false
		edited.zoom = 1.0
		edited.scroll_offset = Vector2(0, 0)
		_open_graphs.append(edited)
	if _edited != null:
		_edited.graph.changed.disconnect(
			_edited_resource_changed
		)
	_edited = edited
	_current_graph_type = _edited.graph.graph_type
	_edited.graph.changed.connect(
		_edited_resource_changed
	)
	_dialogue_types = _get_dialogue_types_for_graph_type(
		_edited.graph.graph_type
	)
	_refresh_anchor_maps()
	_draw_edited_graph()


func _refresh_anchor_maps():
	Logger.debug("Refreshing anchor maps")
	var anchor_maps = _edited.graph.get_anchor_maps()
	_anchors_by_name = anchor_maps[0]
	_anchor_names_by_id = anchor_maps[1]


func _get_resource_path():
	_save_dialog.popup_centered_clamped(Vector2(800, 700))


func _get_open_path():
	_open_graph_dialog.popup_centered_clamped(Vector2(800, 700))


func _get_sub_graph_open_path():
	_open_sub_graph_dialog.popup_centered_clamped(Vector2(800, 700))


func _file_selected(path):
	_edited.path = path
	perform_save()


func _graph_file_selected_for_opening(path):
	var res = load(path)
	if not res is CutsceneGraph:
		_error_dialog.dialog_text = "The selected resource is not a CutsceneGraph."
		_error_dialog.popup_centered()
		return
	edit_graph(res, path)


func _sub_graph_file_selected_for_opening(path):
	var res = load(path)
	if not res is CutsceneGraph:
		_error_dialog.dialog_text = "The selected resource is not a CutsceneGraph."
		_error_dialog.popup_centered()
		return
	_configure_sub_graph_node(_sub_graph_editor_node_for_assignment, res)


func _configure_sub_graph_node(editor_node, res):
	editor_node.sub_graph_selected(res)


func _graph_popup_requested(p_position):
	if _edited:
		_node_creation_mode = NodeCreationMode.NORMAL
		_last_popup_position = _convert_popup_position(p_position)
		_graph_popup.position = get_screen_transform() * p_position
		_set_graph_popup_option_states()
		_graph_popup.popup()


func _graph_popup_hidden():
	Logger.debug("Hiding graph popup")


func _graph_gui_input(event: InputEvent):
	pass


func _node_popup_request(p_position, node_name):
	_node_for_popup = node_name
	var node = _graph_edit.get_node(NodePath(node_name))
	# The repeat node would be a ridiculous place to start, so disallow setting
	# one as the root.
	_node_popup.set_item_disabled(0, node is EditorRepeatNodeClass)
	_node_popup.position = p_position
	_node_popup.popup()


func _graph_popup_index_pressed(index):
	var editor_node = _create_node(
		index,
		_node_creation_mode,
		_last_popup_position
	)
	_set_dirty(true)
	perform_save()
	_refresh_anchor_maps()
	_populate_anchor_destinations()
	var connected_creation = _node_creation_mode == NodeCreationMode.CONNECTED
	if editor_node is EditorAnchorNodeClass and connected_creation:
		var from_node = _graph_edit.get_node(
			NodePath(_pending_connection_from)
		)
		from_node.set_destination(
			editor_node.node_resource.id
		)


func _create_node(
	node_type,
	node_creation_mode,
	editor_position,
	initial_state = {}
):
	var new_editor_node
	var new_graph_node
	
	var node_objects = _create_node_objects(node_type)
	new_editor_node = node_objects[0]
	new_graph_node = node_objects[1]
		
	_configure_graph_node_state(
		new_graph_node,
		initial_state,
		editor_position,
	)
	
	_graph_edit.add_child(new_editor_node)
	
	_configure_editor_node_state(
		new_editor_node,
		new_graph_node,
	)
	
	_edited.graph.nodes[new_graph_node.id] = new_graph_node
	if new_editor_node.is_root:
		_edited.graph.root_node = new_graph_node
	_connect_node_signals(new_editor_node)
	
	_connect_new_editor_node_if_necessary(
		new_editor_node,
		node_creation_mode,
	)
	return new_editor_node


func _get_default_dialogue_type():
	for t in _dialogue_types:
		if _edited.graph.graph_type in t['default_in_graph_types']:
			return t
	return null


func _create_node_objects(node_type):
	var new_editor_node
	var new_graph_node
	
	match node_type:
		GraphPopupMenuItems.ADD_TEXT_NODE:
			new_editor_node = EditorTextNode.instantiate()
			new_graph_node = DialogueTextNode.new()
			var default_dialogue_type = _get_default_dialogue_type()
			if default_dialogue_type != null:
				var ddtd = default_dialogue_type as Dictionary
				new_graph_node.dialogue_type = ddtd['name']
			new_graph_node.text_translation_key = TranslationKey.generate(
				_edited.graph.name,
				"dialogue",
			)
		GraphPopupMenuItems.ADD_BRANCH_NODE:
			new_editor_node = EditorBranchNode.instantiate()
			new_graph_node = BranchNode.new()
		GraphPopupMenuItems.ADD_CHOICE_NODE:
			new_editor_node = EditorChoiceNode.instantiate()
			new_graph_node = DialogueChoiceNode.new()
		GraphPopupMenuItems.ADD_SET_NODE:
			new_editor_node = EditorSetNode.instantiate()
			new_graph_node = VariableSetNode.new()
		GraphPopupMenuItems.ADD_ACTION_NODE:
			new_editor_node = EditorActionNode.instantiate()
			new_graph_node = ActionNode.new()
		GraphPopupMenuItems.ADD_SUB_GRAPH_NODE:
			new_editor_node = EditorSubGraphNode.instantiate()
			new_graph_node = SubGraph.new()
		GraphPopupMenuItems.ADD_RANDOM_NODE:
			new_editor_node = EditorRandomNode.instantiate()
			new_graph_node = RandomNode.new()
		GraphPopupMenuItems.ADD_COMMENT_NODE:
			new_editor_node = EditorCommentNode.instantiate()
			new_graph_node = CommentNode.new()
		GraphPopupMenuItems.ADD_JUMP_NODE:
			new_editor_node = EditorJumpNode.instantiate()
			new_graph_node = JumpNode.new()
		GraphPopupMenuItems.ADD_ANCHOR_NODE:
			new_editor_node = EditorAnchorNode.instantiate()
			new_graph_node = AnchorNode.new()
			new_graph_node.name = _generate_anchor_name()
		GraphPopupMenuItems.ADD_ROUTING_NODE:
			new_editor_node = EditorRoutingNode.instantiate()
			new_graph_node = RoutingNode.new()
		GraphPopupMenuItems.ADD_REPEAT_NODE:
			new_editor_node = EditorRepeatNode.instantiate()
			new_graph_node = RepeatNode.new()
	return [new_editor_node, new_graph_node]


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
	if _graph_edit.get_child_count() == 1:
		new_editor_node.is_root = true
	if new_editor_node.has_method("populate_characters"):
		new_editor_node.populate_characters(_edited.graph.characters)
	if new_editor_node.has_method("set_dialogue_types"):
		new_editor_node.set_dialogue_types(_dialogue_types)
	new_editor_node.configure_for_node(_edited.graph, new_graph_node)


func _connect_new_editor_node_if_necessary(
	new_editor_node,
	node_creation_mode
):
	if node_creation_mode == NodeCreationMode.CONNECTED:
		Logger.debug(
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


func _generate_anchor_name():
	return "%s%s" % [
		CutsceneGraph.NEW_ANCHOR_PREFIX,
		_edited.graph.get_next_anchor_number(),
	]


func _node_popup_index_pressed(index):
	match index:
		NodePopupMenuItems.SET_ROOT:
			_set_root(_node_for_popup)


func _set_root(node_name):
	for child in _graph_edit.get_children():
		if "is_root" in child:
			child.is_root = (child.name == node_name)
			if child.is_root:
				_edited.graph.root_node = child.node_resource
	_set_dirty(true)


func _removing_slot(slot, node_name):
	Logger.debug("Removal of slot %s on node %s requested" % [slot, node_name])
	var connections = _graph_edit.get_connection_list()
	for connection in connections:
		_process_connection_for_slot_removal(
			connection,
			slot,
			node_name,
		)
	_set_dirty(true)


func _process_connection_for_slot_removal(
	connection,
	slot,
	node_name
):
	if connection.from == node_name and connection.from_port == slot:
		# This one just gets removed
		_graph_edit.disconnect_node(
			connection.from,
			connection.from_port,
			connection.to,
			connection.to_port
		)
	elif connection.from == node_name and connection.from_port > slot:
		# Remove and reconnect to slot + 1
		_graph_edit.disconnect_node(
			connection.from,
			connection.from_port,
			connection.to,
			connection.to_port
		)
		_graph_edit.connect_node(
			connection.from,
			connection.from_port - 1,
			connection.to,
			connection.to_port
		)


func _node_close_request(node_name):
	_confirmation_action = ConfirmationActions.REMOVE_NODE
	_node_to_remove = node_name
	if not _node_to_remove is Array:
		_node_to_remove = [_node_to_remove]
	var nodes_text = "this node"
	if len(_node_to_remove) > 1:
		nodes_text = "these nodes"
	_confirmation_dialog.dialog_text = "Are you sure you want to remove %s? This action cannot be undone." % nodes_text
	_confirmation_dialog.popup_centered()


func _action_confirmed():
	match _confirmation_action:
		ConfirmationActions.REMOVE_NODE:
			_remove_nodes()
		ConfirmationActions.CLOSE_GRAPH:
			_close_graph()


func _remove_nodes():
	Logger.debug(
		"Removal of node(s) {nodes} confirmed.".format({
			"nodes": _node_to_remove
		})
	)
	var connections = _graph_edit.get_connection_list()
	for n in _node_to_remove:
		_remove_node(n, connections)
	_set_dirty(true)
	_refresh_anchor_maps()
	_populate_anchor_destinations()


func _remove_node(n, connections):
	# This line is throwing an error now - cannot convert from StringName to NodePath
	var node = _graph_edit.get_node(NodePath(n))
	var is_anchor = node is EditorAnchorNodeClass
	for connection in connections:
		if connection.from == n or connection.to == n:
			# This one just gets removed
			_remove_connection_for_node(
				connection,
				is_anchor,
			)
	
	_edited.graph.nodes.erase(node.node_resource.id)
	_graph_edit.remove_child(node)


func _remove_connection_for_node(connection, is_anchor):
	_graph_edit.disconnect_node(
		connection.from,
		connection.from_port,
		connection.to,
		connection.to_port
	)
	if is_anchor:
		var from_node = _graph_edit.get_node(
			NodePath(connection.from)
		)
		from_node.set_destination(-1)


func _graph_selection_changed(index):
	_update_edited_graph()
	_edited = _open_graphs[index]
	_draw_edited_graph()


func _on_save():
	if not _edited:
		return
		
	if _edited.path != null:
		perform_save()
	else:
		_get_resource_path()


func _on_open():
	_get_open_path()


func _sub_graph_selection_requested(node):
	_sub_graph_editor_node_for_assignment = node
	_get_sub_graph_open_path()


func _sub_graph_open_requested(graph, editor_node):
	edit_graph(graph, graph.resource_path)


func _on_close():
	if not _edited:
		return
	
	if _edited.dirty:
		_confirmation_dialog.dialog_text = "Unsaved changes will be lost. Are you sure you wish to continue?"
		_confirmation_action = ConfirmationActions.CLOSE_GRAPH
		_confirmation_dialog.popup_centered()
	else:
		_close_graph()


func _close_graph():
	_open_graphs.remove(
		_open_graphs.find(
			_edited
		)
	)
	if _open_graphs.size() > 0:
		_edited = _open_graphs[0]
	else:
		_edited = null
	_draw_edited_graph()


func perform_save():
	Logger.trace("perform_save()")
	if _edited == null:
		return
	
	_update_edited_graph()
	save_requested.emit(
		_edited.graph,
		_edited.path,
	)
	_set_dirty(false)


func _on_save_as():
	if _edited:
		_get_resource_path()


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
		
	_cutscene_name.text = _get_name(_edited.graph)

	# Now create and configure the display nodes
	for node in _edited.graph.nodes.values():
		var editor_node = _instantiate_editor_node_for_graph_node(node)
		
		_graph_edit.add_child(editor_node)
		editor_node.configure_for_node(_edited.graph, node)
		if node == _edited.graph.root_node:
			editor_node.is_root = true
		_connect_node_signals(editor_node)
		
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
		Logger.trace(
			"Restored scroll offset and zoom %s, %s from saved %s, %s" % [
				_graph_edit.scroll_offset,
				_graph_edit.zoom,
				_edited.scroll_offset,
				_edited.zoom
			]
		)


func _instantiate_editor_node_for_graph_node(node):
	var editor_node
	
	if node is DialogueTextNode:
		editor_node = EditorTextNode.instantiate()
		editor_node.populate_characters(_edited.graph.characters)
		editor_node.set_dialogue_types(_dialogue_types)
	elif node is BranchNode:
		editor_node = EditorBranchNode.instantiate()
	elif node is VariableSetNode:
		editor_node = EditorSetNode.instantiate()
	elif node is DialogueChoiceNode:
		editor_node = EditorChoiceNode.instantiate()
	elif node is ActionNode:
		editor_node = EditorActionNode.instantiate()
		editor_node.populate_characters(_edited.graph.characters)
	elif node is SubGraph:
		editor_node = EditorSubGraphNode.instantiate()
	elif node is RandomNode:
		editor_node = EditorRandomNode.instantiate()
	elif node is CommentNode:
		editor_node = EditorCommentNode.instantiate()
	elif node is JumpNode:
		editor_node = EditorJumpNode.instantiate()
		editor_node.populate_destinations(_anchor_names_by_id)
		#editor_node.set_destination(node.next)
	elif node is AnchorNode:
		editor_node = EditorAnchorNode.instantiate()
	elif node is RoutingNode:
		editor_node = EditorRoutingNode.instantiate()
	elif node is RepeatNode:
		editor_node = EditorRepeatNode.instantiate()
	
	return editor_node


func _create_connections_for_node(node):
	if node.next != -1:
		var from = _get_editor_node_for_graph_node(node)
		var to = _get_editor_node_for_graph_node(
			_edited.graph.nodes[node.next]
		)
		_graph_edit.connect_node(from.name, 0, to.name, 0)
	if node is BranchNode:
		var from = _get_editor_node_for_graph_node(node)
		for index in range(0, node.branches.size()):
			if node.branches[index]:
				var to = _get_editor_node_for_graph_node(
					_edited.graph.nodes[node.branches[index]]
				)
				_graph_edit.connect_node(from.name, index + 1, to.name, 0)
	elif node is RandomNode:
		var from = _get_editor_node_for_graph_node(node)
		for index in range(0, node.branches.size()):
			if node.branches[index].next != -1:
				var to = _get_editor_node_for_graph_node(
					_edited.graph.nodes[node.branches[index].next]
				)
				_graph_edit.connect_node(from.name, index + 1, to.name, 0)
	elif node is DialogueChoiceNode:
		var from = _get_editor_node_for_graph_node(node)
		for index in range(0, node.choices.size()):
			if node.choices[index].next != -1:
				var to = _get_editor_node_for_graph_node(
					_edited.graph.nodes[node.choices[index].next]
				)
				_graph_edit.connect_node(from.name, index + 1, to.name, 0)


func _connect_node_signals(node):
	node.removing_slot.connect(
		_removing_slot.bind(
			node.name
		)
	)
	node.close_request.connect(
		_node_close_request.bind(
			node.name
		)
	)
	node.popup_request.connect(
		_node_popup_request.bind(
			node.name
		)
	)
	node.position_offset_changed.connect(
		_node_offset_changed.bind(
			node.name
		)
	)
	node.modified.connect(
		_node_modified.bind(
			node.name
		)
	)
	if node is EditorSubGraphNodeClass:
		node.sub_graph_selection_requested.connect(
			_sub_graph_selection_requested.bind(
				node
			)
		)
		node.sub_graph_open_requested.connect(
			_sub_graph_open_requested.bind(
				node
			)
		)
	if node is EditorJumpNodeClass:
		node.destination_chosen.connect(
			_jump_node_destination_chosen.bind(
				node
			)
		)


func _jump_node_destination_chosen(destination_id, node):
	Logger.debug("Jump destination %s chosen for node %s" % [
		destination_id, node
	])
	node.node_resource.next = destination_id
	_draw_edited_graph(true)


func _node_modified(node_name):
	var editor_node = _graph_edit.get_node(NodePath(node_name))
	if editor_node != null:
		if editor_node is EditorAnchorNodeClass:
			_refresh_anchor_maps()
			_populate_anchor_destinations()
	perform_save()


func _populate_anchor_destinations():
	Logger.debug("Populating anchor destinations")
	for node in _edited.graph.nodes.values():
		if node is JumpNode:
			_get_editor_node_for_graph_node(node).populate_destinations(
				_anchor_names_by_id
			)


func _set_dirty(val):
	_edited.dirty = val


func _get_editor_node_for_graph_node(n):
	for node in _graph_edit.get_children():
		if node is EditorGraphNodeBaseClass:
			if node.node_resource == n:
				return node
	return null


func _get_graph_node_by_id(id):
	return _edited.graph.nodes.get(id)


func clear():
	_clear_displayed_graph()
	if _edited != null:
		_edited.graph.changed.disconnect(
			_edited_resource_changed
		)
	_edited = null


func _clear_displayed_graph():
	_graph_edit.clear_connections()
	var graph_nodes = _graph_edit.get_children()
	for node in graph_nodes:
		Logger.debug("Removing node %s" % node.name)
		_graph_edit.remove_child(node)
		node.queue_free()
	_cutscene_name.text = "None"


## Update the graph resources from the current state of the UI.
func _update_edited_graph():
	if _edited == null:
		return
	
	Logger.trace("_update_edited_graph(): %s" % _edited.graph.name)
	
	for node in _graph_edit.get_children():
		# Watch out! Not all graph edit children are actually our nodes!
		if node.has_method("persist_changes_to_node"):
			node.persist_changes_to_node()
			# Clobber all relationships - they will be recreated if they still exist
			node.clear_node_relationships()
	var connections = _graph_edit.get_connection_list()
	for connection in connections:
		_update_resource_graph_for_connection(connection)


func _update_resource_graph_for_connection(connection):
	var from = _graph_edit.get_node(NodePath(connection.from))
	var from_slot = connection.from_port
	var to = _graph_edit.get_node(NodePath(connection.to))
	var to_slot = connection.to_port
	var from_dialogue_node = from.node_resource
	var to_dialogue_node = to.node_resource
	if from_dialogue_node is BranchNode:
		if from_slot == 0:
			from_dialogue_node.next = to_dialogue_node.id
		else:
			from_dialogue_node.branches[from_slot - 1] = to_dialogue_node.id
	elif from_dialogue_node is RandomNode:
		if from_slot == 0:
			from_dialogue_node.next = to_dialogue_node.id
		else:
			from_dialogue_node.branches[from_slot - 1].next = to_dialogue_node.id
	elif from_dialogue_node is DialogueChoiceNode:
		if from_slot == 0:
			from_dialogue_node.next = to_dialogue_node.id
		else:
			from_dialogue_node.choices[from_slot - 1].next = to_dialogue_node.id
	else:
		from_dialogue_node.next = to_dialogue_node.id


func _update_node_characters():
	Logger.debug("Updating node characters")
	for node in _graph_edit.get_children():
		if node.has_method("populate_characters"):
			node.populate_characters(_edited.graph.characters)


func _get_name(graph):
	var display_name = graph.display_name
	var name = graph.name
	if name == null or name == "":
		name = "unnamed"
	if display_name == null or display_name == "":
		display_name = "Unnamed Cutscene"
	return "%s (%s)" % [display_name, name]


func _edited_resource_changed():
	Logger.debug("Graph resource changed")
	_update_node_characters()
	# Only want to do this if the type has actually changed
	if _edited.graph.graph_type != _current_graph_type:
		_current_graph_type = _edited.graph.graph_type
		_dialogue_types = _get_dialogue_types_for_graph_type(
			_current_graph_type
		)
		_draw_edited_graph(true)
	if _edited != null:
		_cutscene_name.text = _get_name(_edited.graph)
	else:
		_cutscene_name.text = "None"


func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	Logger.debug(
		"Connection request from %s, %s to %s, %s" % [
			from, from_slot, to, to_slot
		]
	)
	var connections = _graph_edit.get_connection_list()
	var allow = true
	for connection in connections:
		if connection.from == from and connection.from_port == from_slot:
			allow = false
			break
	if allow:
		_graph_edit.connect_node(from, from_slot, to, to_slot)
		# If the connection is from a jump node then we have to select the
		# correct anchor in its dropdown.
		var from_node = _graph_edit.get_node(NodePath(from))
		if from_node is EditorJumpNodeClass:
			var to_node = _graph_edit.get_node(NodePath(to))
			from_node.set_destination(to_node.node_resource.id)
		# I think setting the dirty flag is supposed to allow the save to be
		# actioned later, when switching away from the graph for example. But
		# that wasn't happening...
		_set_dirty(true)
		perform_save()


func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	Logger.debug(
		"Disconnection request from %s, %s to %s, %s" % [
			from, from_slot, to, to_slot
		]
	)
	_graph_edit.disconnect_node(from, from_slot, to, to_slot)
	# If the connection was from a jump node then we have to remove the
	# selection in its dropdown.
	var from_node = _graph_edit.get_node(NodePath(from))
	if from_node is EditorJumpNodeClass:
		from_node.set_destination(-1)
	_set_dirty(true)
	perform_save()


func _node_offset_changed(node_name):
	Logger.debug("Graph node offset changed")
	_set_dirty(true)
	perform_save()


func _on_graph_edit_end_node_move():
	Logger.debug("Graph node moved")
	_set_dirty(true)
	perform_save()


func _on_graph_edit_scroll_offset_changed(offset):
	if _edited == null:
		return
		
	_edited.zoom = _graph_edit.zoom
	_edited.scroll_offset = Vector2(_graph_edit.scroll_offset)
	# This would be debug but it is highly verbose
	Logger.trace(
		"Saved scroll offset and zoom: %s, %s" % [
			_edited.scroll_offset,
			_edited.zoom
		]
	)


func _convert_popup_position(release_position):
	# This works pretty well - node appears slightly below and to the right of the click location
	# so much like where a popup menu would appear. It was determined by trial and error.
	return (release_position / _graph_edit.zoom) + (_graph_edit.scroll_offset / _graph_edit.zoom)


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


func _set_graph_popup_option_states():
	match _node_creation_mode:
		NodeCreationMode.NORMAL:
			_set_all_graph_popup_disabled(false)
		NodeCreationMode.CONNECTED:
			_set_graph_popup_option_states_for_connected_creation()


func _set_graph_popup_option_states_for_connected_creation():
	Logger.debug("Pending connection from: %s" % _pending_connection_from)
	var from_node = _graph_edit.get_node(NodePath(_pending_connection_from))
	if from_node.get_connection_output_type(
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


func _set_all_graph_popup_disabled(state):
	# TODO: Not great to use the current first and last elements here.
	for option in range(
		GraphPopupMenuBounds.LOWER_BOUND,
		GraphPopupMenuBounds.UPPER_BOUND + 1
	):
		_graph_popup.set_item_disabled(option, state)


func _on_graph_edit_copy_nodes_request():
	var copied_nodes = _get_selected_nodes()
	_copied_nodes = _get_node_states(copied_nodes)
	_scroll_on_copy = {
		"offset": _graph_edit.scroll_offset,
		"zoom": _graph_edit.zoom
	}


func _get_selected_nodes():
	var selected_nodes = []
	for node in _graph_edit.get_children():
		if node.selected:
			selected_nodes.append(node)
	return selected_nodes


func _on_graph_edit_paste_nodes_request():
	if _copied_nodes != null:
		_paste_nodes(_copied_nodes)


func _create_duplicate_nodes(nodes_to_duplicate):
	var new_nodes = {}
	for n in nodes_to_duplicate:
		var node_state = _get_node_state(n)
		var duplicated_node = _create_node(
			node_state["_node_type"],
			NodeCreationMode.DUPLICATION,
			n.position_offset + Vector2(150, 150),
			node_state
		)
		new_nodes[node_state["_original_id"]] = duplicated_node
	
	_create_connections_for_copied_nodes(new_nodes)
	_refresh_anchor_maps()
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
		var pasted_node = _create_node(
			n["_node_type"],
			NodeCreationMode.PASTE,
			n["offset"] + Vector2(200, 200),
			n
		)
		new_nodes[n["_original_id"]] = pasted_node
	
	_create_connections_for_copied_nodes(new_nodes)
	_refresh_anchor_maps()
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
				Logger.debug(
					"Updating next link for copied node %s from %s to %s" % [
						pasted_res.id, pasted_res.next, id
					]
				)
				# Update to the new id.
				pasted_res.next = id
				
			if "branches" in pasted_res:
				for b in range(len(pasted_res.branches)):
					if pasted_res.branches[b] == original_id:
						Logger.debug(
							"Updating branch link for copied node %s from %s to %s" % [
								pasted_res.id, original_id, id
							]
						)
						pasted_res.branches[b] = id
			elif "choices" in pasted_res:
				for b in range(len(pasted_res.choices)):
					if pasted_res.choices[b].next == original_id:
						Logger.debug(
							"Updating choice link for copied node %s from %s to %s" % [
								pasted_res.id, original_id, id
							]
						)
						pasted_res.choices[b].next = id


func _deselect_all():
	for node in _graph_edit.get_children():
		node.selected = false


func _select_nodes(nodes):
	for node in nodes:
		node.selected = true


# TODO: The enum used here is now misnamed or inappropriate.
func _node_type_for_node(node):
	if node is EditorActionNodeClass:
		return GraphPopupMenuItems.ADD_ACTION_NODE
	elif node is EditorBranchNodeClass:
		return GraphPopupMenuItems.ADD_BRANCH_NODE
	elif node is EditorTextNodeClass:
		return GraphPopupMenuItems.ADD_TEXT_NODE
	elif node is EditorSetNodeClass:
		return GraphPopupMenuItems.ADD_SET_NODE
	elif node is EditorSubGraphNodeClass:
		return GraphPopupMenuItems.ADD_SUB_GRAPH_NODE
	elif node is EditorChoiceNodeClass:
		return GraphPopupMenuItems.ADD_CHOICE_NODE
	elif node is EditorRandomNodeClass:
		return GraphPopupMenuItems.ADD_RANDOM_NODE
	elif node is EditorCommentNodeClass:
		return GraphPopupMenuItems.ADD_COMMENT_NODE
	elif node is EditorJumpNodeClass:
		return GraphPopupMenuItems.ADD_JUMP_NODE
	elif node is EditorAnchorNodeClass:
		return GraphPopupMenuItems.ADD_ANCHOR_NODE
	elif node is EditorRoutingNodeClass:
		return GraphPopupMenuItems.ADD_ROUTING_NODE
	elif node is EditorRepeatNodeClass:
		return GraphPopupMenuItems.ADD_REPEAT_NODE
	return GraphPopupMenuItems.ADD_TEXT_NODE


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


## Deep copies arrays and dictionaries. Just returns anything else.
func _deep_copy(obj):
	if obj == null:
		return obj
	if obj is Array or obj is Dictionary:
		return obj.duplicate(true)
	return obj


func _on_graph_edit_duplicate_nodes_request():
	_create_duplicate_nodes(
		_get_selected_nodes()
	)


func _on_expand_button_toggled(button_pressed):
	expand_button_toggled.emit(button_pressed)

@tool
extends VBoxContainer

signal save_requested(object, path)

const Logging = preload("../scripts/Logging.gd")

const DialogueTextNode = preload("../resources/DialogueTextNode.gd")
const BranchNode = preload("../resources/BranchNode.gd")
const DialogueChoiceNode = preload("../resources/DialogueChoiceNode.gd")
const VariableSetNode = preload("../resources/VariableSetNode.gd")
const ActionNode = preload("../resources/ActionNode.gd")
const SubGraph = preload("../resources/SubGraph.gd")
const RandomNode = preload("../resources/RandomNode.gd")

const EditorTextNodeClass = preload("./EditorTextNode.gd")
const EditorBranchNodeClass = preload("./EditorBranchNode.gd")
const EditorChoiceNodeClass = preload("./EditorChoiceNode.gd")
const EditorSetNodeClass = preload("./EditorSetNode.gd")
const EditorGraphNodeBaseClass = preload("./EditorGraphNodeBase.gd")
const EditorActionNodeClass = preload("./EditorActionNode.gd")
const EditorSubGraphNodeClass = preload("./EditorSubGraphNode.gd")
const EditorRandomNodeClass = preload("./EditorRandomNode.gd")

const EditorTextNode = preload("../scenes/EditorTextNode.tscn")
const EditorBranchNode = preload("../scenes/EditorBranchNode.tscn")
const EditorChoiceNode = preload("../scenes/EditorChoiceNode.tscn")
const EditorSetNode = preload("../scenes/EditorSetNode.tscn")
const EditorGraphNodeBase = preload("../scenes/EditorGraphNodeBase.tscn")
const EditorActionNode = preload("../scenes/EditorActionNode.tscn")
const EditorSubGraphNode = preload("../scenes/EditorSubGraphNode.tscn")
const EditorRandomNode = preload("../scenes/EditorRandomNode.tscn")

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
	ADD_RANDOM_NODE
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
	CONNECTED
}

var _open_graphs

var _edited

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

var _last_popup_position
var _pending_connection_from
var _pending_connection_from_port
var _node_creation_mode
var _confirmation_action
var _node_to_remove
var _node_for_popup
var _sub_graph_editor_node_for_assignment

var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

func _init():
	_open_graphs = Array()


func _ready():
	# Set up editor
	_graph_edit.connect("popup_request", Callable(self, "_graph_popup_requested"))
	
	# Refresh the graph when we receive input focus, in case the resource
	# has been changed externally
	_graph_edit.connect("focus_entered", Callable(self, "_edited_resource_changed"))
	
	_graph_edit.gui_input.connect(_graph_gui_input)

	# Context menu
	_graph_popup.connect("index_pressed", Callable(self, "_graph_popup_index_pressed"))
	_graph_popup.popup_hide.connect(_graph_popup_hidden)
	_node_popup.connect("index_pressed", Callable(self, "_node_popup_index_pressed"))

	# Confirmation dialog
	_confirmation_dialog.connect("confirmed", Callable(self, "_action_confirmed"))

	# Set up save dialog
	_save_dialog = EditorFileDialog.new()
	_save_dialog.add_filter("*.tres")
	_save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_save_dialog.mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	self.add_child(_save_dialog)
	_save_dialog.connect("file_selected", Callable(self, "_file_selected"))

	# Set up Open dialogs
	_open_graph_dialog = EditorFileDialog.new()
	_open_graph_dialog.add_filter("*.tres")
	_open_graph_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_open_graph_dialog.mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	self.add_child(_open_graph_dialog)
	_open_graph_dialog.connect("file_selected", Callable(self, "_graph_file_selected_for_opening"))

	_open_sub_graph_dialog = EditorFileDialog.new()
	_open_sub_graph_dialog.add_filter("*.tres")
	_open_sub_graph_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_open_sub_graph_dialog.mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	self.add_child(_open_sub_graph_dialog)
	_open_sub_graph_dialog.connect("file_selected", Callable(self, "_sub_graph_file_selected_for_opening"))

	# TODO: I think this is not required any more...
	_open_character_dialog = EditorFileDialog.new()
	_open_character_dialog.add_filter("*.tres")
	_open_character_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_open_character_dialog.mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	self.add_child(_open_character_dialog)
	_open_character_dialog.connect("file_selected", Callable(self, "_character_file_selected_for_opening"))


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
		_edited.graph.disconnect("changed", Callable(self, "_edited_resource_changed"))
	_edited = edited
	_edited.graph.connect("changed", Callable(self, "_edited_resource_changed"))
	_draw_edited_graph()


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
		var global_rect = get_global_rect()
		_last_popup_position = _convert_popup_position(p_position)
		_graph_popup.position = get_screen_transform() * p_position
		_graph_popup.popup()


func _graph_popup_hidden():
	Logger.debug("Hiding graph popup")


func _graph_gui_input(event: InputEvent):
	pass


func _node_popup_request(p_position, node_name):
	_node_for_popup = node_name
	_node_popup.position = p_position
	_node_popup.popup()


func _graph_popup_index_pressed(index):
	var new_editor_node
	var new_graph_node
	match index:
		GraphPopupMenuItems.ADD_TEXT_NODE:
			new_editor_node = EditorTextNode.instantiate()
			new_graph_node = DialogueTextNode.new()
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
	new_graph_node.id = _edited.graph.get_next_id()
	new_graph_node.offset = _last_popup_position
	_graph_edit.add_child(new_editor_node)
	if _graph_edit.get_child_count() == 1:
		new_editor_node.is_root = true
	if new_editor_node.has_method("populate_characters"):
		new_editor_node.populate_characters(_edited.graph.characters)
	new_editor_node.configure_for_node(new_graph_node)
	_edited.graph.nodes[new_graph_node.id] = new_graph_node
	if new_editor_node.is_root:
		_edited.graph.root_node = new_graph_node
	_connect_node_signals(new_editor_node)
	if _node_creation_mode == NodeCreationMode.CONNECTED:
		Logger.debug("Auto-connecting new node from %s, %s" % [_pending_connection_from, _pending_connection_from_port])
		_graph_edit.emit_signal(
			"connection_request",
			_pending_connection_from,
			_pending_connection_from_port,
			new_editor_node.name,
			0
		)
	_set_dirty(true)
	perform_save()


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
		if connection.from == node_name and connection.from_port == slot:
			# This one just gets removed
			_graph_edit.disconnect_node(connection.from, connection.from_port, connection.to, connection.to_port)
		elif connection.from == node_name and connection.from_port > slot:
			# Remove and reconnect to slot + 1
			_graph_edit.disconnect_node(connection.from, connection.from_port, connection.to, connection.to_port)
			_graph_edit.connect_node(connection.from, connection.from_port - 1, connection.to, connection.to_port)
	_set_dirty(true)


func _node_close_request(node_name):
	_confirmation_action = ConfirmationActions.REMOVE_NODE
	_node_to_remove = node_name
	var nodes_text = "this node"
	if _node_to_remove is Array:
		nodes_text = "these nodes"
	_confirmation_dialog.dialog_text = "Are you sure you want to remove %s? This action cannot be undone." % nodes_text
	_confirmation_dialog.popup_centered()


func _action_confirmed():
	match _confirmation_action:
		ConfirmationActions.REMOVE_NODE:
			if not _node_to_remove is Array:
				_node_to_remove = [_node_to_remove]
			Logger.debug(
				"Removal of node(s) {nodes} confirmed.".format({
					"nodes": _node_to_remove
				})
			)
			var connections = _graph_edit.get_connection_list()
			for n in _node_to_remove:
				for connection in connections:
					if connection.from == n or connection.to == n:
						# This one just gets removed
						_graph_edit.disconnect_node(connection.from, connection.from_port, connection.to, connection.to_port)
				# This line is throwing an error now - cannot convert from StringName to NodePath
				var node = _graph_edit.get_node(NodePath(n))
				_edited.graph.nodes.erase(node.node_resource.id)
				_graph_edit.remove_child(node)
			_set_dirty(true)
		ConfirmationActions.CLOSE_GRAPH:
			_close_graph()


func _graph_selection_changed(index):
	_update_edited_graph()
	_edited = _open_graphs[index]
	_draw_edited_graph()


func _on_save():
	if _edited:
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
	if _edited:
		if _edited.dirty:
			_confirmation_dialog.dialog_text = "Unsaved changes will be lost. Are you sure you wish to continue?"
			_confirmation_action = ConfirmationActions.CLOSE_GRAPH
			_confirmation_dialog.popup_centered()
		else:
			_close_graph()


func _close_graph():
	_open_graphs.remove(_open_graphs.find(_edited))
	if _open_graphs.size() > 0:
		_edited = _open_graphs[0]
	else:
		_edited = null
	_draw_edited_graph()


func perform_save():
	Logger.trace("perform_save()")
	if _edited != null:
		_update_edited_graph()
		emit_signal("save_requested", _edited.graph, _edited.path)
		_set_dirty(false)


func _on_save_as():
	if _edited:
		_get_resource_path()


func _draw_edited_graph():
	"""
	Updated the UI to reflect changes in the underlying graph resource
	"""
	# Clear the existing graph
	_clear_displayed_graph()

	if _edited != null:
		_cutscene_name.text = _get_name(_edited.graph)

		# Now create and configure the display nodes
		for node in _edited.graph.nodes.values():
			var editor_node
			if node is DialogueTextNode:
				editor_node = EditorTextNode.instantiate()
				editor_node.populate_characters(_edited.graph.characters)
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
			_graph_edit.add_child(editor_node)
			editor_node.configure_for_node(node)
			if node == _edited.graph.root_node:
				editor_node.is_root = true
			_connect_node_signals(editor_node)

		# Second pass to create connections
		for node in _edited.graph.nodes.values():
			if node.next != -1:
				var from = _get_editor_node_for_graph_node(node)
				var to = _get_editor_node_for_graph_node(
					_edited.graph.nodes[node.next]
				)
				_graph_edit.connect_node(from.name, 0, to.name, 0)
			if node is DialogueChoiceNode or node is BranchNode or node is RandomNode:
				var from = _get_editor_node_for_graph_node(node)
				for index in range(0, node.branches.size()):
					if node.branches[index]:
						var to = _get_editor_node_for_graph_node(
							_edited.graph.nodes[node.branches[index]]
						)
						_graph_edit.connect_node(from.name, index + 1, to.name, 0)
		
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


func _connect_node_signals(node):
	node.connect("removing_slot", Callable(self, "_removing_slot").bind(node.name))
	node.connect("close_request", Callable(self, "_node_close_request").bind(node.name))
	node.connect("popup_request", Callable(self, "_node_popup_request").bind(node.name))
	node.connect("position_offset_changed", Callable(self, "_node_offset_changed").bind(node.name))
	node.connect("modified", Callable(self, "_node_modified").bind(node.name))
	if node is EditorSubGraphNodeClass:
		node.connect("sub_graph_selection_requested", Callable(self, "_sub_graph_selection_requested").bind(node))
		node.connect("sub_graph_open_requested", Callable(self, "_sub_graph_open_requested").bind(node))


func _node_modified(node):
	perform_save()


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
		_edited.graph.disconnect("changed", Callable(self, "_edited_resource_changed"))
	_edited = null


func _clear_displayed_graph():
	_graph_edit.clear_connections()
	var graph_nodes = _graph_edit.get_children()
	for node in graph_nodes:
		Logger.debug("Removing node %s" % node.name)
		_graph_edit.remove_child(node)
		node.queue_free()
	_cutscene_name.text = "None"


func _update_edited_graph():
	"""
	Update the graph resources from the current state of the UI.
	"""
	if _edited != null:
		Logger.trace("_update_edited_graph(): %s" % _edited.graph.name)
		
		for node in _graph_edit.get_children():
			# Watch out! Not all graph edit children are actually our nodes!
			if node.has_method("persist_changes_to_node"):
				node.persist_changes_to_node()
				# Clobber all relationships - they will be recreated if they still exist
				node.clear_node_relationships()
		var connections = _graph_edit.get_connection_list()
		for connection in connections:
			var from = _graph_edit.get_node(NodePath(connection.from))
			var from_slot = connection.from_port
			var to = _graph_edit.get_node(NodePath(connection.to))
			var to_slot = connection.to_port
			var from_dialogue_node = from.node_resource
			var to_dialogue_node = to.node_resource
			if from_dialogue_node is DialogueTextNode or from_dialogue_node is VariableSetNode or from_dialogue_node is ActionNode or from_dialogue_node is SubGraph:
				from_dialogue_node.next = to_dialogue_node.id
			elif from_dialogue_node is DialogueChoiceNode or from_dialogue_node is BranchNode or from_dialogue_node is RandomNode:
				if from_slot == 0:
					from_dialogue_node.next = to_dialogue_node.id
				else:
					from_dialogue_node.branches[from_slot - 1] = to_dialogue_node.id


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
	_update_node_characters()
	if _edited != null:
		_cutscene_name.text = _get_name(_edited.graph)
	else:
		_cutscene_name.text = "None"


func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	Logger.debug("Connection request from %s, %s to %s, %s" % [from, from_slot, to, to_slot])
	var connections = _graph_edit.get_connection_list()
	var allow = true
	for connection in connections:
		if connection.from == from and connection.from_port == from_slot:
			allow = false
			break
	if allow:
		_graph_edit.connect_node(from, from_slot, to, to_slot)
		# I think setting the dirty flag is supposed to allow the save to be
		# actioned later, when switching away from the graph for example. But
		# that wasn't happening...
		_set_dirty(true)
		perform_save()


func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	Logger.debug("Disconnection request from %s, %s to %s, %s" % [from, from_slot, to, to_slot])
	_graph_edit.disconnect_node(from, from_slot, to, to_slot)
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
	if _edited != null:
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
	# so much like where a popup menu would appear.
	return (release_position / _graph_edit.zoom) + (_graph_edit.scroll_offset / _graph_edit.zoom)


func _on_graph_edit_connection_to_empty(from_node, from_port, release_position):
	if _edited:
		_node_creation_mode = NodeCreationMode.CONNECTED
		_pending_connection_from = from_node
		_pending_connection_from_port = from_port
		var global_rect = get_global_rect()
		_last_popup_position = _convert_popup_position(release_position)
		_graph_popup.position = get_screen_transform() * release_position
		_graph_popup.popup()

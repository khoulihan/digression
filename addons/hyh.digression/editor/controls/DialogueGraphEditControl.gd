@tool
extends GraphEdit


signal graph_modified
signal display_filesystem_path_requested(path: String)
signal sub_graph_edit_requested(graph: DigressionDialogueGraph, path: String)
signal sub_graph_save_as_requested(graph: DigressionDialogueGraph)
signal node_maximise_requested(node_resource: GraphNodeBase)
signal anchor_node_selected(name: String)
# TODO: Not sure we even want to be raising this really - the parent could
# perform the save when receiving the graph_modified signal, no?
signal save_requested
# TODO: Probably need a signal for popup menus.


enum ConnectionTypes {
	NORMAL,
	JUMP,
}

enum NodeCreationMode {
	NORMAL,
	CONNECTED,
	DUPLICATION,
	PASTE
}


const AnchorManager = preload("../open_graphs/AnchorManager.gd")
const OpenGraph = preload("../open_graphs/OpenGraph.gd")

# Utility classes.
const Dialogs = preload("../dialogs/Dialogs.gd")
const DigressionSettings = preload("../../settings/DigressionSettings.gd")
const Logging = preload("../../utility/Logging.gd")
const TranslationKey = preload("../../utility/TranslationKey.gd")
const DigressionTheme = preload("../themes/DigressionTheme.gd")

# Resource graph nodes.
const GraphNodeBase = preload("../../resources/graph/GraphNodeBase.gd")
const DialogueNode = preload("../../resources/graph/DialogueNode.gd")
const DialogueChoiceNode = preload("../../resources/graph/DialogueChoiceNode.gd")
const AnchorNode = preload("../../resources/graph/AnchorNode.gd")

# Editor node classes.
const EditorGraphNodeBase = preload("../nodes/EditorGraphNodeBase.gd")
const EditorSubGraphNode = preload("../nodes/EditorSubGraphNode.gd")
const EditorJumpNode = preload("../nodes/EditorJumpNode.gd")
const EditorAnchorNode = preload("../nodes/EditorAnchorNode.gd")
const EditorEntryPointAnchorNode = preload("../nodes/EditorEntryPointAnchorNode.gd")

const GraphNodeFactory = preload("../factories/GraphNodeFactory.gd")
const GraphNodeTypes = GraphNodeFactory.GraphNodeTypes

const GraphPopupMenu = preload("./GraphPopupMenu.gd")
const GraphPopupMenuItems = GraphPopupMenu.GraphPopupMenuItems
const GraphPopupMenuBounds = GraphPopupMenu.GraphPopupMenuBounds
const GraphPopupMenuPromise = preload("../promises/GraphPopupMenuPromise.gd")
const PromiseState = GraphPopupMenuPromise.PromiseState


# TODO: Should maybe just construct this in code instead of accepting it from outside.
# Or make it a child?
@export var graph_popup: GraphPopupMenu


var _logger := Logging.get_editor_logger()

# Anchor manager
var _anchor_manager: AnchorManager

# Node factory
var _node_factory: GraphNodeFactory

# TODO: Not really sure how this works anymore... Does it need to be provided by parent?
var _resource_clipboard: ResourceClipboard

var _edited: OpenGraph
var _current_graph_type: String


# TODO: Replace with clipboard object.
# Copy & paste
var _copied_nodes
var _scroll_on_copy


func _init():
	_node_factory = GraphNodeFactory.new()
	ProjectSettings.settings_changed.connect(_on_settings_changed)


func _ready() -> void:
	# Create clipboard
	_resource_clipboard = ResourceClipboard.new()


#region Public interface

## Configure the interface for the provided AnchorManager.
func configure(manager: AnchorManager) -> void:
	_anchor_manager = manager


## Edit the specified graph.
func edit_graph(graph: OpenGraph):
	update_edited_graph()

	if _edited != null:
		_edited.graph.changed.disconnect(
			_on_edited_resource_changed
		)
	_edited = graph
	_current_graph_type = _edited.graph.graph_type
	_edited.graph.changed.connect(
		_on_edited_resource_changed
	)
	_draw_edited_graph()


## Update the graph resources from the current state of the UI.
func update_edited_graph():
	if _edited == null:
		return
	
	_logger.trace("_update_edited_graph(): %s" % _edited.graph.name)
	
	for node in _get_graph_edit_children():
		node.persist_changes_to_node()
		# Clobber all relationships - they will be recreated if they still exist
		node.clear_node_relationships()
	var connections = self.get_connection_list()
	for connection in connections:
		_update_resource_graph_for_connection(connection)


func clear() -> void:
	_clear_displayed_graph()


# TODO: Not sure we even want to be doing this here really.
## Save the currently edited graph.
func perform_save():
	_logger.trace("perform_save()")
	if _edited == null:
		return
	
	update_edited_graph()
	save_requested.emit()
	_set_dirty(false)


## Find the editor node corresponding to the provided resource node
## and update it.
func update_node(resource_node: GraphNodeBase) -> void:
	var editor_node = _get_editor_node_for_graph_node(resource_node)
	editor_node.configure_for_node(_edited, resource_node)


func redraw(retain_selection: bool = false) -> void:
	_draw_edited_graph(retain_selection)


func remove_node(resource_node: GraphNodeBase) -> void:
	# TODO: How is this used? Does it need to check if the node is entry point?
	# Seems it is used by the maximised node editor when close is selected for that.
	var editor_node = _get_editor_node_for_graph_node(resource_node)
	_remove_nodes([editor_node.name])


func focus_anchor(name: String) -> void:
	var anchor := _anchor_manager.get_anchor_by_name(name)
	var node = _get_editor_node_for_graph_node(_get_graph_node_by_id(anchor.id))
	self.set_selected(node)
	# TODO: Generalise this for focusing on any given position.
	var offset_to_node = (node.position_offset * self.zoom)
	var centre_to_node = (self.size / 2.0)
	var centre_node = ((node.size * self.zoom) / 2.0)
	self.scroll_offset = offset_to_node - centre_to_node + centre_node


func restore_scroll_offset(scroll_offset: Vector2, zoom: float) -> void:
	self.zoom = zoom
	# This was a deferred set previously, not sure why. It didn't seem
	# like it was actually being called.
	#_graph_edit.set_deferred("scroll_offset", _edited.scroll_offset)
	self.scroll_offset = Vector2(scroll_offset)

#endregion

#region Graph drawing, editing and saving

func _create_new_node_and_add(
	node_type: GraphNodeTypes,
	node_creation_mode: NodeCreationMode,
	editor_position: Vector2,
	initial_state = {},
	pending_connection_from: Variant = null,
	pending_connection_from_port: Variant = null
) -> GraphNode:
	var new_graph_node := _initialise_graph_node(
		_node_factory.create_graph_node(node_type)
	)
	_configure_graph_node_state(
		new_graph_node,
		initial_state,
		editor_position,
	)
	
	var new_editor_node := _instantiate_editor_node_and_add(new_graph_node)
	
	_edited.graph.nodes[new_graph_node.id] = new_graph_node
	
	_anchor_manager.configure(_edited.graph)
	_populate_anchor_destinations()
	
	if pending_connection_from != null:
		self.connect_node(
			pending_connection_from,
			pending_connection_from_port,
			new_editor_node.name,
			0
		)
	return new_editor_node


func _initialise_graph_node(node: GraphNodeBase) -> GraphNodeBase:
	if node is DialogueNode:
		var n := node as DialogueNode
		_set_default_dialogue_type_for_node(n)
		n.set_initial_translation_key(
			TranslationKey.generate(
				_edited.graph.name,
				"dialogue",
			)
		)
	elif node is DialogueChoiceNode:
		var n := node as DialogueChoiceNode
		_set_default_dialogue_type_for_node(n.dialogue)
		_set_default_choice_type_for_node(n)
		n.dialogue.set_initial_translation_key(
			TranslationKey.generate(
				_edited.graph.name,
				"choicedialogue",
			)
		)
	elif node is AnchorNode:
		var n := node as AnchorNode
		n.name = _generate_anchor_name()
	return node


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
	new_editor_node.configure_for_node(_edited, new_graph_node)


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
		self.disconnect_node(
			from_node,
			from_port,
			to_node,
			to_port
		)
	elif from_node == node_name and from_port > slot:
		# Remove and reconnect to slot + 1
		self.disconnect_node(
			from_node,
			from_port,
			to_node,
			to_port
		)
		self.connect_node(
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
	var connections = self.get_connection_list()
	for n in nodes:
		_remove_node(n, connections)
	_set_dirty(true)
	_anchor_manager.configure(_edited.graph)
	_populate_anchor_destinations()


func _remove_node(n, connections):
	# This line is throwing an error now - cannot convert from StringName to NodePath
	var node = self.get_node(NodePath(n))
	for connection in connections:
		if connection["from_node"] == n or connection["to_node"] == n:
			# This one just gets removed
			_remove_connection_for_node(
				connection,
			)
	
	if node.node_resource == _edited.graph.root_node:
		_edited.graph.root_node = null
	_edited.graph.nodes.erase(node.node_resource.id)
	self.remove_child(node)


func _remove_connection_for_node(connection):
	var from_node_name = connection["from_node"]
	var from_port = connection["from_port"]
	self.disconnect_node(
		from_node_name,
		from_port,
		connection["to_node"],
		connection["to_port"]
	)
	var from_node = self.get_node(
		NodePath(from_node_name)
	)
	from_node.disconnected.emit(from_port)


## Update the UI to reflect changes in the underlying graph resource
func _draw_edited_graph(retain_selection: bool = false):
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


func _instantiate_editor_node_and_add(graph_node: GraphNodeBase) -> EditorGraphNodeBase:
	var editor_node := _initialise_editor_node(
		_node_factory.instantiate_editor_node_for_graph_node(graph_node)
	)
	
	self.add_child(editor_node)
	_configure_editor_node_state(editor_node, graph_node)
	if graph_node == _edited.graph.root_node:
		editor_node.is_root = true
	_connect_node_signals(editor_node)
	return editor_node


func _initialise_editor_node(editor_node: EditorGraphNodeBase) -> EditorGraphNodeBase:
	editor_node.theme = DigressionTheme.get_theme()
	return editor_node


func _populate_dependencies(editor_node: EditorGraphNodeBase) -> void:
	if editor_node.has_method('populate_characters'):
		editor_node.populate_characters(_edited.graph.characters)
	if editor_node.has_method('set_dialogue_types'):
		editor_node.set_dialogue_types(_edited.dialogue_types)
	if editor_node.has_method('set_choice_types'):
		editor_node.set_choice_types(_edited.choice_types)
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
		self.connect_node(
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
	var connections_list = self.get_connection_list()
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
		self.disconnect_node(
			connection['from_node'],
			connection['from_port'],
			connection['to_node'],
			connection['to_port']
		)


func _is_connected(node_id: int) -> bool:
	return node_id != -1


func _set_dirty(val):
	_edited.dirty = val
	graph_modified.emit()


func _get_editor_node_for_graph_node(n):
	for node in _get_graph_edit_children():
		if node is EditorGraphNodeBase:
			if node.node_resource == n:
				return node
	return null


func _get_graph_node_by_id(id):
	return _edited.graph.nodes.get(id)


func _clear_displayed_graph():
	self.clear_connections()
	var graph_nodes = _get_graph_edit_children()
	for node in graph_nodes:
		_logger.debug("Removing node %s" % node.name)
		self.remove_child(node)
		node.queue_free()


func _update_resource_graph_for_connection(connection):
	var from = self.get_node(NodePath(connection["from_node"]))
	var from_slot = connection["from_port"]
	var to = self.get_node(NodePath(connection["to_node"]))
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


#region Graph edit signal handlers

func _on_connection_request(from, from_slot, to, to_slot):
	_logger.debug(
		"Connection request from %s, %s to %s, %s" % [
			from, from_slot, to, to_slot
		]
	)
	var connections = self.get_connection_list()
	for connection in connections:
		if connection["from_node"] == from and connection["from_port"] == from_slot:
			# We only allow one outgoing connection from any port.
			return

	self.connect_node(from, from_slot, to, to_slot)
	var from_node = self.get_node(NodePath(from))
	var to_node = self.get_node(NodePath(to))
	# TODO: Cheeky. Should call a method not invoke the signal directly.
	from_node.connected_to_node.emit(
		from_slot,
		to_node.node_resource.id,
	)
	# I think setting the dirty flag is supposed to allow the save to be
	# actioned later, when switching away from the graph for example. But
	# that wasn't happening...
	_set_dirty(true)
	perform_save()


func _on_disconnection_request(from, from_slot, to, to_slot):
	_logger.debug(
		"Disconnection request from %s, %s to %s, %s" % [
			from, from_slot, to, to_slot
		]
	)
	self.disconnect_node(from, from_slot, to, to_slot)
	var from_node = self.get_node(NodePath(from))
	from_node.disconnected.emit(from_slot)
	_set_dirty(true)
	perform_save()


func _on_end_node_move():
	_logger.debug("Graph node moved")
	_set_dirty(true)
	perform_save()


func _on_scroll_offset_changed(offset):
	if _edited == null:
		return
		
	_edited.zoom = self.zoom
	_edited.scroll_offset = Vector2(self.scroll_offset)
	# This would be debug but it is highly verbose
	_logger.trace(
		"Saved scroll offset and zoom: %s, %s" % [
			_edited.scroll_offset,
			_edited.zoom
		]
	)


# TODO: Could action this as a copy and immediate paste?
# I suppose it might not be expected that the clipboard would be overwritten.
func _on_duplicate_nodes_request():
	_create_duplicate_nodes(
		_get_selected_nodes()
	)


func _on_copy_nodes_request():
	# TODO: Should have a clipboard object for this state.
	var copied_nodes = _get_selected_nodes()
	_copied_nodes = _get_node_states(copied_nodes)
	_scroll_on_copy = {
		"offset": self.scroll_offset,
		"zoom": self.zoom
	}


func _on_paste_nodes_request():
	if _copied_nodes != null:
		_paste_nodes(_copied_nodes)


func _on_connection_to_empty(from_node, from_port, release_position):
	if not _edited:
		return
		
	_display_graph_popup(
		release_position,
		NodeCreationMode.CONNECTED,
		from_node,
		from_port
	)


func _on_popup_request(p_position):
	if not _edited:
		return

	_display_graph_popup(
		p_position,
		NodeCreationMode.NORMAL
	)


func _display_graph_popup(
	popup_position: Vector2,
	mode: NodeCreationMode,
	from_node: Variant = null,
	from_port: Variant = null
) -> void:
	var converted_popup_position := _convert_popup_position(popup_position)
	graph_popup.position = get_screen_transform() * popup_position
	_set_graph_popup_option_states(
		mode,
		from_node,
		from_port
	)
	var popup_promise := GraphPopupMenuPromise.new(graph_popup)
	graph_popup.popup()
	await popup_promise.completed
	if popup_promise.state == PromiseState.FULFILLED:
		_handle_create_node_request(
			mode,
			popup_promise.value,
			converted_popup_position,
			from_node,
			from_port
		)

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
# TODO: A lot of overlap though, I'm sure this could be streamlined.
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
	initial_state["_node_type"] = _node_factory.get_node_type(node)
	# Required for duplicating the connections
	initial_state["_original_id"] = graph_node.id
	
	return initial_state

#endregion


# TODO: Want to move this stuff to the OpenGraphManager
#region Dialogue and choice types

func _set_default_dialogue_type_for_node(new_graph_node: GraphNodeBase) -> void:
	var default_dialogue_type = _edited.get_default_dialogue_type()
	if default_dialogue_type != null:
		var ddtd = default_dialogue_type as Dictionary
		new_graph_node.dialogue_type = ddtd['name']


func _set_default_choice_type_for_node(new_graph_node: GraphNodeBase) -> void:
	var default_choice_type = _edited.get_default_choice_type()
	if default_choice_type != null:
		var dctd = default_choice_type as Dictionary
		new_graph_node.choice_type = dctd['name']

#endregion


#region Graph resource signal handlers

func _on_edited_resource_changed():
	_logger.debug("Graph resource changed")
	_update_node_characters()
	# Only want to do this if the type has actually changed
	if _edited.graph.graph_type != _current_graph_type:
		_current_graph_type = _edited.graph.graph_type
		_edited.refresh_types()
		_draw_edited_graph(true)
	graph_modified.emit()

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
		node.sub_graph_save_as_requested.connect(
			_on_sub_graph_save_as_requested
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


func _on_anchor_node_selected(node: EditorGraphNodeBase):
	anchor_node_selected.emit(node.node_resource.name)


func _on_node_removing_slot(slot, node_name):
	_logger.debug("Removal of slot %s on node %s requested" % [slot, node_name])
	var connections = self.get_connection_list()
	for connection in connections:
		_process_connection_for_slot_removal(
			connection,
			slot,
			node_name,
		)
	_set_dirty(true)


# TODO: Can this include more than one node? Seems like it can't currently...
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
		var node = self.get_node(NodePath(n))
		if node is EditorEntryPointAnchorNode:
			return true
	return false


func _on_node_modified(node_name):
	var editor_node = self.get_node(NodePath(node_name))
	if editor_node != null:
		if editor_node is EditorAnchorNode:
			_anchor_manager.configure(_edited.graph)
			_populate_anchor_destinations()
		var res = editor_node.node_resource
		# TODO: Would like to include a flag with this signal to indicate if
		# connections have been modified, to avoid recreating them unnecessarily.
		_clear_connections_for_node(res)
		_create_connections_for_node(res)
	# TODO: Raise signal instead I think
	# But is modified signal enough or do I need a "save_requested" signal?
	graph_modified.emit()
	#perform_save()


func _on_node_maximise_requested(node) -> void:
	node_maximise_requested.emit(
		node.node_resource
	)


func _on_sub_graph_node_open_requested(
	graph: DigressionDialogueGraph,
	path: String,
	editor_node: EditorGraphNodeBase
) -> void:
	sub_graph_edit_requested.emit(graph, path)


func _on_sub_graph_save_as_requested(
	graph: DigressionDialogueGraph,
) -> void:
	sub_graph_save_as_requested.emit(graph)


func _on_sub_graph_node_display_filesystem_path_requested(path):
	display_filesystem_path_requested.emit(path)


func _on_jump_node_destination_chosen(destination_id, node):
	_logger.debug("Jump destination %s chosen for node %s" % [
		destination_id, node
	])
	node.node_resource.next = destination_id
	_draw_edited_graph(true)

#endregion


#region Context menu


func _handle_create_node_request(
	node_creation_mode: NodeCreationMode,
	node_type: GraphNodeTypes,
	create_position: Vector2,
	pending_connection_from: Variant = null,
	pending_connection_from_port: Variant = null,
):
	_create_new_node_and_add(
		node_type,
		node_creation_mode,
		create_position,
		{},
		pending_connection_from,
		pending_connection_from_port,
	)
	_set_dirty(true)
	perform_save()


func _set_graph_popup_option_states(
	creation_mode: NodeCreationMode,
	pending_connection_from: Variant = null,
	pending_connection_from_port: Variant = null,
):
	graph_popup.set_option_states(
		creation_mode == NodeCreationMode.CONNECTED,
		false if pending_connection_from == null else _is_creating_for_anchor(
			pending_connection_from as String,
			pending_connection_from_port as int
		)
	)


func _is_creating_for_anchor(
	pending_connection_from: String,
	pending_connection_from_port: int,
) -> bool:
	if pending_connection_from.is_empty():
		return false
	var from_node = self.get_node(NodePath(pending_connection_from))
	return from_node.get_output_port_type(
		pending_connection_from_port
	) == ConnectionTypes.JUMP

#endregion

#region Utility functions

## Deep copies arrays and dictionaries. Just returns anything else.
func _deep_copy(obj):
	if obj == null:
		return obj
	if obj is Array or obj is Dictionary:
		return obj.duplicate(true)
	return obj


func _convert_popup_position(release_position: Vector2) -> Vector2:
	# This works pretty well - node appears slightly below and to the right of 
	# the click location so much like where a popup menu would appear. It was
	# determined by trial and error.
	return (release_position / self.zoom) + \
		(self.scroll_offset / self.zoom)


func _get_graph_edit_children() -> Array:
	var c = self.get_children()
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

#endregion

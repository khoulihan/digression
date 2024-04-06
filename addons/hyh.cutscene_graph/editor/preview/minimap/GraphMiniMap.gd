@tool
extends GraphEdit
## Mini-map for graph previewer.


const Logging = preload("../../../utility/Logging.gd")

# Resource graph nodes.
const DialogueTextNode = preload("../../../resources/graph/DialogueTextNode.gd")
const MatchBranchNode = preload("../../../resources/graph/MatchBranchNode.gd")
const IfBranchNode = preload("../../../resources/graph/MatchBranchNode.gd")
const DialogueChoiceNode = preload("../../../resources/graph/DialogueChoiceNode.gd")
const VariableSetNode = preload("../../../resources/graph/VariableSetNode.gd")
const ActionNode = preload("../../../resources/graph/ActionNode.gd")
const SubGraph = preload("../../../resources/graph/SubGraph.gd")
const RandomNode = preload("../../../resources/graph/RandomNode.gd")
const CommentNode = preload("../../../resources/graph/CommentNode.gd")
const JumpNode = preload("../../../resources/graph/JumpNode.gd")
const AnchorNode = preload("../../../resources/graph/AnchorNode.gd")
const RoutingNode = preload("../../../resources/graph/RoutingNode.gd")
const RepeatNode = preload("../../../resources/graph/RepeatNode.gd")

# Mini-map nodes
const MiniMapNodeBase = preload("MiniMapNodeBase.tscn")
#const MiniMapNodeBaseClass = preload("MiniMapNodeBase.gd")
const MiniMapActionNode = preload("MiniMapActionNode.tscn")
const MiniMapAnchorNode = preload("MiniMapAnchorNode.tscn")
const MiniMapMatchBranchNode = preload("MiniMapMatchBranchNode.tscn")
const MiniMapIfBranchNode = preload("MiniMapIfBranchNode.tscn")
const MiniMapChoiceNode = preload("MiniMapChoiceNode.tscn")
const MiniMapDialogueNode = preload("MiniMapDialogueNode.tscn")
const MiniMapJumpNode = preload("MiniMapJumpNode.tscn")
const MiniMapRandomNode = preload("MiniMapRandomNode.tscn")
const MiniMapRepeatNode = preload("MiniMapRepeatNode.tscn")
const MiniMapRoutingNode = preload("MiniMapRoutingNode.tscn")
const MiniMapSetNode = preload("MiniMapSetNode.tscn")
const MiniMapSubGraphNode = preload("MiniMapSubGraphNode.tscn")
const MiniMapCommentNode = preload("MiniMapCommentNode.tscn")
const SCALE = 0.26

var _logger = Logging.new("Digression Dialogue Graph Preview", Logging.DGE_NODES_LOG_LEVEL)
var _graph


# Called when the node enters the scene tree for the first time.
func _ready():
	#get_zoom_hbox().visible = false
	show_zoom_buttons = false
	show_arrange_button = false
	show_grid = false
	show_grid_buttons = false
	show_menu = false
	show_minimap_button = false


## Clear the mini-map.
func clear():
	_logger.debug("Clearing graph mini-map")
	for child in self.get_children():
		self.remove_child(child)
		child.free()


## Populate the mini-map for the provided graph.
func display_graph(graph):
	_logger.debug("Displaying graph mini-map")
	_graph = graph
	var root_node
	for i in graph.nodes:
		var node = graph.nodes[i]
		if node is CommentNode:
			continue
		var n = _instantiate_mini_map_node(node)
		n.set_meta("resource", node)
		self.add_child(n)
		n.position_offset = graph.nodes[i].offset * SCALE
		_add_branches(node, n)
		_set_tooltip(n, node)
		# Including the comments didn't really look good.
		# One problem is that they are inevitably offset
		# from where they appear to be in the actual graph.
		# Also, the wrapping is not really working correctly.
		#if node is CommentNode:
		#	n.set_comment_and_size(
		#		node.comment,
		#		node.size * SCALE
		#	)
		if graph.root_node == node:
			#n.overlay = GraphNode.OVERLAY_POSITION
			root_node = node
	for node in graph.nodes.values():
		_create_connections_for_node(node)
	focus_on_node(root_node)


## Focus on the specified node.
func focus_on_node(node):
	var n = _get_minimap_node_for_graph_node(node)
	# Setting this property apparently has to be deferred, at least
	# when the graph has just been populated...
	call_deferred("_focus_on_node", n)


func _instantiate_mini_map_node(node):
	var n
	if node is ActionNode:
		n = MiniMapActionNode.instantiate()
	elif node is AnchorNode:
		n = MiniMapAnchorNode.instantiate()
	elif node is MatchBranchNode:
		n = MiniMapMatchBranchNode.instantiate()
	elif node is IfBranchNode:
		n = MiniMapIfBranchNode.instantiate()
	elif node is CommentNode:
		n = MiniMapCommentNode.instantiate()
	elif node is DialogueChoiceNode:
		n = MiniMapChoiceNode.instantiate()
	elif node is DialogueTextNode:
		n = MiniMapDialogueNode.instantiate()
	elif node is JumpNode:
		n = MiniMapJumpNode.instantiate()
	elif node is RandomNode:
		n = MiniMapRandomNode.instantiate()
	elif node is RepeatNode:
		n = MiniMapRepeatNode.instantiate()
	elif node is RoutingNode:
		n = MiniMapRoutingNode.instantiate()
	elif node is VariableSetNode:
		n = MiniMapSetNode.instantiate()
	elif node is SubGraph:
		n = MiniMapSubGraphNode.instantiate()
	else:
		n = MiniMapNodeBase.instantiate()
	return n


func _set_tooltip(node, resource):
	if resource is ActionNode:
		node.tooltip_text = "Action \"%s\"" % resource.action_or_method_name
	elif resource is AnchorNode:
		node.tooltip_text = "Anchor \"%s\"" % resource.name
	elif resource is MatchBranchNode:
		node.tooltip_text = "Branch (Match) on \"%s\"" % resource.variable
	elif resource is IfBranchNode:
		node.tooltip_text = "Branch (If) on \"%s\"" % resource.variable
	elif resource is DialogueChoiceNode:
		node.tooltip_text = "Choice"
	elif resource is DialogueTextNode:
		node.tooltip_text = "Dialogue"
	elif resource is JumpNode:
		if resource.next == -1:
			node.tooltip_text = "Jump (no destination set)"
		else:
			var dest = _graph.nodes[resource.next]
			node.tooltip_text = "Jump to anchor \"%s\"" % dest.name
	elif resource is RandomNode:
		node.tooltip_text = "Random branch"
	elif resource is RepeatNode:
		node.tooltip_text = "Repeat last choice"
	elif resource is RoutingNode:
		node.tooltip_text = "Routing"
	elif resource is VariableSetNode:
		node.tooltip_text = "Set variable \"%s\"" % [resource.variable]
	elif resource is SubGraph:
		node.tooltip_text = "Sub-graph \"%s\"" % resource.sub_graph.name
	else:
		node.tooltip_text = "Unknown node"


func _add_branches(resource, node):
	if resource is MatchBranchNode:
		_add_branch_branches(resource, node)
	elif resource is RandomNode or resource is DialogueChoiceNode:
		_add_random_or_choice_branches(resource, node)


func _add_branch_branches(resource, node):
	for i in range(len(resource.branches)):
		var destination = resource.branches[i]
		var c = Control.new()
		c.custom_minimum_size = Vector2(0,20)
		c.set_meta("destination", destination)
		c.mouse_filter = Control.MOUSE_FILTER_PASS
		node.add_child(c)
		node.set_slot_enabled_left(i+1, false)
		node.set_slot_enabled_right(i+1, true)


func _add_random_or_choice_branches(resource, node):
	var branches
	if resource is RandomNode:
		branches = resource.branches
	else:
		branches = resource.choices
	for i in range(len(branches)):
		var branch = branches[i]
		var destination = branch.next
		var c = Control.new()
		c.custom_minimum_size = Vector2(0,20)
		c.set_meta("destination", destination)
		c.mouse_filter = Control.MOUSE_FILTER_PASS
		node.add_child(c)
		node.set_slot_enabled_left(i+1, false)
		node.set_slot_enabled_right(i+1, true)


func _create_connections_for_node(node):
	if node.next != -1:
		var from = _get_minimap_node_for_graph_node(node)
		var to = _get_minimap_node_for_graph_node(
			_graph.nodes[node.next]
		)
		self.connect_node(from.name, 0, to.name, 0)
	if node is MatchBranchNode:
		var from = _get_minimap_node_for_graph_node(node)
		for index in range(0, node.branches.size()):
			if node.branches[index]:
				var to = _get_minimap_node_for_graph_node(
					_graph.nodes[node.branches[index]]
				)
				self.connect_node(from.name, index + 1, to.name, 0)
	elif node is IfBranchNode:
		var from = _get_minimap_node_for_graph_node(node)
		for index in range(0, node.branches.size()):
			if node.branches[index].next != -1:
				var to = _get_minimap_node_for_graph_node(
					_graph.nodes[node.branches[index].next]
				)
				self.connect_node(from.name, index + 1, to.name, 0)
	elif node is RandomNode:
		var from = _get_minimap_node_for_graph_node(node)
		for index in range(0, node.branches.size()):
			if node.branches[index].next != -1:
				var to = _get_minimap_node_for_graph_node(
					_graph.nodes[node.branches[index].next]
				)
				self.connect_node(from.name, index + 1, to.name, 0)
	elif node is DialogueChoiceNode:
		var from = _get_minimap_node_for_graph_node(node)
		for index in range(0, node.choices.size()):
			if node.choices[index].next != -1:
				var to = _get_minimap_node_for_graph_node(
					_graph.nodes[node.choices[index].next]
				)
				self.connect_node(from.name, index + 1, to.name, 0)


func _get_minimap_node_for_graph_node(n):
	for node in self.get_children():
		#if node is MiniMapNodeBaseClass:
		if node.get_meta("resource") == n:
			return node
	return null


func _focus_on_node(node):
	# Note that this calculation only works at 1x zoom.
	# Currently we are fixed at that zoom level.
	self.scroll_offset = node.position_offset - (self.size / 2.0)
	# TODO: Need an alternative method of highlighting the current node.
	_unset_current_overlay(node)
	#if node.overlay != GraphNode.OVERLAY_POSITION:
		#node.overlay = GraphNode.OVERLAY_BREAKPOINT


func _unset_current_overlay(except_node):
	# TODO: Need an alternative method of highlighting the current node.
	return
	for node in self.get_children():
		if node == except_node:
			continue
		#if node.overlay == GraphNode.OVERLAY_BREAKPOINT:
			#node.overlay = GraphNode.OVERLAY_DISABLED


func _on_connection_drag_started(from_node, from_port, is_output):
	# We don't want the mini-map to appear editable at all.
	self.force_connection_drag_end()

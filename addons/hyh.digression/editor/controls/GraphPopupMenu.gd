@tool
extends PopupMenu


signal create_node_requested(node_type: GraphNodeTypes)


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


const GraphNodeFactory = preload("../factories/GraphNodeFactory.gd")
const GraphNodeTypes = GraphNodeFactory.GraphNodeTypes

const Logging = preload("../../utility/Logging.gd")


var _logger := Logging.get_editor_logger()


func _ready() -> void:
	self.index_pressed.connect(_on_index_pressed)


func node_type_for_menu_index(index: GraphPopupMenuItems) -> GraphNodeTypes:
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


func set_option_states(
	connected_creation: bool = false,
	from_anchor: bool = false
) -> void:
	if not connected_creation:
		_set_all_disabled(false)
	else:
		_set_graph_popup_option_states_for_connected_creation(from_anchor)


func _set_graph_popup_option_states_for_connected_creation(from_anchor: bool) -> void:
	if not from_anchor:
		_set_all_disabled(false)
		self.set_item_disabled(
			GraphPopupMenuItems.ADD_ANCHOR_NODE,
			true
		)
	else:
		_set_all_disabled(true)
		self.set_item_disabled(
			GraphPopupMenuItems.ADD_ANCHOR_NODE,
			false
		)
	self.set_item_disabled(
		GraphPopupMenuItems.ADD_COMMENT_NODE,
		true
	)


func _set_all_disabled(state):
	# TODO: Not great to use the current first and last elements here.
	for option in range(
		GraphPopupMenuBounds.LOWER_BOUND,
		GraphPopupMenuBounds.UPPER_BOUND + 1
	):
		self.set_item_disabled(option, state)


func _on_index_pressed(index: int) -> void:
	create_node_requested.emit(
		node_type_for_menu_index(index)
	)

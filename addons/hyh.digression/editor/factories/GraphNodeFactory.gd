@tool
extends RefCounted


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


# Resource graph nodes.
const GraphNodeBase = preload("../../resources/graph/GraphNodeBase.gd")
const DialogueNode = preload("../../resources/graph/DialogueNode.gd")
const MatchBranchNode = preload("../../resources/graph/MatchBranchNode.gd")
const IfBranchNode = preload("../../resources/graph/IfBranchNode.gd")
const DialogueChoiceNode = preload("../../resources/graph/DialogueChoiceNode.gd")
const VariableSetNode = preload("../../resources/graph/VariableSetNode.gd")
const ActionNode = preload("../../resources/graph/ActionNode.gd")
const SubGraph = preload("../../resources/graph/SubGraph.gd")
const RandomNode = preload("../../resources/graph/RandomNode.gd")
const CommentNode = preload("../../resources/graph/CommentNode.gd")
const JumpNode = preload("../../resources/graph/JumpNode.gd")
const AnchorNode = preload("../../resources/graph/AnchorNode.gd")
const RoutingNode = preload("../../resources/graph/RoutingNode.gd")
const RepeatNode = preload("../../resources/graph/RepeatNode.gd")
const EntryPointAnchorNode = preload("../../resources/graph/EntryPointAnchorNode.gd")
const ExitNode = preload("../../resources/graph/ExitNode.gd")

# Editor node classes.
const EditorDialogueNode = preload("../nodes/EditorDialogueNode.gd")
const EditorMatchBranchNode = preload("../nodes/EditorMatchBranchNode.gd")
const EditorIfBranchNode = preload("../nodes/EditorIfBranchNode.gd")
const EditorChoiceNode = preload("../nodes/EditorChoiceNode.gd")
const EditorSetNode = preload("../nodes/EditorSetNode.gd")
const EditorGraphNodeBase = preload("../nodes/EditorGraphNodeBase.gd")
const EditorActionNode = preload("../nodes/EditorActionNode.gd")
const EditorSubGraphNode = preload("../nodes/EditorSubGraphNode.gd")
const EditorRandomNode = preload("../nodes/EditorRandomNode.gd")
const EditorCommentNode = preload("../nodes/EditorCommentNode.gd")
const EditorJumpNode = preload("../nodes/EditorJumpNode.gd")
const EditorAnchorNode = preload("../nodes/EditorAnchorNode.gd")
const EditorRoutingNode = preload("../nodes/EditorRoutingNode.gd")
const EditorRepeatNode = preload("../nodes/EditorRepeatNode.gd")
const EditorEntryPointAnchorNode = preload("../nodes/EditorEntryPointAnchorNode.gd")
const EditorExitNode = preload("../nodes/EditorExitNode.gd")

# Editor node scenes.
const EditorDialogueNodeScene = preload("../nodes/EditorDialogueNode.tscn")
const EditorMatchBranchNodeScene = preload("../nodes/EditorMatchBranchNode.tscn")
const EditorIfBranchNodeScene = preload("../nodes/EditorIfBranchNode.tscn")
const EditorChoiceNodeScene = preload("../nodes/EditorChoiceNode.tscn")
const EditorSetNodeScene = preload("../nodes/EditorSetNode.tscn")
const EditorGraphNodeBaseScene = preload("../nodes/EditorGraphNodeBase.tscn")
const EditorActionNodeScene = preload("../nodes/EditorActionNode.tscn")
const EditorSubGraphNodeScene = preload("../nodes/EditorSubGraphNode.tscn")
const EditorRandomNodeScene = preload("../nodes/EditorRandomNode.tscn")
const EditorCommentNodeScene = preload("../nodes/EditorCommentNode.tscn")
const EditorJumpNodeScene = preload("../nodes/EditorJumpNode.tscn")
const EditorAnchorNodeScene = preload("../nodes/EditorAnchorNode.tscn")
const EditorRoutingNodeScene = preload("../nodes/EditorRoutingNode.tscn")
const EditorRepeatNodeScene = preload("../nodes/EditorRepeatNode.tscn")
const EditorEntryPointAnchorNodeScene = preload("../nodes/EditorEntryPointAnchorNode.tscn")
const EditorExitNodeScene = preload("../nodes/EditorExitNode.tscn")

const Logging = preload("../../utility/Logging.gd")


func create_graph_node(node_type: GraphNodeTypes) -> GraphNodeBase:
	var new_graph_node
	
	match node_type:
		GraphNodeTypes.DIALOGUE:
			new_graph_node = DialogueNode.new()
		GraphNodeTypes.MATCH_BRANCH:
			new_graph_node = MatchBranchNode.new()
		GraphNodeTypes.IF_BRANCH:
			new_graph_node = IfBranchNode.new()
		GraphNodeTypes.CHOICE:
			new_graph_node = DialogueChoiceNode.new()
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
		GraphNodeTypes.ROUTING:
			new_graph_node = RoutingNode.new()
		GraphNodeTypes.REPEAT:
			new_graph_node = RepeatNode.new()
		GraphNodeTypes.EXIT:
			new_graph_node = ExitNode.new()
	
	return new_graph_node


func instantiate_editor_node_for_graph_node(node: GraphNodeBase) -> EditorGraphNodeBase:
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
	
	return editor_node


func get_node_type(node: GraphNode) -> GraphNodeTypes:
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

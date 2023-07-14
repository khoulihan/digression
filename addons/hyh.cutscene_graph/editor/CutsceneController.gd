extends Node

## Walks a CutsceneGraph resource and raises signals with the details of each
## node.

const Logging = preload("../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Controller", Logging.CGE_NODES_LOG_LEVEL)

#const CutsceneGraph = preload("../resources/CutsceneGraph.gd")
const DialogueTextNode = preload("../resources/graph/DialogueTextNode.gd")
const BranchNode = preload("../resources/graph/BranchNode.gd")
const DialogueChoiceNode = preload("../resources/graph/DialogueChoiceNode.gd")
const VariableSetNode = preload("../resources/graph/VariableSetNode.gd")
const ActionNode = preload("../resources/graph/ActionNode.gd")
const SubGraph = preload("../resources/graph/SubGraph.gd")
const RandomNode = preload("../resources/graph/RandomNode.gd")
const AnchorNode = preload("../resources/graph/AnchorNode.gd")
const JumpNode = preload("../resources/graph/JumpNode.gd")
const RoutingNode = preload("../resources/graph/RoutingNode.gd")
const RepeatNode = preload("../resources/graph/RepeatNode.gd")

# Condition resource types
const BooleanCondition = preload("../resources/graph/branches/conditions/BooleanCondition.gd")
const ValueCondition = preload("../resources/graph/branches/conditions/ValueCondition.gd")
const BooleanType = BooleanCondition.BooleanType

## Emitted when processing of a cutscene graph begins.
signal cutscene_started(cutscene_name, graph_type)
## Emitted when a sub-graph has been entered.
signal sub_graph_entered(cutscene_name, graph_type)
## Emitted when processing of a cutscene graph resumes after a sub-graph completes.
signal cutscene_resumed(cutscene_name, graph_type)
## Emitted when processing of a cutscene graph is completed.
signal cutscene_completed()
## A request to display dialogue.
signal dialogue_display_requested(
	dialogue_type,
	text,
	character,
	character_variant,
	process
)
## A request to perform an action.
signal action_requested(
	action,
	character,
	character_variant,
	argument,
	process
)
## A request to display dialogue that is related to
## upcoming choices.
signal choice_dialogue_display_requested(
	choice_type,
	dialogue_type,
	text,
	character,
	character_variant,
	process
)
## A request to display choices to the player.
signal choice_display_requested(
	choice_type,
	choices,
	process
)
## A request to display choices to the player.
#signal choice_display_requested(
#	choice_type,
#	dialogue_included,
#	dialogue_type,
#	text,
#	character_name,
#	character_variant,
#	choices,
#	process
#)


class GraphState:
	var graph
	var current_node
	var last_choice_node_id


class ProceedSignal:
	signal ready_to_proceed(choice)
	
	func proceed(choice: int = -1):
		ready_to_proceed.emit(choice)


## A node that can store variables for the scope of the entire game
@export var global_store: NodePath
## A node that can store variables for the scope of the current level/scene
@export var scene_store: NodePath
var _local_store : Dictionary
var _global_store : Node
var _scene_store : Node

var _dialogue_types
var _choice_types

var _graph_stack
var _current_graph
var _current_node
var _split_dialogue
var _last_choice_node_id


## Register a global variable store
func register_global_store(store):
	Logger.info("Registering global store")
	_global_store = store


## Register a "scene" variable store
func register_scene_store(store):
	Logger.debug("Registering scene store")
	_scene_store = store


func _ready():
	if global_store != null and global_store != NodePath(""):
		register_global_store(get_node(global_store))
	else:
		Logger.warn("Global store not set.")
	
	if scene_store != null and scene_store != NodePath(""):
		register_scene_store(get_node(scene_store))
	else:
		Logger.warn("Scene store not set.")
	
	_dialogue_types = ProjectSettings.get_setting(
		"cutscene_graph_editor/dialogue_types"
	)
	_choice_types = ProjectSettings.get_setting(
		"cutscene_graph_editor/choice_types"
	)
	
	_local_store = {}


func _get_variable(variable_name, scope):
	match scope:
		VariableSetNode.VariableScope.SCOPE_DIALOGUE:
			# We can deal with these internally for the duration of a cutscene
			return _local_store.get(variable_name)
		VariableSetNode.VariableScope.SCOPE_SCENE:
			if _scene_store == null:
				Logger.error(
					"Scene variable \"%s\" requested but no scene store is available" % variable_name
				)
				return null
			return _scene_store.get_variable(variable_name)
		VariableSetNode.VariableScope.SCOPE_GLOBAL:
			if _global_store == null:
				Logger.error(
					"Global variable \"%s\" requested but no global store is available" % variable_name
				)
				return null
			return _global_store.get_variable(variable_name)
	return null


# This shouldn't really be required anymore
func _get_first_variable(variable_name):
	if variable_name in _local_store:
		return _local_store[variable_name]
	if _scene_store.has_variable(variable_name):
		return _scene_store.get_variable(variable_name)
	if _global_store.has_variable(variable_name):
		return _global_store.get_variable(variable_name)
	return null


func _set_variable(variable_name, scope, value):
	match scope:
		VariableSetNode.VariableScope.SCOPE_DIALOGUE:
			# We can deal with these internally for the duration of a cutscene
			_local_store[variable_name] = value
		VariableSetNode.VariableScope.SCOPE_SCENE:
			if _scene_store == null:
				Logger.error(
					"Scene variable \"%s\" set with value \"%s\" but no scene store is available" % [
						variable_name, value
					]
				)
				return
			_scene_store.set_variable(variable_name, value)
		VariableSetNode.VariableScope.SCOPE_GLOBAL:
			if _scene_store == null:
				Logger.error(
					"Scene variable \"%s\" set with value \"%s\" but no scene store is available" % [
						variable_name, value
					]
				)
				return
			_global_store.set_variable(variable_name, value)


func _await_response():
	return ProceedSignal.new()


func _get_node_by_id(id):
	if id != null and id != -1:
		return _current_graph.nodes.get(id)
	return null


## Process the specified cutscene graph.
func process_cutscene(cutscene):
	_graph_stack = []
	_local_store = {}
	_current_graph = cutscene
	_current_node = _current_graph.root_node
	Logger.info("Processing cutscene \"%s\"" % _current_graph.name)
	_split_dialogue = _get_split_dialogue_from_graph_type(
		_current_graph.graph_type
	)
	cutscene_started.emit(
		_current_graph.name,
		_current_graph.graph_type
	)
	
	while _current_node != null:
		
		if _current_node is DialogueTextNode:
			await _process_dialogue_node()
		elif _current_node is BranchNode:
			_process_branch_node()
		elif _current_node is DialogueChoiceNode:
			await _process_choice_node()
		elif _current_node is VariableSetNode:
			_process_set_node()
		elif _current_node is ActionNode:
			await _process_action_node()
		elif _current_node is SubGraph:
			_process_subgraph_node()
		elif _current_node is RandomNode:
			_process_random_node()
		elif _current_node is JumpNode:
			_process_passthrough_node()
		elif _current_node is AnchorNode:
			_process_passthrough_node()
		elif _current_node is RoutingNode:
			_process_passthrough_node()
		elif _current_node is RepeatNode:
			_process_repeat_node()
		
		if _current_node == null:
			if len(_graph_stack) > 0:
				var graph_state = _graph_stack.pop_back()
				_current_graph = graph_state.graph
				_last_choice_node_id = graph_state.last_choice_node_id
				_current_node = _get_node_by_id(graph_state.current_node.next)
				Logger.info("Resuming cutscene \"%s\"." % _current_graph.name)
				cutscene_resumed.emit(
					_current_graph.name,
					_current_graph.graph_type
				)
	
	Logger.info("Cutscene \"%s\" completed." % _current_graph.name)
	emit_signal("cutscene_completed")


func _get_split_dialogue_from_graph_type(graph_type):
	if graph_type == null or graph_type == '':
		return true

	var graph_types = ProjectSettings.get_setting(
		"cutscene_graph_editor/graph_types",
		[]
	)
	for gt in graph_types:
		if gt['name'] == _current_graph.graph_type:
			return gt['split_dialogue']
	
	return true


func _split_dialogue_for_node(dialogue_type, graph_type_setting):
	if dialogue_type.get('split_dialogue', null) == null:
		return graph_type_setting
	return dialogue_type['split_dialogue']


func _get_dialogue_type_by_name(name) -> Dictionary:
	if name == "":
		return {}
	for t in _dialogue_types:
		if t['name'] == name:
			return t
	return {}


func _get_choice_type_by_name(name) -> Dictionary:
	if name == "":
		return {}
	for t in _choice_types:
		if t['name'] == name:
			return t
	return {}


func _emit_dialogue_signal_variant(
	for_choice,
	choice_type,
	dialogue_type,
	text,
	character,
	character_variant,
	process
):
	if for_choice:
		_emit_choice_dialogue_signal(
			choice_type,
			dialogue_type,
			text,
			character,
			character_variant,
			process
		)
	else:
		_emit_dialogue_signal(
			dialogue_type,
			text,
			character,
			character_variant,
			process
		)


func _emit_dialogue_signal(
	dialogue_type,
	text,
	character,
	character_variant,
	process
):
	dialogue_display_requested.emit(
		dialogue_type,
		text,
		character,
		character_variant,
		process
	)


func _emit_choice_dialogue_signal(
	choice_type,
	dialogue_type,
	text,
	character,
	character_variant,
	process
):
	choice_dialogue_display_requested.emit(
		choice_type,
		dialogue_type,
		text,
		character,
		character_variant,
		process
	)


func _process_repeat_node():
	if _last_choice_node_id == null:
		_current_node = null
		return
	_current_node = _get_node_by_id(_last_choice_node_id)


## Process any type of node that just involves moving directly to the next node.
func _process_passthrough_node():
	_current_node = _get_node_by_id(_current_node.next)


func _process_dialogue_node():
	await _process_dialogue_node_internal(_current_node)


func _process_dialogue_node_internal(node, for_choice=false, choice_type=null):
	Logger.debug("Processing dialogue node \"%s\"." % node)
	
	var text = null
	# Try the translation first
	var tr_key = node.text_translation_key
	if tr_key != null and tr_key != "":
		text = tr(tr_key)
		if text == tr_key:
			text = null
	# Still no text, so use the default
	if text == null:
		text = node.text
	
	var dialogue_type: Dictionary = _get_dialogue_type_by_name(
		node.dialogue_type
	)
	var dialogue_type_name = dialogue_type.get('name', "")
	
	var character = null
	var variant = null
	
	if dialogue_type.get('involves_character', true):
		if node.character != null:
			character = node.character
		if node.character_variant != null:
			variant = node.character_variant
	
	if _split_dialogue_for_node(dialogue_type, _split_dialogue):
		# TODO: This should strip before splitting in case there
		# are blank lines before or after the interesting text.
		var lines = text.split("\n")
		for index in range(len(lines)):
			# Just in case there are blank lines
			if lines[index] == "":
				continue
			var process = _await_response()
			var final_line = for_choice and index == len(lines) - 1
			_emit_dialogue_signal_variant.call_deferred(
				final_line,
				choice_type,
				dialogue_type_name,
				lines[index],
				character,
				variant,
				process
			)
			await process.ready_to_proceed
	else:
		var process = _await_response()
		_emit_dialogue_signal_variant.call_deferred(
			for_choice,
			choice_type,
			dialogue_type_name,
			text,
			character,
			variant,
			process
		)
		await process.ready_to_proceed
	# If this dialogue is the child of a choice node,
	# it is the choice node that needs to decide the
	# next node to process.
	if not for_choice:
		_current_node = _get_node_by_id(node.next)
	

func _process_branch_node():
	Logger.debug("Processing branch node \"%s\"." % _current_node)
	
	var val = _get_variable(
		_current_node.variable,
		_current_node.scope
	)
	for i in range(_current_node.branch_count):
		if val == _current_node.get_value(i):
			_current_node = _get_node_by_id(
				_current_node.branches[i]
			)
			return
	# Default case, no match or no branches
	_current_node = _get_node_by_id(
		_current_node.next
	)


func _emit_choices_signal(
	choice_type,
	choices,
	process
):
	choice_display_requested.emit(
		choice_type,
		choices,
		process
	)


func _process_choice_node():
	Logger.debug("Processing choice node \"%s\"." % _current_node)
	
	var choice_type: Dictionary = _get_choice_type_by_name(
		_current_node.choice_type
	)
	var choice_type_name = choice_type.get('name', "")
	# TODO: What is the correct default here if the choice type is null?
	var include_dialogue = choice_type.get('include_dialogue', false)
	var show_dialogue_for_default = _current_node.show_dialogue_for_default
	
	if not choice_type.get("skip_for_repeat", false):
		_last_choice_node_id = _current_node.id
	
	var choices = {}
	for i in range(len(_current_node.choices)):
		var choice = _current_node.choices[i]
		var valid = true
		
		if choice.condition != null:
			valid = _evaluate_condition(choice.condition)
		
		if valid:
			var text = null
			# Try the translation first
			var tr_key = choice.display_translation_key
			if tr_key != null and tr_key != "":
				text = tr(tr_key)
				if text == tr_key:
					text = null
			# Still no text, so use the default
			if text == null:
				text = choice.display
			choices[i] = text
	
	if !choices.is_empty() or (include_dialogue and show_dialogue_for_default):
		
		if include_dialogue:
			await _process_dialogue_node_internal(
				_current_node.dialogue,
				true,
				choice_type_name
			)
		
		var process = _await_response()
		_emit_choices_signal.call_deferred(
			choice_type_name,
			choices,
			process
		)
		var choice = await process.ready_to_proceed
		if !choices.is_empty():
			_current_node = _get_node_by_id(
				_current_node.choices[choice].next
			)
		else:
			_current_node = _get_node_by_id(
				_current_node.next
			)
	else:
		_current_node = _get_node_by_id(
			_current_node.next
		)


func _process_set_node():
	Logger.debug("Processing set node \"%s\"." % _current_node)
	
	_set_variable(
		_current_node.variable,
		_current_node.scope,
		_current_node.get_value()
	)
	_current_node = _get_node_by_id(
		_current_node.next
	)


func _emit_action_signal(
	action,
	character,
	character_variant,
	argument,
	process
):
	action_requested.emit(
		action,
		character,
		character_variant,
		argument,
		process
	)


func _process_action_node():
	Logger.debug("Processing action node \"%s\"." % _current_node)
	
	var process = _await_response()
	
	var character = null
	var variant = null
	if _current_node.character != null:
		character = _current_node.character
	if _current_node.character_variant != null:
		variant = _current_node.character_variant
	
	_emit_action_signal.call_deferred(
		_current_node.action_name,
		character,
		variant,
		_current_node.argument,
		process
	)
	await process.ready_to_proceed
	_current_node = _get_node_by_id(
		_current_node.next
	)


func _process_subgraph_node():
	Logger.debug("Processing subgraph node \"%s\"." % _current_node)
	
	var graph_state = GraphState.new()
	graph_state.graph = _current_graph
	graph_state.current_node = _current_node
	graph_state.last_choice_node_id = _last_choice_node_id
	_graph_stack.push_back(graph_state)
	_current_graph = _current_node.sub_graph
	_current_node = _current_graph.root_node
	sub_graph_entered.emit(
		_current_graph.name,
		_current_graph.graph_type
	)


func _process_random_node():
	Logger.debug("Processing random node \"%s\"." % _current_node)
	
	var viable = []
	for i in range(len(_current_node.branches)):
		var branch = _current_node.branches[i]
		
		if _evaluate_condition(branch.condition):
			viable.append(branch.next)

	if len(viable) == 0:
		_current_node = _get_node_by_id(
			_current_node.next
		)
	else:
		_current_node = _get_node_by_id(
			viable[randi() % len(viable)]
		)


func _evaluate_condition(condition) -> bool:
	if condition == null:
		return true
	
	if condition is ValueCondition:
		return condition.evaluate(
			_get_variable(
				condition.variable,
				condition.scope
			)
		)
	var result: bool = (condition.operator == BooleanType.BOOLEAN_AND)
	for child in condition.children:
		if condition.operator == BooleanType.BOOLEAN_AND:
			result = result and _evaluate_condition(child)
			if not result:
				return result
		else:
			result = result or _evaluate_condition(child)
			if result:
				return result
	return result

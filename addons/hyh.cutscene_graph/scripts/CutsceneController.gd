extends Node

## Walks a CutsceneGraph resource and raises signals with the details of each
## node.

const Logging = preload("../scripts/Logging.gd")
var Logger = Logging.new("Cutscene Graph Controller", Logging.CGE_NODES_LOG_LEVEL)

#const CutsceneGraph = preload("../resources/CutsceneGraph.gd")
const DialogueTextNode = preload("../resources/DialogueTextNode.gd")
const BranchNode = preload("../resources/BranchNode.gd")
const DialogueChoiceNode = preload("../resources/DialogueChoiceNode.gd")
const VariableSetNode = preload("../resources/VariableSetNode.gd")
const ActionNode = preload("../resources/ActionNode.gd")
const SubGraph = preload("../resources/SubGraph.gd")
const RandomNode = preload("../resources/RandomNode.gd")

signal cutscene_started(cutscene_name, graph_type)
signal sub_graph_entered(cutscene_name, graph_type)
signal cutscene_resumed(cutscene_name, graph_type)
signal cutscene_completed()
signal dialogue_display_requested(
	text,
	character_name,
	character_variant,
	process
)
signal action_requested(
	action,
	character_name,
	character_variant,
	argument,
	process
)
signal choice_display_requested(choices, process)


class GraphState:
	var graph
	var current_node


class ProceedSignal:
	signal ready_to_proceed(choice)
	
	func proceed(choice: int = -1):
		emit_signal("ready_to_proceed", choice)

## A node that can store variables for the scope of the entire game
@export var global_store: NodePath
## A node that can store variables fo rthe scope of the current level/scene
@export var scene_store: NodePath
var _local_store : Dictionary
var _global_store : Node
var _scene_store : Node

var _graph_stack
var _current_graph
var _current_node


func register_global_store(store):
	Logger.info("Registering global store")
	_global_store = store


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
	
	_local_store = {}


func _get_variable(variable_name, scope):
	match scope:
		VariableSetNode.VariableScope.SCOPE_DIALOGUE:
			# We can deal with these internally for the duration of a cutscene
			return _local_store.get(variable_name)
		VariableSetNode.VariableScope.SCOPE_SCENE:
			if _scene_store == null:
				Logger.error("Scene variable \"%s\" requested but no scene store is available" % variable_name)
				return null
			return _scene_store.get_variable(variable_name)
		VariableSetNode.VariableScope.SCOPE_GLOBAL:
			if _global_store == null:
				Logger.error("Global variable \"%s\" requested but no global store is available" % variable_name)
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
				Logger.error("Scene variable \"%s\" set with value \"%s\" but no scene store is available" % [variable_name, value])
				return
			_scene_store.set_variable(variable_name, value)
		VariableSetNode.VariableScope.SCOPE_GLOBAL:
			if _scene_store == null:
				Logger.error("Scene variable \"%s\" set with value \"%s\" but no scene store is available" % [variable_name, value])
				return
			_global_store.set_variable(variable_name, value)


func _await_response():
	return ProceedSignal.new()


func _get_node_by_id(id):
	if id != null:
		return _current_graph.nodes.get(id)
	return null


func process_cutscene(cutscene):
	_graph_stack = []
	_local_store = {}
	_current_graph = cutscene
	_current_node = _current_graph.root_node
	Logger.info("Processing cutscene \"%s\"" % _current_graph.name)
	emit_signal("cutscene_started", _current_graph.name, _current_graph.graph_type)
	
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
		
		if _current_node == null:
			if len(_graph_stack) > 0:
				var graph_state = _graph_stack.pop_back()
				_current_graph = graph_state.graph
				_current_node = _get_node_by_id(graph_state.current_node.next)
				Logger.info("Resuming cutscene \"%s\"." % _current_graph.name)
				emit_signal(
					"cutscene_resumed",
					_current_graph.name,
					_current_graph.graph_type
				)
	
	Logger.info("Cutscene \"%s\" completed." % _current_graph.name)
	emit_signal("cutscene_completed")


func _emit_dialogue_signal(
	text,
	character_name,
	character_variant,
	process
):
	emit_signal(
		"dialogue_display_requested",
		text,
		character_name,
		character_variant,
		process
	)


func _process_dialogue_node():
	
	Logger.debug("Processing dialogue node \"%s\"." % _current_node)
	
	var text = null
	# Try the translation first
	var tr_key = _current_node.text_translation_key
	if tr_key != null and tr_key != "":
		text = tr(tr_key)
		if text == tr_key:
			text = null
	# Still no text, so use the default
	if text == null:
		text = _current_node.text
	
	var character_name = null
	var variant_name = null
	if _current_node.character != null:
		character_name = _current_node.character.character_name
	if _current_node.character_variant != null:
		variant_name = _current_node.character_variant.variant_name
	
	if _current_graph.split_dialogue:
		var lines = text.split("\n")
		for line in lines:
			# Just in case there are blank lines
			if line == "":
				continue
			var process = _await_response()
			call_deferred(
				"_emit_dialogue_signal",
				line,
				character_name,
				variant_name,
				process
			)
			await process.ready_to_proceed
	else:
		var process = _await_response()
		call_deferred(
			"_emit_dialogue_signal",
			text,
			character_name,
			variant_name,
			process
		)
		await process.ready_to_proceed
	_current_node = _get_node_by_id(_current_node.next)
	

func _process_branch_node():
	Logger.debug("Processing branch node \"%s\"." % _current_node)
	
	var val = _get_variable(_current_node.variable, _current_node.scope)
	for i in range(_current_node.branch_count):
		if val == _current_node.get_value(i):
			_current_node = _get_node_by_id(_current_node.branches[i])
			return
	# Default case, no match or no branches
	_current_node = _get_node_by_id(_current_node.next)


func _emit_choices_signal(
	choices,
	process
):
	emit_signal(
		"choice_display_requested",
		choices,
		process
	)


func _process_choice_node():
	Logger.debug("Processing choice node \"%s\"." % _current_node)
	
	var choices = {}
	for i in range(len(_current_node.branches)):
		var valid = true
		var variable = _current_node.variables[i]
		if variable != null and variable != "":
			var val = _get_variable(variable, _current_node.scopes[i])
			var expected_val = _current_node.get_value(i)
			valid = (val == expected_val)
		if valid:
			var text = null
			# Try the translation first
			var tr_key = _current_node.display_translation_keys[i]
			if tr_key != null and tr_key != "":
				text = tr(tr_key)
				if text == tr_key:
					text = null
			# Still no text, so use the default
			if text == null:
				text = _current_node.display[i]
			choices[i] = text
	if !choices.is_empty():
		var process = _await_response()
		call_deferred(
			"_emit_choices_signal",
			choices,
			process
		)
		var choice = await process.ready_to_proceed
		_current_node = _get_node_by_id(_current_node.branches[choice])
	else:
		_current_node = _get_node_by_id(_current_node.next)


func _process_set_node():
	Logger.debug("Processing set node \"%s\"." % _current_node)
	
	_set_variable(
		_current_node.variable,
		_current_node.scope,
		_current_node.get_value()
	)
	_current_node = _get_node_by_id(_current_node.next)


func _emit_action_signal(
	action,
	character_name,
	character_variant,
	argument,
	process
):
	emit_signal(
		"action_requested",
		action,
		character_name,
		character_variant,
		argument,
		process
	)


func _process_action_node():
	Logger.debug("Processing action node \"%s\"." % _current_node)
	
	var process = _await_response()
	
	var character_name = null
	var variant_name = null
	if _current_node.character != null:
		character_name = _current_node.character.character_name
	if _current_node.character_variant != null:
		variant_name = _current_node.character_variant.variant_name
	
	call_deferred(
		"_emit_action_signal",
		_current_node.action_name,
		character_name,
		variant_name,
		_current_node.argument,
		process
	)
	await process.ready_to_proceed
	_current_node = _get_node_by_id(_current_node.next)


func _process_subgraph_node():
	Logger.debug("Processing subgraph node \"%s\"." % _current_node)
	
	var graph_state = GraphState.new()
	graph_state.graph = _current_graph
	graph_state.current_node = _current_node
	_graph_stack.push_back(graph_state)
	_current_graph = _current_node.sub_graph
	_current_node = _current_graph.root_node
	emit_signal("sub_graph_entered", _current_graph.name, _current_graph.graph_type)


func _process_random_node():
	Logger.debug("Processing random node \"%s\"." % _current_node)
	
	var viable = []
	for i in range(len(_current_node.branches)):
		var variable = _current_node.variables[i]
		if variable == null or variable == "":
			viable.append(_current_node.branches[i])
		else:
			var val = _current_node.get_value(i)
			var stored = _get_variable(variable, _current_node.scopes[i])
			if val == stored:
				viable.append(_current_node.branches[i])
	if len(viable) == 0:
		_current_node = _get_node_by_id(_current_node.next)
	else:
		_current_node = _get_node_by_id(viable[randi() % len(viable)])

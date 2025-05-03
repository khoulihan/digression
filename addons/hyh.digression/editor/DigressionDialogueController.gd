@tool
extends Node
## Walks a DigressionDialogueGraph resource and raises signals with the details
## of each node.


#region Signals

## Emitted when processing of a dialogue graph begins.
signal dialogue_graph_started(graph_name, graph_type)
## Emitted when a sub-graph has been entered.
signal sub_graph_entered(graph_name, graph_type)
## Emitted when processing of a dialogue graph resumes after a sub-graph completes.
signal dialogue_graph_resumed(graph_name, graph_type, exit_value)
## Emitted when processing of a dialogue graph is completed.
signal dialogue_graph_completed(exit_value)
## Emitted when processing of a dialogue graph is cancelled prematurely.
signal cancelled()
## A request to display dialogue.
signal dialogue_display_requested(
	dialogue_type,
	text,
	character,
	character_variant,
	properties,
	process
)
## A request to perform an action.
signal action_requested(
	action,
	arguments,
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
	properties,
	process
)
## A request to display choices to the player.
signal choice_display_requested(
	choice_type,
	choices,
	process
)

#endregion

#region Enums

enum ProceedSignalReturnValues {
	CHOICE,
	VALUE,
}

#endregion

#region Constants

const Logging = preload("../utility/Logging.gd")
const DigressionSettings = preload("../editor/settings/DigressionSettings.gd")

const DialogueNode = preload("../resources/graph/DialogueNode.gd")
const MatchBranchNode = preload("../resources/graph/MatchBranchNode.gd")
const IfBranchNode = preload("../resources/graph/IfBranchNode.gd")
const DialogueChoiceNode = preload("../resources/graph/DialogueChoiceNode.gd")
const VariableSetNode = preload("../resources/graph/VariableSetNode.gd")
const ActionNode = preload("../resources/graph/ActionNode.gd")
const SubGraph = preload("../resources/graph/SubGraph.gd")
const RandomNode = preload("../resources/graph/RandomNode.gd")
const AnchorNode = preload("../resources/graph/AnchorNode.gd")
const JumpNode = preload("../resources/graph/JumpNode.gd")
const RoutingNode = preload("../resources/graph/RoutingNode.gd")
const RepeatNode = preload("../resources/graph/RepeatNode.gd")
const ExitNode = preload("../resources/graph/ExitNode.gd")

const ExpressionEvaluator = preload("./expressions/ExpressionEvaluator.gd")
const DialogueProcessingContext = preload("./DialogueProcessingContext.gd")

const ActionMechanism = ActionNode.ActionMechanism
const ActionReturnType = ActionNode.ActionReturnType
const ActionArgumentType = ActionNode.ActionArgumentType
const VariableScope = VariableSetNode.VariableScope
const VariableType = VariableSetNode.VariableType

const LAST_RETURN_VALUE_KEY = "_last_return_value"

#endregion

#region Variable definitions

## A node that can store variables for the scope of the entire game
@export var global_store: NodePath

## A node that can store variables for the scope of the current level/scene
@export var local_store: NodePath


var _context : DialogueProcessingContext

var _dialogue_types : Array
var _choice_types : Array
var _split_dialogue : bool

var _internal: ControllerInternal
var _currently_awaiting: ProceedSignal

var _expression_evaluator: ExpressionEvaluator

var _logger := Logging.get_runtime_logger()

#endregion


#region Built-in virtual methods

func _ready():
	_context = DialogueProcessingContext.new()
	
	if global_store != null and global_store != NodePath(""):
		register_global_store(get_node(global_store))
	else:
		_logger.warn("Global store not set.")
	
	if local_store != null and local_store != NodePath(""):
		register_local_store(get_node(local_store))
	else:
		_logger.warn("Scene store not set.")
	
	_dialogue_types = DigressionSettings.get_dialogue_types()
	_choice_types = DigressionSettings.get_choice_types()
	
	_expression_evaluator = ExpressionEvaluator.new()
	_expression_evaluator.context = _context
	
	# Only expose the internals if we are running in the editor.
	if Engine.is_editor_hint():
		_internal = ControllerInternal.new()

#endregion


#region Public interface

## Register a global variable store
func register_global_store(store):
	_logger.info("Registering global store")
	_context.global_store = store


## Register a "local" variable store
func register_local_store(store):
	_logger.debug("Registering local store")
	_context.local_store = store


## Process the specified dialogue graph.
func process_dialogue_graph(
	dialogue_graph,
	state_store,
	scene_root=null,
	start_anchor=null
):
	var entry_name = _context.prepare_for_processing(
		dialogue_graph,
		state_store,
		scene_root,
		start_anchor,
	)
	_logger.info(
		"Processing dialogue graph \"%s\" starting at anchor \"%s\"" % [
			_context.graph.name,
			entry_name,
		]
	)
	_split_dialogue = _get_split_dialogue_from_graph_type(
		_context.graph.graph_type
	)
	dialogue_graph_started.emit(
		_context.graph.name,
		_context.graph.graph_type
	)
	
	while _context.current_node != null:
		_context.increment_current_node_visit_count()
		
		if _context.current_node is DialogueNode:
			await _process_dialogue_node()
		elif _context.current_node is MatchBranchNode:
			_process_match_branch_node()
		elif _context.current_node is IfBranchNode:
			_process_if_branch_node()
		elif _context.current_node is DialogueChoiceNode:
			await _process_choice_node()
		elif _context.current_node is VariableSetNode:
			_internal_notify_set_node()
			_process_set_node()
		elif _context.current_node is ActionNode:
			await _process_action_node()
		elif _context.current_node is SubGraph:
			_process_subgraph_node()
		elif _context.current_node is RandomNode:
			_process_random_node()
		elif _context.current_node is JumpNode:
			_internal_notify_jump_node()
			_process_passthrough_node()
		elif _context.current_node is AnchorNode:
			_internal_notify_anchor_node()
			_process_passthrough_node()
		elif _context.current_node is RoutingNode:
			_internal_notify_routing_node()
			_process_passthrough_node()
		elif _context.current_node is RepeatNode:
			_internal_notify_repeat_node()
			_process_repeat_node()
		elif _context.current_node is ExitNode:
			_internal_notify_exit_node()
			_process_exit_node()
		
		if _context.graph == null:
			# Graph processing has been cancelled.
			_logger.info("Dialogue graph processing cancelled.")
			cancelled.emit()
			return
		
		if _context.current_node == null:
			if not _context.is_graph_stack_empty():
				_context.pop_graph_stack()
				_logger.info("Resuming dialogue graph \"%s\"." % _context.graph.name)
				dialogue_graph_resumed.emit(
					_context.graph.name,
					_context.graph.graph_type,
					_context.get_last_exit_value(),
				)
	
	_logger.info("Dialogue graph \"%s\" completed." % _context.graph.name)
	dialogue_graph_completed.emit(
		_context.get_current_exit_value()
	)


## Stop processing
func cancel():
	# TODO: The graph and current node were being cleared twice here and I don't know why!
	# Determine if not doing so is a problem - might be that cancelling the await restores them somehow.
	if _currently_awaiting != null and not _currently_awaiting.signalled():
		_currently_awaiting.cancel()
	_context.cancel_processing()

#endregion


#region Node processing toplevel

## Process any type of node that just involves moving directly to the next node.
func _process_passthrough_node():
	_context.advance_to_next_node()


func _process_repeat_node():
	if _context.last_choice_node_id == null:
		_context.clear_current_node()
		return
	# TODO: Could have a "get_last_choice_node" or "return_to_last_choice" method here.
	_context.set_current_node(
		_context.get_node_by_id(_context.last_choice_node_id)
	)


func _process_dialogue_node():
	await _process_dialogue_node_internal(_context.current_node)


func _process_dialogue_node_internal(node, for_choice=false, choice_type=null):
	_logger.debug("Processing dialogue node \"%s\"." % node)
	for text_resource in node.sections:
		await _process_dialogue_node_text_internal(
			node,
			text_resource,
			for_choice,
			choice_type
		)
	# If this dialogue is the child of a choice node,
	# it is the choice node that needs to decide the
	# next node to process.
	if not for_choice:
		_context.set_current_node(
			_context.get_node_by_id(node.next)
		)

func _process_dialogue_node_text_internal(node, text_resource, for_choice=false, choice_type=null):
	_logger.debug("Processing dialogue text \"%s\"." % text_resource)
	
	var text = null
	# Try the translation first
	var tr_key = text_resource.text_translation_key
	if tr_key != null and tr_key != "":
		text = tr(tr_key)
		if text == tr_key:
			text = null
	# Still no text, so use the default
	if text == null:
		text = text_resource.text
	
	var dialogue_type: Dictionary = _get_dialogue_type_by_name(
		node.dialogue_type
	)
	var dialogue_type_name = dialogue_type.get('name', "")
	
	var character = null
	var variant = null
	
	if dialogue_type.get('involves_character', true):
		if node.character != null:
			character = node.character
		if text_resource.character_variant != null:
			variant = text_resource.character_variant
	
	# Process the custom properties
	var properties := {}
	for property_name in text_resource.custom_properties:
		properties[property_name] = _expression_evaluator.evaluate(
			text_resource.custom_properties[property_name]['expression']
		)
	
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
				_context.substitute_variables(lines[index]),
				character,
				variant,
				properties,
				process
			)
			var response = await process.ready_to_proceed
			if process.was_cancelled():
				_cancel_processing()
				return
			var return_value = response[
				ProceedSignalReturnValues.VALUE
			]
			if return_value != null:
				_context.set_last_return_value(return_value)
	else:
		var process = _await_response()
		_emit_dialogue_signal_variant.call_deferred(
			for_choice,
			choice_type,
			dialogue_type_name,
			_context.substitute_variables(text),
			character,
			variant,
			properties,
			process
		)
		var response = await process.ready_to_proceed
		if process.was_cancelled():
			_cancel_processing()
			return
		var return_value = response[
			ProceedSignalReturnValues.VALUE
		]
		if return_value != null:
			_context.set_last_return_value(return_value)


func _process_match_branch_node():
	_logger.debug("Processing match branch node \"%s\"." % _context.current_node)
	
	var val = _context.get_variable(
		_context.current_node.variable,
		_context.current_node.scope
	)
	for i in range(len(_context.current_node.branches)):
		var branch_value = _context.realise_value(
			_context.current_node.get_value(i)
		)
		
		if val == branch_value:
			_context.set_current_node(
				_context.get_node_by_id(
					_context.current_node.branches[i].next
				)
			)
			return
	# Default case, no match or no branches
	_context.advance_to_next_node()


func _process_if_branch_node():
	_logger.debug("Processing if branch node \"%s\"." % _context.current_node)
	
	for i in range(len(_context.current_node.branches)):
		var branch_true = _expression_evaluator.evaluate(
			_context.current_node.branches[i].condition
		)
		
		if branch_true:
			# TODO: Could the context contain a method for this?
			_context.set_current_node(
				_context.get_node_by_id(
					_context.current_node.branches[i].next
				)
			)
			return
	# Default case, no match or no branches
	_context.advance_to_next_node()


func _process_choice_node():
	_logger.debug("Processing choice node \"%s\"." % _context.current_node)
	
	var choice_type: Dictionary = _get_choice_type_by_name(
		_context.current_node.choice_type
	)
	var choice_type_name = choice_type.get('name', "")
	# TODO: What is the correct default here if the choice type is null?
	var include_dialogue = choice_type.get('include_dialogue', false)
	var show_dialogue_for_default = _context.current_node.show_dialogue_for_default
	
	if not choice_type.get("skip_for_repeat", false):
		_context.last_choice_node_id = _context.current_node.id
	
	var choices = {}
	for i in range(len(_context.current_node.choices)):
		var choice = _context.current_node.choices[i]
		var valid = true
		
		if choice.condition != null:
			valid = _evaluate_boolean_expression_resource(
				choice.condition,
				choice
			)
		
		if valid:
			var choice_obj = Choice.new()
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
			text = _context.substitute_variables(text, choice)
			
			# Process the custom properties
			var properties := {}
			for property_name in choice.custom_properties:
				properties[property_name] = _expression_evaluator.evaluate(
					choice.custom_properties[property_name]['expression'],
					choice
				)
			
			choice_obj.text = text
			choice_obj.visit_count = _context.get_visit_count(choice)
			choice_obj.properties = properties
			choices[i] = choice_obj
	
	if !choices.is_empty() or (include_dialogue and show_dialogue_for_default):
		
		if include_dialogue:
			await _process_dialogue_node_internal(
				_context.current_node.dialogue,
				true,
				choice_type_name
			)
		
		var process = _await_response()
		_emit_choices_signal.call_deferred(
			choice_type_name,
			choices,
			process
		)
		var response = await process.ready_to_proceed
		if process.was_cancelled():
			_cancel_processing()
			return
		var choice = response[ProceedSignalReturnValues.CHOICE]
		var return_value = response[
			ProceedSignalReturnValues.VALUE
		]
		if return_value != null:
			_context.set_last_return_value(return_value)
		if !choices.is_empty() and choice != null:
			var c = _context.current_node.choices[choice]
			_context.increment_visit_count(c)
			_context.last_choice = c
			_context.set_current_node(
				_context.get_node_by_id(
					c.next
				)
			)
		else:
			_context.advance_to_next_node()
	else:
		_context.advance_to_next_node()


func _process_action_node():
	_logger.debug("Processing action node \"%s\"." % _context.current_node)
	
	var process = _await_response()
	
	var arguments = _get_action_arguments()
	
	var response = null
	var ret_value = null
	
	if _context.current_node.action_mechanism == ActionMechanism.SIGNAL:
		_emit_action_signal.call_deferred(
			_context.current_node.action_or_method_name,
			arguments,
			process
		)
		response = await process.ready_to_proceed
		if process.was_cancelled():
			_cancel_processing()
			return
		ret_value = response[
			ProceedSignalReturnValues.VALUE
		]
	else:
		var action_node
		if not _is_previewing() and _context.scene_root != null:
			action_node = _context.scene_root.get_node_or_null(_context.current_node.node)
		elif _is_previewing():
			# If we are previewing there is a method on the previewer which
			# handles all actions - and the previewer will be the owner.
			action_node = owner
		
		if action_node == null:
			_logger.error(
				"Node specified for action could not be found %s" % [
					_context.current_node.node
				]
			)
			_context.advance_to_next_node()
			return
		
		_logger.debug("Node for method call action is %s" % action_node.name)
		if not _is_previewing() and not action_node.has_method(_context.current_node.action_or_method_name):
			_logger.error(
				"Node specified for action does not have method %s" % [
					_context.current_node.action_or_method_name
				]
			)
			_context.advance_to_next_node()
			return
		
		if _context.current_node.returns_immediately:
			ret_value = _call_action_method(
				action_node,
				_context.current_node.action_or_method_name,
				arguments,
			)
		else:
			arguments.append(process)
			_call_action_method(
				action_node,
				_context.current_node.action_or_method_name,
				arguments,
			)
			response = await process.ready_to_proceed
			if process.was_cancelled():
				_cancel_processing()
				return
			ret_value = response[
				ProceedSignalReturnValues.VALUE
			]
	
	_handle_action_return(ret_value)
	_context.advance_to_next_node()


func _process_set_node():
	_logger.debug("Processing set node \"%s\"." % _context.current_node)
	
	_context.set_variable(
		_context.current_node.variable,
		_context.current_node.scope,
		_expression_evaluator.evaluate(
			_context.current_node.get_value_expression()
		)
	)
	_context.advance_to_next_node()


func _process_subgraph_node():
	_logger.debug("Processing subgraph node \"%s\"." % _context.current_node)
	
	# TODO: sub_graph could be null?
	# TODO: Probably will always be pushing the sub_graph of the current node,
	# so could have a method for that.
	_context.push_graph_to_stack(
		_context.current_node.sub_graph,
		_context.current_node.entry_point,
	)
	sub_graph_entered.emit(
		_context.graph.name,
		_context.graph.graph_type
	)


func _process_exit_node():
	_logger.debug("Processing exit node \"%s\"." % _context.current_node)
	
	if _context.current_node.value != null:
		_context.set_exit_value(
			_expression_evaluator.evaluate(
				_context.current_node.value.expression
			)
		)
	if _context.current_node.exit_type == ExitNode.ExitType.RETURN_TO_PARENT:
		# There should be no "next node", so advancing will exit to the parent
		# or exit completely, whichever is appropriate.
		_context.advance_to_next_node()
	else:
		# We have to stop graph processing completely, ignoring the graph stack.
		# Notably, this is not the same as cancelling.
		_context.clear_stack()
		_context.advance_to_next_node()


func _process_random_node():
	_logger.debug("Processing random node \"%s\"." % _context.current_node)
	
	var viable = []
	var accumulated_weight := 0
	for i in range(len(_context.current_node.branches)):
		var branch = _context.current_node.branches[i]
		# No weight set actually means a weight of 1
		var branch_weight: int = 1 if branch.weight < 1 else branch.weight
		
		if _evaluate_boolean_expression_resource(branch.condition):
			accumulated_weight += branch_weight
			viable.append({
				"next": branch.next,
				"weight": branch_weight,
				"accumulated_weight": accumulated_weight,
			})

	if len(viable) == 0:
		_context.advance_to_next_node()
	else:
		var roll := (randi() % accumulated_weight) + 1
		_context.set_current_node(
			_context.get_node_by_id(
				_get_weighted_branch(viable, roll)
			)
		)

#endregion


#region Node processing detail

func _call_action_method(action_node, method, arguments):
	if _is_previewing():
		return _call_preview_action_method(
			method,
			arguments,
		)
	if _context.current_node.returns_immediately:
		return action_node.callv(
			method,
			arguments
		)
	# `callv_deferred` does not exist, but I need it!
	# Fake it by deferring a call to a method that will use `callv`
	call_deferred(
		"_node_callv",
		action_node,
		method,
		arguments,
	)


func _call_preview_action_method(method, arguments):
	if _context.current_node.returns_immediately:
		return owner.call(
			'_action_method',
			method,
			_context.current_node.returns_immediately,
			arguments,
		)
	owner.call_deferred(
		'_action_method',
		method,
		_context.current_node.returns_immediately,
		arguments,
	)


func _get_action_arguments():
	var arguments = []
	for argument in _context.current_node.arguments:
		match argument['argument_type']:
			ActionArgumentType.DATA_STORE:
				arguments.append(
					_context.get_data_store(argument['data_store_type'])
				)
			ActionArgumentType.CHARACTER:
				arguments.append(
					_get_character_from_argument(argument)
				)
			ActionArgumentType.EXPRESSION:
				arguments.append(
					_expression_evaluator.evaluate(
						argument['expression']
					)
				)
	return arguments


func _handle_action_return(return_value):
	_context.set_last_return_value(return_value)
	if _context.current_node.return_type == ActionReturnType.ASSIGN_TO_VARIABLE:
		var v = _context.current_node.return_variable
		if v == null or v.is_empty():
			_logger.error("Variable not set for action node return value.")
		else:
			_context.set_variable(v['name'], v['scope'], return_value)


func _node_callv(node, method, arguments):
	node.callv(method, arguments)


func _get_character_from_argument(argument):
	var c = CharacterDetails.new()
	if argument['character'] == null:
		return null
	c.character = argument['character']
	if argument['variant'] != null:
		c.variant = argument['variant']
	return c


func _get_weighted_branch(branches, roll) -> int:
	for branch in branches:
		if branch["accumulated_weight"] >= roll:
			return branch["next"]
	_logger.error("No branch found to satisfy roll.")
	return -1


func _evaluate_boolean_expression_resource(res, current_choice=null):
	if res == null:
		return true
	var result = _expression_evaluator.evaluate(
		res.expression,
		current_choice
	)
	if result == null:
		return false
	return result


func _await_response():
	_currently_awaiting = ProceedSignal.new()
	return _currently_awaiting


func _cancel_processing():
	#_current_graph = null
	_context.clear_current_node()
	# TODO: Would this not be a better substitute for the above line?
	#_context.cancel_processing()

#endregion


#region Dialogue and choice types

func _get_split_dialogue_from_graph_type(graph_type) -> bool:
	if graph_type == null or graph_type == '':
		return true

	var graph_types := DigressionSettings.get_graph_types()

	for gt in graph_types:
		if gt['name'] == _context.graph.graph_type:
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

#endregion


#region Signal emission

func _emit_dialogue_signal_variant(
	for_choice,
	choice_type,
	dialogue_type,
	text,
	character,
	character_variant,
	properties,
	process
):
	if for_choice:
		_emit_choice_dialogue_signal(
			choice_type,
			dialogue_type,
			text,
			character,
			character_variant,
			properties,
			process
		)
	else:
		_emit_dialogue_signal(
			dialogue_type,
			text,
			character,
			character_variant,
			properties,
			process
		)


func _emit_dialogue_signal(
	dialogue_type,
	text,
	character,
	character_variant,
	properties,
	process
):
	dialogue_display_requested.emit(
		dialogue_type,
		text,
		character,
		character_variant,
		properties,
		process
	)


func _emit_choice_dialogue_signal(
	choice_type,
	dialogue_type,
	text,
	character,
	character_variant,
	properties,
	process
):
	choice_dialogue_display_requested.emit(
		choice_type,
		dialogue_type,
		text,
		character,
		character_variant,
		properties,
		process
	)


func _emit_action_signal(
	action,
	arguments,
	process
):
	action_requested.emit(
		action,
		arguments,
		process
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

#endregion


#region Internal state notifications

func _is_previewing():
	return _internal != null


func _internal_notify_repeat_node():
	if not _is_previewing():
		return
	_internal.processed_repeat_node.emit()


func _internal_notify_jump_node():
	if not _is_previewing():
		return
	var target = _context.get_node_by_id(_context.current_node.next)
	var destination_name = null
	if target != null:
		destination_name = target.name
	_internal.processed_jump_node.emit(destination_name)


func _internal_notify_anchor_node():
	if not _is_previewing():
		return
	_internal.processed_anchor_node.emit(_context.current_node.name)


func _internal_notify_routing_node():
	if not _is_previewing():
		return
	_internal.processed_routing_node.emit()


func _internal_notify_set_node():
	if not _is_previewing():
		return
	# TODO: This involves evaluating the expression a second time
	# This is both wasteful and might produce incorrect results!
	_internal.processed_set_node.emit(
		_context.current_node.variable,
		_context.current_node.scope,
		_expression_evaluator.evaluate(
			_context.current_node.get_value_expression()
		)
	)


func _internal_notify_exit_node():
	if not _is_previewing():
		return
	_internal.processed_exit_node.emit()

#endregion


#region Internal classes

class ProceedSignal:
	signal ready_to_proceed(choice, return_value)
	
	var _cancelled := false
	var _signalled := false
	var return_value = null
	
	func proceed(return_value=null) -> void:
		_signalled = true
		self.return_value = return_value
		ready_to_proceed.emit(null, return_value)
	
	func proceed_with_choice(choice: int, return_value=null) -> void:
		_signalled = true
		self.return_value = return_value
		ready_to_proceed.emit(choice, return_value)
	
	func cancel() -> void:
		_signalled = true
		_cancelled = true
		ready_to_proceed.emit()
	
	func was_cancelled() -> bool:
		return self._cancelled
	
	func signalled() -> bool:
		return _signalled


class Choice:
	var text: String
	var visited: bool:
		get:
			return visit_count > 0
	var visit_count: int
	var properties: Dictionary


class CharacterDetails:
	var character
	var variant
	
	func has_variant():
		return self.variant != null


# This class is for communicating the internal state of the controller to
# the graph previewer, and perhaps other debugging tools.
class ControllerInternal:
	signal processed_set_node(variable, scope, value)
	signal processed_match_branch_node(variable, scope, value, branch_matched)
	signal processed_if_branch_node(branch_matched)
	signal processed_random_node()
	signal processed_repeat_node()
	signal processed_jump_node(destination_name)
	signal processed_anchor_node(anchor_name)
	signal processed_routing_node()
	signal processed_exit_node()

#endregion

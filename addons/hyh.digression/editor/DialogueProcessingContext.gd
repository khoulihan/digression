@tool
extends RefCounted
## Stores the context for a graph that is being processed.


const BuiltInVariable = {
	LAST_RETURN_VALUE = "_last_return_value",
	GRAPH_TRIGGERED_COUNT = "_graph_triggered_count",
	GRAPH_TRIGGERED_PREVIOUSLY = "_graph_triggered_previously",
	CURRENT_NODE_VISIT_COUNT = "_current_node_visit_count",
	CURRENT_NODE_VISITED_PREVIOUSLY = "_current_node_visited_previously",
	PREVIOUS_NODE_VISIT_COUNT = "_previous_node_visit_count",
	CHOICE_VISIT_COUNT = "_choice_visit_count",
	CHOICE_VISITED_PREVIOUSLY = "_choice_visited_previously",
	SUBGRAPH_EXIT_VALUE = "_subgraph_exit_value",
}

const Logging = preload("../utility/Logging.gd")
const VariableHelper = preload("./helpers/VariablesHelper.gd")
const VariableSetNode = preload("../resources/graph/VariableSetNode.gd")
const VariableScope = VariableSetNode.VariableScope
const AnchorNode = preload("res://addons/hyh.digression/resources/graph/AnchorNode.gd")


var graph

# Variable stores
var transient_store : Dictionary
var dialogue_graph_state_store : Dictionary
var global_store : Node
var local_store : Node

# Graph traversal state and history
var previous_node
var current_node
var last_choice
# TODO: Why is this an ID while all the others are the resources themselves?
var last_choice_node_id

# TODO: Is this the appropriate name??
var _logger = Logging.new(
	"Digression Dialogue Processing Context",
	Logging.DGE_NODES_LOG_LEVEL
)
var _variable_regex: RegEx
var _graph_stack
var _built_in_variable_names: Array[String]
var _current_graph_exit_value = null
var _last_graph_exit_value = null


func _init() -> void:
	_variable_regex = RegEx.new()
	_variable_regex.compile(
		r'(?<!\\){([\w\s:]+?)}',
	)
	# Some built-in variables are appropriate to keep in the
	# transient store, so those are pre-populated here.
	transient_store = {}
	transient_store[BuiltInVariable.LAST_RETURN_VALUE] = null
	_built_in_variable_names = []
	for v in VariableHelper.BUILT_IN_VARIABLES:
		if v['name'] not in _built_in_variable_names:
			_built_in_variable_names.append(v['name'])


func prepare_for_processing(dialogue_graph, state_store, start_anchor=null):
	_graph_stack = []
	transient_store = {}
	dialogue_graph_state_store = state_store
	var triggered_count = 0 if not '_graph_triggered_count' in dialogue_graph_state_store else dialogue_graph_state_store['_graph_triggered_count']
	dialogue_graph_state_store['_graph_triggered_count'] = triggered_count + 1
	graph = dialogue_graph
	current_node = _get_start_node(start_anchor)
	previous_node = null
	last_choice = null
	return current_node.name


func _get_start_node(start_anchor):
	if start_anchor == null:
		return graph.root_node
	for n in graph.nodes.values():
		if not n is AnchorNode:
			continue
		if n.name == start_anchor:
			return n
	_logger.error(
		"Specified anchor (\"%s\") not found. Starting at root." % start_anchor
	)
	return graph.root_node
	


## Stop processing
func cancel_processing():
	graph = null
	current_node = null
	previous_node = null
	last_choice = null
	last_choice_node_id = null


#region Variable management

func get_data_store(scope):
	match scope:
		VariableScope.SCOPE_TRANSIENT:
			return transient_store
		VariableScope.SCOPE_DIALOGUE_GRAPH:
			return dialogue_graph_state_store
		VariableScope.SCOPE_LOCAL:
			return local_store
		VariableScope.SCOPE_GLOBAL:
			return global_store


func get_variable(variable_name, scope, current_choice=null):
	# As well as straightforwardly retrieving the specified variable in the specified
	# scope, we may be asked to return a built-in variable here.
	if _is_built_in_variable(variable_name):
		_logger.debug("Handling built-in variable")
		return get_special_variable(variable_name, current_choice)
	match scope:
		VariableSetNode.VariableScope.SCOPE_TRANSIENT:
			# We can deal with these internally for the duration of a graph
			return transient_store.get(variable_name)
		VariableSetNode.VariableScope.SCOPE_DIALOGUE_GRAPH:
			return dialogue_graph_state_store.get(variable_name)
		VariableSetNode.VariableScope.SCOPE_LOCAL:
			if local_store == null:
				_logger.error(
					"Scene variable \"%s\" requested but no local store is available" % variable_name
				)
				return null
			return local_store.get_variable(variable_name)
		VariableSetNode.VariableScope.SCOPE_GLOBAL:
			if global_store == null:
				_logger.error(
					"Global variable \"%s\" requested but no global store is available" % variable_name
				)
				return null
			return global_store.get_variable(variable_name)
	return null


func get_variable_any_store(variable_name, current_choice=null):
	# As well as straightforwardly retrieving the specified variable, we may be
	# asked to return a built-in variable here.
	if _is_built_in_variable(variable_name):
		_logger.debug("Handling built-in variable")
		return get_special_variable(variable_name, current_choice)
	if transient_store != null:
		if variable_name in transient_store:
			return transient_store[variable_name]
	if dialogue_graph_state_store != null:
		if variable_name in dialogue_graph_state_store:
			return dialogue_graph_state_store[variable_name]
	if local_store != null:
		if local_store.has_variable(variable_name):
			return local_store.get_variable(variable_name)
	if global_store != null:
		if global_store.has_variable(variable_name):
			return global_store.get_variable(variable_name)
	return null


func _normalise_built_in_variable_name(variable_name : String) -> String:
	if variable_name.left(1) != "_":
		variable_name = "_%s" % variable_name
	return variable_name


func _is_built_in_variable(variable_name : String) -> bool:
	return _normalise_built_in_variable_name(variable_name) in _built_in_variable_names


func _matches_special_variable_name(variable_name: String, base_name: String) -> bool:
	return variable_name == base_name or "_%s" % variable_name == base_name


## Special variables are built-ins which are based on the current context
func get_special_variable(variable_name, current_choice=null):
	match _normalise_built_in_variable_name(variable_name):
		BuiltInVariable.CURRENT_NODE_VISIT_COUNT:
			var v = _get_visit_count_variable(current_node)
			return dialogue_graph_state_store.get(v, 0)
		BuiltInVariable.CURRENT_NODE_VISITED_PREVIOUSLY:
			var v = _get_visit_count_variable(current_node)
			return dialogue_graph_state_store.get(v, 0) > 1
		BuiltInVariable.PREVIOUS_NODE_VISIT_COUNT:
			if previous_node == null:
				return 0
			var v = _get_visit_count_variable(previous_node)
			return dialogue_graph_state_store.get(v, 0)
		BuiltInVariable.GRAPH_TRIGGERED_COUNT:
			return dialogue_graph_state_store.get(BuiltInVariable.GRAPH_TRIGGERED_COUNT, 0)
		BuiltInVariable.GRAPH_TRIGGERED_PREVIOUSLY:
			return dialogue_graph_state_store.get(BuiltInVariable.GRAPH_TRIGGERED_COUNT, 0) > 1
		BuiltInVariable.LAST_RETURN_VALUE:
			return transient_store[BuiltInVariable.LAST_RETURN_VALUE]
		BuiltInVariable.SUBGRAPH_EXIT_VALUE:
			return _last_graph_exit_value
		_:
			# _choice_visit_count and _choice_visited_previously remain. They have to
			# work within a choice and for the last choice made.
			var relevant_choice = last_choice if current_choice == null else current_choice
			# When evaluating a choice in a choice node the visit counter will
			# not have been incremented, whereas if we are considering it after
			# it has been chosen it will have been, changing the basis for
			# determining if it has been visited previously.
			var limit = 1 if current_choice == null else 0
			if relevant_choice != null:
				var v = _get_visit_count_variable(relevant_choice)
				var val = dialogue_graph_state_store.get(v, 0)
				if _matches_special_variable_name(variable_name, BuiltInVariable.CHOICE_VISIT_COUNT):
					return val
				elif _matches_special_variable_name(variable_name, BuiltInVariable.CHOICE_VISITED_PREVIOUSLY):
					return val > limit
	return null


func set_variable(variable_name, scope, value):
	match scope:
		VariableSetNode.VariableScope.SCOPE_TRANSIENT:
			# We can deal with these internally for the duration of a graph
			transient_store[variable_name] = value
		VariableSetNode.VariableScope.SCOPE_DIALOGUE_GRAPH:
			dialogue_graph_state_store[variable_name] = value
		VariableSetNode.VariableScope.SCOPE_LOCAL:
			if local_store == null:
				_logger.error(
					"Scene variable \"%s\" set with value \"%s\" but no scene store is available" % [
						variable_name, value
					]
				)
				return
			local_store.set_variable(variable_name, value)
		VariableSetNode.VariableScope.SCOPE_GLOBAL:
			if global_store == null:
				_logger.error(
					"Global variable \"%s\" set with value \"%s\" but no global store is available" % [
						variable_name, value
					]
				)
				return
			global_store.set_variable(variable_name, value)


func set_last_return_value(return_value):
	if return_value != null:
		transient_store[BuiltInVariable.LAST_RETURN_VALUE] = return_value


func substitute_variables(text: String, current_choice=null) -> String:
	var substituted := text
	var substitutions := {}
	for m in _variable_regex.search_all(text):
		var variable_name := m.get_string(1)
		var variable_value = get_variable_any_store(variable_name)
		if variable_value == null:
			_logger.error("Variable \"%s\" not found in any store: substitution failed." % variable_name)
			variable_value = ""
		substitutions[variable_name] = variable_value
	if len(substitutions) > 0:
		substituted = substituted.format(substitutions)
	# Actualise any escape sequences
	substituted = substituted.c_unescape()
	# Clean up the string by removing any escaped braces
	substituted = substituted.replace(r'\{', "{")
	substituted = substituted.replace(r'\}', "}")
	return substituted


func realise_value(value_or_var: Variant) -> Variant:
	if typeof(value_or_var) == TYPE_DICTIONARY:
		return get_variable(
			value_or_var['name'],
			value_or_var['scope'],
		)
	return value_or_var


func _get_meta_variable_root(res):
	return "_%s_%s" % [graph.name, res.resource_path]


func _get_meta_variable_name(res, v):
	return "%s_%s" % [_get_meta_variable_root(res), v]


func _get_visit_count_variable(res):
	return _get_meta_variable_name(res, "visited_count")


func get_visit_count(res):
	var v = _get_visit_count_variable(res)
	return dialogue_graph_state_store.get(v, 0)


func increment_visit_count(res):
	dialogue_graph_state_store[
		_get_visit_count_variable(res)
	] = get_visit_count(res) + 1


func get_current_node_visit_count():
	return get_visit_count(current_node)


func increment_current_node_visit_count():
	increment_visit_count(current_node)


func set_exit_value(val):
	_current_graph_exit_value = val


## Get the exit value for the last completed subgraph.
func get_last_exit_value():
	return _last_graph_exit_value


## Get the exit value set for the current graph. This is used for the completion
## signal when an exit node completes graph processing.
func get_current_exit_value():
	return _current_graph_exit_value

#endregion


#region Graph traversal

func set_current_node(new_current):
	previous_node = current_node
	current_node = new_current


func clear_current_node():
	set_current_node(null)


func advance_to_next_node():
	set_current_node(
		get_node_by_id(
			current_node.next
		)
	)


func get_node_by_id(id):
	if id != null and id != -1:
		return graph.nodes.get(id)
	return null


func get_next_node():
	return get_node_by_id(current_node.next)

#endregion


#region Graph stack management

func is_graph_stack_empty():
	return len(_graph_stack) == 0


func pop_graph_stack():
	if not is_graph_stack_empty():
		var graph_state = _graph_stack.pop_back()
		graph = graph_state.graph
		last_choice_node_id = graph_state.last_choice_node_id
		previous_node = graph_state.current_node
		current_node = get_node_by_id(graph_state.current_node.next)
		last_choice = graph_state.last_choice
		_last_graph_exit_value = _current_graph_exit_value
		transient_store[BuiltInVariable.SUBGRAPH_EXIT_VALUE] = _last_graph_exit_value
		_current_graph_exit_value = null


func push_graph_to_stack(new_graph, entry_point=null):
	var graph_state = GraphState.new()
	graph_state.graph = graph
	graph_state.current_node = current_node
	graph_state.last_choice_node_id = last_choice_node_id
	graph_state.last_choice = last_choice
	_graph_stack.push_back(graph_state)
	graph = new_graph
	if entry_point == null:
		current_node = graph.root_node
	else:
		current_node = entry_point
	previous_node = null
	_last_graph_exit_value = null
	_current_graph_exit_value = null


## Remove all graphs from the stack. This means that if the current graph is a
## subgraph it will not return to the parent after it is finished.
func clear_stack():
	_graph_stack.clear()

#endregion


#region Internal classes

class GraphState:
	var graph
	var current_node
	var last_choice_node_id
	var last_choice

#endregion

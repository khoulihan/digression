@tool
extends RefCounted


const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope

const _descriptions := {
	'_last_return_value': "The last value returned from a choice, dialogue, or action.",
	'_subgraph_exit_value': "The exit value from the last subgraph processed (if any).",
}
const BUILT_IN_VARIABLES: Array[Dictionary] = [
	{
		'name': "_last_return_value",
		"scope": VariableScope.SCOPE_TRANSIENT,
		"type": VariableType.TYPE_BOOL,
		"description": _descriptions['_last_return_value'],
		"tags": ['builtin', 'last_return_value']
	},
	{
		'name': "_last_return_value",
		"scope": VariableScope.SCOPE_TRANSIENT,
		"type": VariableType.TYPE_FLOAT,
		"description": _descriptions['_last_return_value'],
		"tags": ['builtin', 'last_return_value']
	},
	{
		'name': "_last_return_value",
		"scope": VariableScope.SCOPE_TRANSIENT,
		"type": VariableType.TYPE_INT,
		"description": _descriptions['_last_return_value'],
		"tags": ['builtin', 'last_return_value']
	},
	{
		'name': "_last_return_value",
		"scope": VariableScope.SCOPE_TRANSIENT,
		"type": VariableType.TYPE_STRING,
		"description": _descriptions['_last_return_value'],
		"tags": ['builtin', 'last_return_value']
	},
	{
		'name': "_subgraph_exit_value",
		"scope": VariableScope.SCOPE_TRANSIENT,
		"type": VariableType.TYPE_BOOL,
		"description": _descriptions['_subgraph_exit_value'],
		"tags": ['builtin', 'subgraph_exit_value']
	},
	{
		'name': "_subgraph_exit_value",
		"scope": VariableScope.SCOPE_TRANSIENT,
		"type": VariableType.TYPE_FLOAT,
		"description": _descriptions['_subgraph_exit_value'],
		"tags": ['builtin', 'subgraph_exit_value']
	},
	{
		'name': "_subgraph_exit_value",
		"scope": VariableScope.SCOPE_TRANSIENT,
		"type": VariableType.TYPE_INT,
		"description": _descriptions['_subgraph_exit_value'],
		"tags": ['builtin', 'subgraph_exit_value']
	},
	{
		'name': "_subgraph_exit_value",
		"scope": VariableScope.SCOPE_TRANSIENT,
		"type": VariableType.TYPE_STRING,
		"description": _descriptions['_subgraph_exit_value'],
		"tags": ['builtin', 'subgraph_exit_value']
	},
	{
		'name': "_graph_triggered_count",
		"scope": VariableScope.SCOPE_DIALOGUE_GRAPH,
		"type": VariableType.TYPE_INT,
		"description": "The number of times this graph has been triggered.",
		"tags": ['builtin']
	},
	{
		'name': "_current_node_visit_count",
		"scope": VariableScope.SCOPE_DIALOGUE_GRAPH,
		"type": VariableType.TYPE_INT,
		"description": "The number of times this node has been visited.",
		"tags": ['builtin']
	},
	{
		'name': "_previous_node_visit_count",
		"scope": VariableScope.SCOPE_DIALOGUE_GRAPH,
		"type": VariableType.TYPE_INT,
		"description": "The number of times the previous node has been visited.",
		"tags": ['builtin']
	},
	{
		'name': "_choice_visit_count",
		"scope": VariableScope.SCOPE_DIALOGUE_GRAPH,
		"type": VariableType.TYPE_INT,
		"description": "The number of times a choice has been selected.",
		"tags": ['builtin']
	},
	{
		'name': "_graph_triggered_previously",
		"scope": VariableScope.SCOPE_DIALOGUE_GRAPH,
		"type": VariableType.TYPE_BOOL,
		"description": "Indicates whether or not this graph has been triggered before.",
		"tags": ['builtin']
	},
	{
		'name': "_current_node_visited_previously",
		"scope": VariableScope.SCOPE_DIALOGUE_GRAPH,
		"type": VariableType.TYPE_BOOL,
		"description": "Indicates whether or not this node has been visited before.",
		"tags": ['builtin']
	},
	{
		'name': "_choice_visited_previously",
		"scope": VariableScope.SCOPE_DIALOGUE_GRAPH,
		"type": VariableType.TYPE_BOOL,
		"description": "Indicates whether or not a choice has been visited before.",
		"tags": ['builtin']
	}
]


## Remove the leading underscore from built-in variables.
static func create_display_name(name: String) -> String:
	if name.begins_with("_"):
		return name.substr(1)
	return name

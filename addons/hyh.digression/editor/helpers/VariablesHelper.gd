@tool
extends RefCounted


const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope

const _descriptions := {
	'_last_return_value': "The last value returned from a choice, dialogue, or action."
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
		'name': "_graph_triggered_count",
		"scope": VariableScope.SCOPE_DIALOGUE_GRAPH,
		"type": VariableType.TYPE_INT,
		"description": "The number of times this graph has been triggered.",
		"tags": ['builtin']
	}
]


## Remove the leading underscore from built-in variables.
static func create_display_name(name: String) -> String:
	if name.begins_with("_"):
		return name.substr(1)
	return name

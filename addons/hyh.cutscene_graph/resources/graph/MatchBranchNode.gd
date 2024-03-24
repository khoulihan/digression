@tool
extends "GraphNodeBase.gd"
## A branch node with semantics similar to a "match" statement.


const VariableScope = preload("VariableSetNode.gd").VariableScope
const VariableType = preload("VariableSetNode.gd").VariableType

## The name of the variable to compare to the branch values.
@export var variable: String

## The type of the variable.
@export var variable_type = VariableType.TYPE_BOOL

## The scope of the variable.
@export var scope: VariableScope

# TODO: This seems unnecessary...
## The number of branches.
@export var branch_count = 0

# branches cannot be a typed array because then it would not be able
# to store nulls where no connection is present.
## An array of the nodes to connect to for each branch.
var branches: Array
## An array of the values to compare to for each branch.
var values: Array


# This is necessary to ensure that "branches" and "values"
# are saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "values",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	properties.append({
		"name": "branches",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties


## Get the value for a specific branch.
func get_value(index):
	return values[index]


## Get all the branch values.
func get_values():
	return values


## Set all branch values.
func set_values(vals):
	values.resize(branch_count)
	for i in range(branch_count):
		values[i] = vals[i]


## Return an array of all outgoing connections.
func get_connections() -> Array[int]:
	var connections: Array[int] = [next]
	for b in branches:
		if b == null:
			connections.append(-1)
		else:
			connections.append(b)
	return connections


## Connect to the specified node
func connect_to_node(connection_index: int, node_id: int) -> void:
	if connection_index == 0:
		next = node_id
		return
	branches[connection_index - 1] = node_id

@tool
extends "GraphNodeBase.gd"
## A branch node with semantics similar to a "match" statement.


const VariableScope = preload("VariableSetNode.gd").VariableScope
const VariableType = preload("VariableSetNode.gd").VariableType
const MatchBranch = preload("branches/MatchBranch.gd")

## The name of the variable to compare to the branch values.
@export var variable: String

## The type of the variable.
@export var variable_type = VariableType.TYPE_BOOL

## The scope of the variable.
@export var scope: VariableScope

## An array of the branches for the node.
@export var branches: Array[MatchBranch]


## Get the value for a specific branch.
func get_value(index):
	return branches[index].value


## Return an array of all outgoing connections.
func get_connections() -> Array[int]:
	var connections: Array[int] = [next]
	for b in branches:
		connections.append(b.next)
	return connections


## Connect to the specified node
func connect_to_node(connection_index: int, node_id: int) -> void:
	if connection_index == 0:
		next = node_id
		return
	branches[connection_index - 1].next = node_id


func remove_branch(branch: MatchBranch) -> void:
	branches.remove_at(
		branches.find(branch)
	)

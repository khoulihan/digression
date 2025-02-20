@tool
extends "GraphNodeBase.gd"
## A branch node with semantics similar to an "if" statement.


const IfBranch = preload("branches/IfBranch.gd")

## The possible branches of the node.
@export var branches: Array[IfBranch]


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


func remove_branch(branch: IfBranch) -> void:
	branches.remove_at(
		branches.find(branch)
	)

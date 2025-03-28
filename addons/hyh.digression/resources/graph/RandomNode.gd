@tool
extends "GraphNodeBase.gd"
## A node for following a random route.


const RandomBranch = preload("branches/RandomBranch.gd")

## An array of the branches for the node.
@export var branches: Array[RandomBranch]


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


func remove_branch(branch: RandomBranch) -> void:
	branches.remove_at(
		branches.find(branch)
	)

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

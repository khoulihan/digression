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

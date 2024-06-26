@tool
extends Resource
## The base class of all dialogue graph node resources.

## A unique ID for the node.
@export var id: int

## The node to move to next. This may be a default fallback for some node types.
@export var next: int = -1

## The position of the node in the graph editor. Not relevant at runtime.
@export var offset: Vector2


## Return an array of all outgoing connections.
func get_connections() -> Array[int]:
	return [next]


## Connect to the specified node
func connect_to_node(connection_index: int, node_id: int) -> void:
	if connection_index > 0:
		return
	next = node_id

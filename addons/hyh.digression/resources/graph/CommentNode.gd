@tool
extends "GraphNodeBase.gd"
## A node for a comment. It cannot be connected to other nodes.

## The comment text.
@export var comment: String = "Enter your comment here..."

# This is used only for recreating the node state in the editor
@export var size: Vector2


## Connect to the specified node
func connect_to_node(connection_index: int, node_id: int) -> void:
	return

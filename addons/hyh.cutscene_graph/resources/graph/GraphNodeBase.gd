@tool
extends Resource
## The base class of all dialogue graph node resources.

## A unique ID for the node.
@export var id: int

## The node to move to next. This may be a default fallback for some node types.
@export var next: int = -1

## The position of the node in the graph editor. Not relevant at runtime.
@export var offset: Vector2

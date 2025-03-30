@tool
extends "GraphNodeBase.gd"

enum ExitType {
	RETURN_TO_PARENT,
	STOP_GRAPH_PROCESSING,
}

const ExpressionResource = preload("expressions/ExpressionResource.gd")

## The type of exit (just exit the current graph or stop all graph processing).
@export var exit_type: ExitType

## An optional value to return in the completion signal and to the parent graph
## if there is one.
@export var value: ExpressionResource

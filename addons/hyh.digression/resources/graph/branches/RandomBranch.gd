@tool
extends Resource
## A branch resource for Random node branches.


const ExpressionResource = preload("../expressions/ExpressionResource.gd")


## The node to proceed to if this branch is chosen.
@export var next: int = -1

## An expression to evaluate to determine if this branch should be considered.
@export var condition: ExpressionResource

## A weight for this branch (-1 for "no weight", functionally the same as a
## weight of 1).
@export var weight: int = -1

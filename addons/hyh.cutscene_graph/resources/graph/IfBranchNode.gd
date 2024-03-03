@tool
extends "GraphNodeBase.gd"
## A branch node with semantics similar to an "if" statement.


const IfBranch = preload("branches/IfBranch.gd")

## The possible branches of the node.
@export var branches: Array[IfBranch]

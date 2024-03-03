@tool
extends "GraphNodeBase.gd"
## A node for following a random route.


const RandomBranch = preload("branches/RandomBranch.gd")

## An array of the branches for the node.
@export var branches: Array[RandomBranch]

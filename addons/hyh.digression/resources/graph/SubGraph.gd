@tool
extends "GraphNodeBase.gd"
## A node that references another graph resource to be run directly.


const AnchorNode = preload("res://addons/hyh.digression/resources/graph/AnchorNode.gd")


## The graph resource.
@export var sub_graph: DigressionDialogueGraph
@export var entry_point: AnchorNode

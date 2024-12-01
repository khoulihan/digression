@tool
extends "GraphNodeBase.gd"
## A node for grouping related dialogue texts.


const DialogueTextNode = preload("DialogueTextNode.gd")


## A character associated with this dialogue group, if any.
@export var character: Character

## The child text nodes.
@export var children: Array[DialogueTextNode]

# This is used only for recreating the node state in the editor
@export var size: Vector2

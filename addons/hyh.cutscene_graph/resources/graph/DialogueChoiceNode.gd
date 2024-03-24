@tool
extends "GraphNodeBase.gd"


const ChoiceBranch = preload("branches/ChoiceBranch.gd")
const DialogueTextNode = preload("DialogueTextNode.gd")
const VariableType = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableType


@export var choice_type: String
# This array no longer needs to allow nulls
@export var choices: Array[ChoiceBranch]
@export var dialogue: DialogueTextNode
@export var show_dialogue_for_default: bool = false

# This is used only for recreating the node state in the editor
@export var size: Vector2


func _init():
	self.dialogue = DialogueTextNode.new()


## Return an array of all outgoing connections.
func get_connections() -> Array[int]:
	var connections: Array[int] = [next]
	for b in choices:
		connections.append(b.next)
	return connections

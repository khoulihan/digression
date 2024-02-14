@tool
extends "GraphNodeBase.gd"

enum ActionMechanism {
	SIGNAL,
	METHOD,
}

enum ActionReturnType {
	NONE,
	ASSIGN_TO_VARIABLE,
}

enum ActionArgumentType {
	EXPRESSION,
	CHARACTER,
	DATA_STORE,
}


@export var action_mechanism: ActionMechanism = ActionMechanism.SIGNAL
@export var node: NodePath # This is only relevant if `action_type` is METHOD
@export var action_or_method_name: String
# This is only relevant if `action_type` is METHOD
@export var returns_immediately: bool = false

@export var return_type: ActionReturnType = ActionReturnType.NONE
# This is only relevant if `return_type` is ASSIGN_TO_VARIABLE
@export var return_variable: Dictionary

@export var arguments: Array[Dictionary] = []


func _init():
	pass

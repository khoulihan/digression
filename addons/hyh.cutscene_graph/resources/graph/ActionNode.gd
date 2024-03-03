@tool
extends "GraphNodeBase.gd"
## Node that represents a custom action.

## The mechanism by which the action is indicated to the game.
enum ActionMechanism {
	SIGNAL,
	METHOD,
}

## What to do with return values from an action.
enum ActionReturnType {
	NONE,
	ASSIGN_TO_VARIABLE,
}

## Possible types for action arguments.
enum ActionArgumentType {
	EXPRESSION,
	CHARACTER,
	DATA_STORE,
}

## The mechanism of action - either a signal can be raised, or a specified
## method can be called on  a particular node.
@export var action_mechanism: ActionMechanism = ActionMechanism.SIGNAL

## The node on which to call a method, if the METHOD action mechanism is used.
## This is only relevant if `action_type` is METHOD
@export var node: NodePath

## The action name to pass in the signal, or name of the method to call.
@export var action_or_method_name: String

## Indicates if the method returns immediately. Otherwise a `process` object
## will be passed as the last argument and the callee must use it to resume
## processing when ready.
## This is only relevant if `action_type` is METHOD
@export var returns_immediately: bool = false

## What to do with the return value, if there is one.
@export var return_type: ActionReturnType = ActionReturnType.NONE

## Details of the variable to store the return value in.
## This is only relevant if `return_type` is ASSIGN_TO_VARIABLE
@export var return_variable: Dictionary

## A collection of arguments to pass to the action handler.
@export var arguments: Array[Dictionary] = []

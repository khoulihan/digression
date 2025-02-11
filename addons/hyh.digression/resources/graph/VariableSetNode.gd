@tool
extends "GraphNodeBase.gd"
## A node for setting the value of a variable.


## The possible scopes for variables.
enum VariableScope {
	SCOPE_TRANSIENT,
	SCOPE_DIALOGUE_GRAPH,
	SCOPE_LOCAL,
	SCOPE_GLOBAL
}

# These match the Variant.Type enum... which I could not reference directly
# for some reason. Anyway we only need a few of them.
## The possible types for variables to be used by the graph editor.
enum VariableType {
	TYPE_BOOL = 1,
	TYPE_INT = 2,
	TYPE_FLOAT = 3,
	TYPE_STRING = 4
}

## The scope of the variable.
@export var scope: VariableScope

## The name of the variable.
@export var variable: String

## The type of the variable.
@export var variable_type: VariableType

# This is used only for recreating the node state in the editor
@export var size: Vector2

## The expression to evaluate to set the variable value at runtime.
var value_expression


# This is necessary to ensure that "value_expression" is saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "value_expression",
		"type": null,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties


func get_value_expression():
	return value_expression


func set_value_expression(val):
	value_expression = val

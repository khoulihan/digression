@tool
extends "GraphNodeBase.gd"

const VariableScope = preload("VariableSetNode.gd").VariableScope
const VariableType = preload("VariableSetNode.gd").VariableType

@export var variables: Array[String]
@export var scopes: Array[VariableScope]
@export var variable_types: Array[VariableType]


# branches cannot be a typed array because then it would not be able
# to store nulls where no connection is present.
var branches: Array
var values: Array


# This is necessary to ensure that "branches" and "values"
# are saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "values",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	properties.append({
		"name": "branches",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties


func get_value(index):
	return values[index]


func get_values():
	return values


func set_values(vals):
	values.resize(len(variable_types))
	for i in range(len(variable_types)):
		values[i] = vals[i]


func _init():
	pass

@tool
extends "GraphNodeBase.gd"


const VariableScope = preload("VariableSetNode.gd").VariableScope
const VariableType = preload("VariableSetNode.gd").VariableType


@export var variable: String
@export var variable_type = VariableType.TYPE_BOOL
@export var scope: VariableScope
@export var branch_count = 0

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
	values.resize(branch_count)
	for i in range(branch_count):
		values[i] = vals[i]


func _init():
	pass

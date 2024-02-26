@tool
extends Resource


const VariableType = preload("../graph/VariableSetNode.gd").VariableType


@export var property: String
@export var type: VariableType
var value


# This is necessary to ensure that "value" is saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "value",
		"type": null,
		"usage": PROPERTY_USAGE_STORAGE + PROPERTY_USAGE_EDITOR,
	})
	return properties


func get_value():
	return value


func set_value(val):
	value = val

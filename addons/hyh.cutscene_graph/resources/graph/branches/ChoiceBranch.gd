@tool
extends Resource


const ExpressionResource = preload("../expressions/ExpressionResource.gd")
const VariableType = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableType


@export var display: String
@export var display_translation_key: String

@export var next: int = -1
@export var condition: ExpressionResource

var custom_properties: Dictionary = {}


func add_custom_property(name: String, type: VariableType) -> Dictionary:
	var cp := {
		'name': name,
		'type': type,
		'expression': {},
	}
	custom_properties[name] = cp
	return cp


func remove_custom_property(name: String) -> void:
	custom_properties.erase(name)


# This may not really be worthwhile for nodes. We will need to
# evaluate the properties and pass them in a dictionary to the
# handler signals anyway, the user will not see this resource
# directly.
func _get_property_list():
	var properties = []
	
	properties.append({
		"name": "custom_properties",
		"type": TYPE_DICTIONARY,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	
	for prop_name in custom_properties:
		var hint = PROPERTY_HINT_NONE
		var hint_string = ""
		properties.append({
			"name": prop_name,
			"type": TYPE_DICTIONARY,
			"usage": PROPERTY_USAGE_EDITOR,
			"hint": hint,
			"hint_string": hint_string,
		})
				
	return properties


func _get(property):
	if not property in custom_properties:
		return
	return custom_properties[
		property
	]['expression']


func _set(property, value):
	if not property in custom_properties:
		return false
	custom_properties[
		property
	]['expression'] = value
	return true

@tool
extends Resource
## A resource for dialogue text within a DialogueTextGroupNode.


const VariableType = preload("VariableSetNode.gd").VariableType

# TODO: Do we need this??
## A unique ID for the node.
#@export var id: int

## The dialogue text.
@export var text: String

## A key to use for retrieving equivalent localised text for this dialogue.
@export var text_translation_key: String

## A character variant associated with this dialogue, if any.
@export var character_variant: CharacterVariant

# This is used only for recreating the node state in the editor
@export var size: Vector2

## Details of the resource's custom properties.
var custom_properties: Dictionary = {}


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


## Add a custom property to the node.
func add_custom_property(name: String, type: VariableType) -> Dictionary:
	var cp := {
		'name': name,
		'type': type,
		'expression': {},
	}
	custom_properties[name] = cp
	return cp


## Remove a custom property.
func remove_custom_property(name: String) -> void:
	custom_properties.erase(name)

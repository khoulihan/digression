@tool
@icon("res://addons/hyh.cutscene_graph/icons/icon_portrait.svg")
extends Resource

class_name CharacterVariant


const PropertyUse = preload("../editor/property_select_dialog/PropertySelectDialog.gd").PropertyUse
const VariableType = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableType


## An identifier for the variant to reference it in code.
@export
var variant_name: String

## An optional display name to represent the variant to the player.
@export
var variant_display_name: String

var custom_properties: Dictionary = {}


## Returns the display name and name, formatted for display in the editor.
func get_full_name() -> String:
	var display = self.variant_display_name
	if display == null or display == "":
		display = "Unnamed Variant"
	
	var actual = self.variant_name
	if actual == null or actual == "":
		actual = "unnamed"
	
	return "%s (%s)" % [display, actual]


func add_custom_property(name: String, type: VariableType) -> void:
	var value
	match type:
		VariableType.TYPE_BOOL:
			value = false
		VariableType.TYPE_FLOAT:
			value = 0.0
		VariableType.TYPE_INT:
			value = 0
		VariableType.TYPE_STRING:
			value = ""
	custom_properties[name] = {
		'name': name,
		'type': type,
		'value': value,
	}
	custom_properties_modified()


func remove_custom_property(name: String) -> void:
	custom_properties.erase(_strip_group(name))
	custom_properties_modified()


func custom_properties_modified():
	notify_property_list_changed()


func _get_property_list():
	var properties = []
	
	# Add the custom group
	properties.append({
		"name": "Custom",
		"type": TYPE_NIL,
		"hint_string": "custom_",
		"usage": PROPERTY_USAGE_GROUP,
	})
	
	for prop_name in custom_properties:
		var prop = custom_properties[prop_name]
		var t = TYPE_BOOL
		var hint = PROPERTY_HINT_NONE
		var hint_string = ""
		match prop['type']:
			VariableType.TYPE_INT:
				t = TYPE_INT
			VariableType.TYPE_FLOAT:
				t = TYPE_FLOAT
			VariableType.TYPE_STRING:
				t = TYPE_STRING
		properties.append({
			"name": "custom_%s" % prop_name,
			"type": t,
			"usage": PROPERTY_USAGE_EDITOR,
			"hint": hint,
			"hint_string": hint_string,
		})
	
	# Set the custom_properties property to read-only so the user
	# can't overwrite it. The details of the resource remain editable.
	properties.append({
		"name": "custom_properties",
		"type": TYPE_DICTIONARY,
		"usage": PROPERTY_USAGE_STORAGE + PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_READ_ONLY,
	})
	
	return properties


func _strip_group(property: String) -> String:
	if not property.begins_with("custom_"):
		return property
	return property.erase(0, len("custom_"))


func _get(property):
	if not property.begins_with("custom_"):
		return
	return custom_properties[
		_strip_group(property)
	]['value']


func _set(property, value):
	if not property.begins_with("custom_"):
		return false
	custom_properties[
		_strip_group(property)
	]['value'] = value
	return true

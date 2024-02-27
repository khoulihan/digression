@tool
@icon("res://addons/hyh.cutscene_graph/icons/icon_character.svg")
extends Resource

class_name Character


const PropertyCollection = preload("./properties/PropertyCollection.gd")
const PropertyUse = preload("../editor/inspector/character_property_edit/CharacterPropertySelector.gd").PropertyUse
const VariableType = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableType


## An identifier for the character when referenced in code.
@export
var character_name: String

## A optional display name for the character to present to the player.
@export
var character_display_name: String

## Character variant resources.
## Character variants describe different states that the character
## can be in during dialogue (e.g. moods)
@export
var character_variants: Array[CharacterVariant]

@export
var is_player: bool = false

var custom_properties: PropertyCollection = PropertyCollection.new()

var _character_variants


func _init() -> void:
	custom_properties.use_restriction = PropertyUse.CHARACTERS


func get_character_variants():
	if _character_variants == null:
		_character_variants = {}
		for v in character_variants:
			_character_variants[v.variant_name] = v
	return _character_variants


## Returns the display name and name, formatted for display in the editor.
func get_full_name() -> String:
	var display = self.character_display_name
	if display == null or display == "":
		display = "Unnamed Character"
	
	var actual = self.character_name
	if actual == null or actual == "":
		actual = "unnamed"
	
	return "%s (%s)" % [display, actual]


func _custom_properties_modified():
	notify_property_list_changed()


func _get_property_list():
	# I think this will not be necessary if the properties are stored directly
	# on this resource...
	if not custom_properties.property_list_changed.is_connected(_custom_properties_modified):
		custom_properties.property_list_changed.connect(_custom_properties_modified)
	print ("Getting resource property list")
	var properties = []
	# Set the custom_properties property to read-only so the user
	# can't overwrite it. The details of the resource remain editable.
	properties.append({
		"name": "custom_properties",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_STORAGE + PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_READ_ONLY,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "PropertyCollection",
	})
	
	properties.append({
		"name": "Custom",
		"type": TYPE_NIL,
		"hint_string": "custom_",
		"usage": PROPERTY_USAGE_GROUP,
	})
	
	for prop_name in custom_properties.properties:
		var prop = custom_properties.properties[prop_name]
		var t = TYPE_BOOL
		var hint = PROPERTY_HINT_NONE
		var hint_string = ""
		match prop.type:
			VariableType.TYPE_INT:
				t = TYPE_INT
				#hint = PROPERTY_HINT_RANGE
				#hint_string = "-1000,1000,1"
			VariableType.TYPE_FLOAT:
				t = TYPE_FLOAT
				#hint = PROPERTY_HINT_RANGE
				#hint_string = "-1000.0,1000.0,0.0001"
			VariableType.TYPE_STRING:
				t = TYPE_STRING
		properties.append({
			"name": "custom_%s" % prop_name,
			"type": t,
			"usage": PROPERTY_USAGE_EDITOR,
			"hint": hint,
			"hint_string": hint_string,
		})
				
	return properties


func _strip_group(property: String) -> String:
	if not property.begins_with("custom_"):
		return property
	return property.erase(0, len("custom_"))


func _get(property):
	if not property.begins_with("custom_"):
		return
	return custom_properties.properties[
		_strip_group(property)
	].value


func _set(property, value):
	if not property.begins_with("custom_"):
		return false
	custom_properties.properties[
		_strip_group(property)
	].value = value
	return true

@tool
@icon("../icons/icon_character.svg")
class_name Character extends Resource
## A character or entity to which dialogue can be assigned in a dialogue graph.


const PropertyUse = preload("../editor/dialogs/property_select_dialog/PropertySelectDialog.gd").PropertyUse
const VariableType = preload("graph/VariableSetNode.gd").VariableType

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

var custom_properties: Dictionary = {}

var _character_variants: Dictionary = {}


func _get_property_list() -> Array:
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


## Get a dictionary of the variants for this character with their names
## as the keys.
func get_character_variants() -> Dictionary:
	if len(_character_variants) == 0:
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


## Add a custom property to this character.
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
	_custom_properties_modified()


## Remove a custom property from this character.
func remove_custom_property(name: String) -> void:
	custom_properties.erase(_strip_group(name))
	_custom_properties_modified()


func _custom_properties_modified() -> void:
	notify_property_list_changed()


func _strip_group(property: String) -> String:
	if not property.begins_with("custom_"):
		return property
	return property.erase(0, len("custom_"))


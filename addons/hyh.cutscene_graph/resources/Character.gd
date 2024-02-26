@tool
@icon("res://addons/hyh.cutscene_graph/icons/icon_character.svg")
extends Resource

class_name Character


const PropertyCollection = preload("./properties/PropertyCollection.gd")
const PropertyUse = preload("../editor/inspector/character_property_edit/CharacterPropertySelector.gd").PropertyUse


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

@export
var custom_properties: PropertyCollection = PropertyCollection.new() # Array[CharacterProperty]

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


# Read-only usage flag did not work. This doesn't seem to work at all
# for a resource property.
#func _get_property_list():
	#var properties = []
	#properties.append({
		#"name": "custom_properties",
		#"type": Resource,
		#"usage": PROPERTY_USAGE_STORAGE + PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_READ_ONLY,
		#"hint": PROPERTY_HINT_RESOURCE_TYPE,
		#"hint_string": "PropertyCollection",
	#})
	#return properties

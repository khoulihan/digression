@tool
@icon("res://addons/hyh.cutscene_graph/icons/icon_portrait.svg")
extends Resource

class_name CharacterVariant

## An identifier for the variant to reference it in code.
@export
var variant_name: String

## An optional display name to represent the variant to the player.
@export
var variant_display_name: String


## Returns the display name and name, formatted for display in the editor.
func get_full_name() -> String:
	var display = self.variant_display_name
	if display == null or display == "":
		display = "Unnamed Variant"
	
	var actual = self.variant_name
	if actual == null or actual == "":
		actual = "unnamed"
	
	return "%s (%s)" % [display, actual]

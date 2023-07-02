@icon("res://addons/hyh.cutscene_graph/icons/icon_sprite.svg")
extends Resource

class_name Character

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

var _character_variants

func get_character_variants():
	if _character_variants == null:
		_character_variants = {}
		for v in character_variants:
			_character_variants[v.variant_name] = v
	return _character_variants

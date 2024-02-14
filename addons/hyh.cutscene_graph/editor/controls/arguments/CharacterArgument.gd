@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/arguments/Argument.gd"

@onready var CharacterOption = get_node("ExpressionContainer/PC/ArgumentValueContainer/GC/CharacterOption")
@onready var VariantOption = get_node("ExpressionContainer/PC/ArgumentValueContainer/GC/VariantOption")


var _characters


func configure():
	super()
	_populate_characters(_characters)


func set_characters(characters):
	_characters = characters


func get_selected_character():
	if CharacterOption.selected == -1:
		return null
	return _characters[CharacterOption.selected]


func get_selected_variant():
	if VariantOption.selected == -1:
		return null
	return _characters[CharacterOption.selected].character_variants[VariantOption.selected]


func set_character(character):
	if character == null:
		CharacterOption.selected = -1
		VariantOption.selected = -1
		return
	CharacterOption.select(_characters.find(character))
	if CharacterOption.selected != -1:
		_populate_variants(_characters[CharacterOption.selected].character_variants)


func set_variant(variant):
	if variant == null:
		VariantOption.selected = -1
		return
	VariantOption.select(
		_characters[CharacterOption.selected].character_variants.find(
			variant
		)
	)

func _populate_characters(characters):
	_characters = characters
	var selected = CharacterOption.selected
	CharacterOption.clear()
	for character in characters:
		CharacterOption.add_item(character.character_display_name)
	# TODO: What happens here if previously selected index is out of range?
	# Should determine name of selection beforehand and be sure to reselect that character, or null
	# selection if gone
	CharacterOption.select(selected)
	if CharacterOption.selected != -1:
		_populate_variants(_characters[CharacterOption.selected].character_variants)


func _populate_variants(variants):
	var selected = VariantOption.selected
	VariantOption.clear()
	if variants:
		for v in variants:
			VariantOption.add_item(v.variant_display_name)
		VariantOption.select(selected)


func _on_character_option_item_selected(index):
	if index == -1:
		_populate_variants(null)
		return
	var id = CharacterOption.get_item_id(index)
	var character = _characters[id]
	_populate_variants(character.character_variants)


func _on_variant_option_item_selected(index):
	CharacterOption.id


func _get_type_name():
	return "Character"

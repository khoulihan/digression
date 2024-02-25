@tool
extends EditorInspectorPlugin


const CharacterPropertySelector = preload("CharacterPropertySelector.gd")
const CharacterPropertyValueEdit = preload("CharacterPropertyValueEdit.gd")
const PropertyUse = CharacterPropertySelector.PropertyUse


func _can_handle(object: Variant) -> bool:
	return object is CharacterProperty or object is VariantProperty


func _parse_begin(object):
	var is_variant := object is VariantProperty
	var selector := CharacterPropertySelector.new()
	if is_variant:
		selector.use_restriction = PropertyUse.VARIANTS
	add_property_editor_for_multiple_properties(
		"Property",
		["property", "type"],
		selector,
	)


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "value":
		add_property_editor(name, CharacterPropertyValueEdit.new())
		return true
	if name == "property":
		return true
	if name == "type":
		# This could be achieved with property usage hints on the type
		return true
	return false

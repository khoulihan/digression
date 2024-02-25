@tool
extends EditorInspectorPlugin


var CharacterPropertySelector = preload("CharacterPropertySelector.gd")
var CharacterPropertyValueEdit = preload("CharacterPropertyValueEdit.gd")


func _can_handle(object: Variant) -> bool:
	return object is CharacterProperty


func _parse_begin(object):
	add_property_editor_for_multiple_properties(
		"Property",
		["property", "type"],
		CharacterPropertySelector.new(),
	)


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	print(name)
	if name == "value":
		add_property_editor(name, CharacterPropertyValueEdit.new())
		return true
	if name == "property":
		return true
	if name == "type":
		# This could be achieved with property usage hints on the type
		return true
	return false

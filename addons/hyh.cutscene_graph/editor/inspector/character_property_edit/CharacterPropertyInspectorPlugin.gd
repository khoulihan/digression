@tool
extends EditorInspectorPlugin


const PropertyCollection = preload("../../../resources/properties/PropertyCollection.gd")
const CharacterPropertySelector = preload("CharacterPropertySelector.gd")
const CharacterPropertyValueEdit = preload("CharacterPropertyValueEdit.gd")
const PropertyCollectionEditor = preload("PropertyCollectionEditor.tscn")
const PropertyUse = CharacterPropertySelector.PropertyUse


func _can_handle(object: Variant) -> bool:
	if object is Character:
		print("What a character!")
	return object is PropertyCollection


func _parse_begin(object):
	var property_edit := PropertyCollectionEditor.instantiate()
	add_custom_control(property_edit)
	await property_edit.ready
	print ("DOne awaitin")
	property_edit.property_collection = object
	return
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
	if name == "use_restriction":
		return false
	if name == "properties":
		return true
	return false

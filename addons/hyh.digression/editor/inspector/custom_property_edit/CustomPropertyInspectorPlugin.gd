@tool
extends EditorInspectorPlugin
## Inspector plugin for adding custom properties to DigressionDialogueGraphs,
## Characters, and CharacterVariants.


const Dialogs = preload("../../dialogs/Dialogs.gd")
const PropertyUse = preload("../../dialogs/property_select_dialog/PropertySelectDialog.gd").PropertyUse
const CustomEditorProperty = preload("CustomEditorProperty.gd")

var _add_property_button: Button


func _can_handle(object: Variant) -> bool:
	return object is Character \
		or object is CharacterVariant \
		or object is DigressionDialogueGraph


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "use_restriction":
		return false
	if name == "custom_properties":
		_add_property_button = Button.new()
		_add_property_button.text = "Add Custom Property"
		_add_property_button.icon = preload(
			"../../../icons/icon_add.svg"
		)
		_add_property_button.pressed.connect(
			_on_add_property_button_pressed.bind(object)
		)
		_add_property_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		add_custom_control(_add_property_button)
		return true
	if name.begins_with("custom_"):
		var actual_name: String = name.erase(0, len("custom_"))
		var property_edit = CustomEditorProperty.new(
			object.custom_properties[actual_name]['type']
		)
		property_edit.remove_requested.connect(
			_on_property_remove_requested.bind(object, actual_name)
		)
		add_property_editor(name, property_edit)
		return true
	return false


func _is_variant(object) -> bool:
	return object is CharacterVariant


func _is_graph(object) -> bool:
	return object is DigressionDialogueGraph


func _on_add_property_button_pressed(object) -> void:
	var restriction: PropertyUse
	if _is_variant(object):
		restriction = PropertyUse.VARIANTS
	if _is_graph(object):
		restriction = PropertyUse.DIALOGUE_GRAPHS
	else:
		restriction = PropertyUse.CHARACTERS

	var selected := await Dialogs.select_property(restriction)
	if not selected.is_empty():
		if not selected['name'] in object.custom_properties:
			object.add_custom_property(
				selected['name'],
				selected['type'],
			)



func _on_property_remove_requested(object, name) -> void:
	if await Dialogs.request_confirmation(
		"Are you sure you want to remove this property? This action cannot be undone."
	):
		object.remove_custom_property(name)

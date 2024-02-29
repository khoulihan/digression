@tool
extends EditorInspectorPlugin


const PropertyUse = preload("../../property_select_dialog/PropertySelectDialog.gd").PropertyUse
const PropertySelectDialog = preload("../../property_select_dialog/PropertySelectDialog.tscn")
const CustomEditorProperty = preload("CustomEditorProperty.gd")


var AddPropertyButton: Button


func _can_handle(object: Variant) -> bool:
	return object is Character \
		or object is CharacterVariant \
		or object is CutsceneGraph


func _is_variant(object) -> bool:
	return object is CharacterVariant


func _is_graph(object) -> bool:
	return object is CutsceneGraph


func _add_property_button_pressed(object) -> void:
	var dialog := PropertySelectDialog.instantiate()
	if _is_variant(object):
		dialog.use_restriction = PropertyUse.VARIANTS
	if _is_graph(object):
		dialog.use_restriction = PropertyUse.SCENES
	else:
		dialog.use_restriction = PropertyUse.CHARACTERS
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.cancelled.connect(
		_property_select_dialog_cancelled.bind(dialog)
	)
	dialog.selected.connect(
		_property_select_dialog_selected.bind(object, dialog)
	)
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup()


func _property_select_dialog_cancelled(dialog):
	EditorInterface.get_base_control().remove_child(dialog)
	dialog.queue_free()


func _property_select_dialog_selected(property, object, dialog):
	EditorInterface.get_base_control().remove_child(dialog)
	dialog.queue_free()
	if not property['name'] in object.custom_properties:
		object.add_custom_property(
			property['name'],
			property['type'],
		)


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "use_restriction":
		return false
	if name == "custom_properties":
		AddPropertyButton = Button.new()
		AddPropertyButton.text = "Add Custom Property"
		AddPropertyButton.icon = preload(
			"res://addons/hyh.cutscene_graph/icons/icon_add.svg"
		)
		AddPropertyButton.pressed.connect(
			_add_property_button_pressed.bind(object)
		)
		AddPropertyButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		add_custom_control(AddPropertyButton)
		return true
	if name.begins_with("custom_"):
		var actual_name: String = name.erase(0, len("custom_"))
		var property_edit = CustomEditorProperty.new(
			object.custom_properties[actual_name]['type']
		)
		property_edit.remove_requested.connect(
			_property_remove_requested.bind(object, actual_name)
		)
		add_property_editor(name, property_edit)
		return true
	return false


func _property_remove_requested(object, name) -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Please Confirm"
	dialog.dialog_text = "Are you sure you want to remove this property? This action cannot be undone."
	dialog.canceled.connect(_removal_cancelled.bind(dialog))
	dialog.confirmed.connect(_removal_confirmed.bind(object, name, dialog))
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()


func _removal_cancelled(dialog) -> void:
	EditorInterface.get_base_control().remove_child(dialog)
	dialog.queue_free()


func _removal_confirmed(object, name, dialog) -> void:
	EditorInterface.get_base_control().remove_child(dialog)
	dialog.queue_free()
	object.remove_custom_property(name)

@tool
extends MarginContainer
## Editor control for a Choice branch resource.


signal remove_requested()
signal modified()
signal preparing_to_change_parent()
signal dropped_after(section)
signal size_changed(size_change)


enum ChoiceMenuItems {
	SET_CONDITION,
	ADD_CUSTOM_PROPERTY,
	REGENERATE_TRANSLATION_KEY_FROM_TEXT,
}


const Logging = preload("../../utility/Logging.gd")
const ChoiceBranch = preload("../../resources/graph/branches/ChoiceBranch.gd")
const TranslationKey = preload("../../utility/TranslationKey.gd")
const HANDLE_ICON = preload("../../icons/icon_drag_light.svg")
const PREVIEW_LENGTH = 25

var choice_resource: ChoiceBranch

var _logger := Logging.new(
	Logging.DGE_EDITOR_LOG_NAME,
	Logging.DGE_EDITOR_LOG_LEVEL
)

@onready var _display_edit = $HB/VariableContainer/DisplayContainer/DisplayEdit
@onready var _translation_key_edit = $HB/VariableContainer/TranslationContainer/TranslationKeyEdit
@onready var _condition_control = $HB/ConditionControl
@onready var _custom_properties_control = $HB/CustomPropertiesControl
@onready var _menu_button: MenuButton = $HB/VariableContainer/TranslationContainer/MenuButton


func _ready() -> void:
	var popup := _menu_button.get_popup()
	popup.id_pressed.connect(_on_menu_id_pressed)
	if choice_resource != null:
		set_choice(choice_resource)


## Get the resource populated with the current values.
func get_choice() -> ChoiceBranch:
	choice_resource.display = _display_edit.text
	choice_resource.display_translation_key = _translation_key_edit.text
	choice_resource.condition = _condition_control.condition_resource
	choice_resource.custom_properties = _custom_properties_control.serialise()
	return choice_resource


## Assign a choice to the UI.
func set_choice(choice: ChoiceBranch) -> void:
	self.choice_resource = choice
	_condition_control.condition_resource = self.choice_resource.condition
	_display_edit.text = self.choice_resource.display
	_translation_key_edit.text = self.choice_resource.display_translation_key
	_populate_properties(self.choice_resource.custom_properties)


func prepare_to_change_parent():
	preparing_to_change_parent.emit()


func _populate_properties(properties: Dictionary) -> void:
	_custom_properties_control.configure(properties)


func get_drag_preview():
	var preview = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.texture = HANDLE_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	var ptext = Label.new()
	ptext.text = _get_drag_preview_text()
	preview.add_child(icon)
	preview.add_child(ptext)
	preview.modulate = Color.from_string("#777777FF", Color.DIM_GRAY)
	return preview


func _get_drag_preview_text():
	var preview_text = "Choice"
	var text = _display_edit.text.strip_edges()
	if text.is_empty():
		return preview_text
	var first_line = text.split("\n", false, 1)[0].strip_edges().strip_escapes()
	if len(first_line) > PREVIEW_LENGTH:
		first_line = "{0}...".format([first_line.substr(0, PREVIEW_LENGTH)])
	preview_text = "{0} (\"{1}\")".format([preview_text, first_line])
	return preview_text


func _on_remove_button_pressed() -> void:
	emit_signal("remove_requested")


func _on_display_edit_text_changed(new_text) -> void:
	modified.emit()


func _on_translation_key_edit_text_changed(new_text) -> void:
	modified.emit()


func _on_condition_control_size_changed(size_change) -> void:
	size_changed.emit(size_change)


func _on_custom_properties_control_add_property_requested(property_definition) -> void:
	var name = property_definition['name']
	if name in choice_resource.custom_properties:
		return
	var property = choice_resource.add_custom_property(
		property_definition['name'],
		property_definition['type'],
	)
	_custom_properties_control.add_property(property)


func _on_custom_properties_control_modified() -> void:
	modified.emit()


func _on_custom_properties_control_remove_property_requested(property_name) -> void:
	if not property_name in choice_resource.custom_properties:
		return
	choice_resource.remove_custom_property(property_name)
	_custom_properties_control.remove_property(property_name)


func _on_custom_properties_control_size_changed(size_change) -> void:
	size_changed.emit(size_change)


func _on_drag_target_dropped(arg: Variant, at_position: Variant) -> void:
	dropped_after.emit(arg)


func _on_menu_id_pressed(id: int) -> void:
	if id == ChoiceMenuItems.ADD_CUSTOM_PROPERTY:
		_custom_properties_control.request_property_and_add()
	elif id == ChoiceMenuItems.REGENERATE_TRANSLATION_KEY_FROM_TEXT:
		choice_resource.display_translation_key = TranslationKey.generate_from_text(
			choice_resource.display,
		)
		_translation_key_edit.text = choice_resource.display_translation_key
	elif id == ChoiceMenuItems.SET_CONDITION:
		if _condition_control.condition_resource == null:
			_condition_control.configure_for_new_condition()


func _on_menu_button_about_to_popup() -> void:
	var popup := _menu_button.get_popup()
	popup.set_item_disabled(
		ChoiceMenuItems.SET_CONDITION,
		_condition_control.condition_resource != null
	)

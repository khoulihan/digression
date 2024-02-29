@tool
extends MarginContainer

const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

const ChoiceBranch = preload("../../resources/graph/branches/ChoiceBranch.gd")

@onready var DisplayEdit = get_node("HBoxContainer/VariableContainer/DisplayContainer/DisplayEdit")
@onready var TranslationKeyEdit = get_node("HBoxContainer/VariableContainer/DisplayContainer/TranslationKeyEdit")
@onready var ConditionControl = get_node("HBoxContainer/ConditionControl")
@onready var CustomPropertiesControl = get_node("HBoxContainer/CustomPropertiesControl")


signal remove_requested()
signal modified()
signal size_changed(size_change)


var choice_resource


func _ready():
	if choice_resource != null:
		set_choice(choice_resource)


func get_choice():
	choice_resource.display = DisplayEdit.text
	choice_resource.display_translation_key = TranslationKeyEdit.text
	choice_resource.condition = ConditionControl.condition_resource
	choice_resource.custom_properties = CustomPropertiesControl.serialise()
	return choice_resource


func set_choice(choice):
	self.choice_resource = choice
	ConditionControl.condition_resource = self.choice_resource.condition
	DisplayEdit.text = self.choice_resource.display
	TranslationKeyEdit.text = self.choice_resource.display_translation_key
	_populate_properties(self.choice_resource.custom_properties)


func _populate_properties(properties: Dictionary) -> void:
	CustomPropertiesControl.configure(properties)


func _on_RemoveButton_pressed():
	emit_signal("remove_requested")


func _on_DisplayEdit_text_changed(new_text):
	modified.emit()


func _on_TranslationKeyEdit_text_changed(new_text):
	modified.emit()


func _on_condition_control_size_changed(size_change):
	size_changed.emit(size_change)


func _on_custom_properties_control_add_property_requested(property_definition):
	var name = property_definition['name']
	if name in choice_resource.custom_properties:
		return
	var property = choice_resource.add_custom_property(
		property_definition['name'],
		property_definition['type'],
	)
	CustomPropertiesControl.add_property(property)


func _on_custom_properties_control_modified():
	modified.emit()


func _on_custom_properties_control_remove_property_requested(property_name):
	if not property_name in choice_resource.custom_properties:
		return
	choice_resource.remove_custom_property(property_name)
	CustomPropertiesControl.remove_property(property_name)


func _on_custom_properties_control_size_changed(size_change):
	size_changed.emit(size_change)

@tool
extends MarginContainer

const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

const ChoiceBranch = preload("../../resources/graph/branches/ChoiceBranch.gd")

@onready var DisplayEdit = get_node("HBoxContainer/VariableContainer/DisplayContainer/DisplayEdit")
@onready var TranslationKeyEdit = get_node("HBoxContainer/VariableContainer/DisplayContainer/TranslationKeyEdit")
@onready var ConditionControl = get_node("HBoxContainer/ConditionControl")


signal remove_requested()
signal modified()
signal set_condition_requested()
signal edit_condition_requested()
signal clear_condition_requested()


var choice_resource


func get_choice():
	choice_resource.display = DisplayEdit.text
	choice_resource.display_translation_key = TranslationKeyEdit.text
	choice_resource.condition = ConditionControl.condition_resource
	return choice_resource


func set_choice(choice):
	self.choice_resource = choice
	ConditionControl.condition_resource = self.choice_resource.condition
	DisplayEdit.text = self.choice_resource.display
	TranslationKeyEdit.text = self.choice_resource.display_translation_key


func _on_RemoveButton_pressed():
	emit_signal("remove_requested")


func _on_DisplayEdit_text_changed(new_text):
	emit_signal("modified")


func _on_TranslationKeyEdit_text_changed(new_text):
	emit_signal("modified")


func _on_conditional_control_set_condition_requested():
	emit_signal("set_condition_requested")

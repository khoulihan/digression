@tool
extends MarginContainer

const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType


signal value_changed()


@onready var LineEditControl = get_node("HBoxContainer/EditContainer/LineEdit")
@onready var SpinBoxControl = get_node("HBoxContainer/EditContainer/SpinBox")
@onready var CheckBoxControl = get_node("HBoxContainer/EditContainer/CheckBox")
@onready var ValidationWarning = get_node("HBoxContainer/ValidationWarning")

# TODO: Setting this in the inspector does not work because the controls are not
# ready when it is set at runtime
@export var variable_type: VariableType = VariableType.TYPE_BOOL:
	get:
		return variable_type
	set(t):
		variable_type = t
		_configure_for_type()


func _ready():
	_configure_for_type()
	clear_validation_warning()


func set_variable_type(t):
	variable_type = t
	_configure_for_type()


func _configure_for_type():
	LineEditControl.visible = variable_type == VariableType.TYPE_STRING
	SpinBoxControl.visible = variable_type == VariableType.TYPE_INT or variable_type == VariableType.TYPE_FLOAT
	CheckBoxControl.visible = variable_type == VariableType.TYPE_BOOL
	if variable_type == VariableType.TYPE_INT or variable_type == VariableType.TYPE_FLOAT:
		SpinBoxControl.rounded = (variable_type == VariableType.TYPE_INT)
		if variable_type == VariableType.TYPE_INT:
			SpinBoxControl.step = 1
			SpinBoxControl.value = SpinBoxControl.value as int
		else:
			SpinBoxControl.step = 0.0001


func clear_values():
	CheckBoxControl.button_pressed = true
	LineEditControl.text = ""
	SpinBoxControl.value = 0


func set_value(val):
	clear_values()
	match variable_type:
		VariableType.TYPE_BOOL:
			if val == null:
				CheckBoxControl.button_pressed = true
			else:
				CheckBoxControl.button_pressed = val
		VariableType.TYPE_STRING:
			if val == null:
				LineEditControl.text = ""
			else:
				LineEditControl.text = val
		VariableType.TYPE_INT, VariableType.TYPE_FLOAT:
			if val == null:
				SpinBoxControl.value = 0
			else:
				SpinBoxControl.value = val


func get_value():
	match variable_type:
		VariableType.TYPE_BOOL:
			return CheckBoxControl.button_pressed
		VariableType.TYPE_STRING:
			return LineEditControl.text
		VariableType.TYPE_INT:
			return SpinBoxControl.value as int
		VariableType.TYPE_FLOAT:
			return SpinBoxControl.value as float


func set_validation_warning(t):
	ValidationWarning.set_warning(t)


func clear_validation_warning():
	ValidationWarning.clear_warning()


func _on_CheckBox_pressed():
	emit_signal("value_changed")


func _on_SpinBox_value_changed(value):
	emit_signal("value_changed")


func _on_LineEdit_text_changed(new_text):
	emit_signal("value_changed")


func _on_SpinBox_changed():
	emit_signal("value_changed")

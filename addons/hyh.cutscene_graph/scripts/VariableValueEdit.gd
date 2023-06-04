@tool
extends MarginContainer

const Logging = preload("../scripts/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

const VariableType = preload("../resources/VariableSetNode.gd").VariableType


signal value_changed()


@onready var LineEditControl = get_node("LineEdit")
@onready var SpinBoxControl = get_node("SpinBox")
@onready var CheckBoxControl = get_node("CheckBox")


var _variable_type = VariableType.TYPE_BOOL


func _ready():
	_configure_for_type()


func set_variable_type(t):
	_variable_type = t
	_configure_for_type()


func _configure_for_type():
	LineEditControl.visible = _variable_type == VariableType.TYPE_STRING
	SpinBoxControl.visible = _variable_type == VariableType.TYPE_INT or _variable_type == VariableType.TYPE_FLOAT
	CheckBoxControl.visible = _variable_type == VariableType.TYPE_BOOL
	if _variable_type == VariableType.TYPE_INT or _variable_type == VariableType.TYPE_FLOAT:
		SpinBoxControl.rounded = (_variable_type == VariableType.TYPE_INT)
		if _variable_type == VariableType.TYPE_INT:
			SpinBoxControl.step = 1
			SpinBoxControl.value = SpinBoxControl.value as int
		else:
			SpinBoxControl.step = 0.0001


func set_value(val):
	match _variable_type:
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
	match _variable_type:
		VariableType.TYPE_BOOL:
			return CheckBoxControl.button_pressed
		VariableType.TYPE_STRING:
			return LineEditControl.text
		VariableType.TYPE_INT:
			Logger.debug("Variable int value: %s" % (SpinBoxControl.value as int))
			return SpinBoxControl.value as int
		VariableType.TYPE_FLOAT:
			Logger.debug("Variable float value: %s" % (SpinBoxControl.value as float))
			return SpinBoxControl.value as float


func _on_CheckBox_pressed():
	emit_signal("value_changed")


func _on_SpinBox_value_changed(value):
	emit_signal("value_changed")


func _on_LineEdit_text_changed(new_text):
	emit_signal("value_changed")


func _on_SpinBox_changed():
	emit_signal("value_changed")

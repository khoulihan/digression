@tool
extends MarginContainer
## Control for a branch in a Match Branch node.


signal remove_requested()
signal modified()

const Logging = preload("../../utility/Logging.gd")
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

var _logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)
var _type: VariableType

@onready var _value_edit = $VB/HorizontalLayout/GridContainer/ValueEdit


func _ready() -> void:
	if _type != null:
		_value_edit.set_variable_type(_type)


## Set the type of the variable involved with the parent node.
func set_type(t: VariableType) -> void:
	_type = t
	if _value_edit != null:
		_value_edit.set_variable_type(t)


## Set the current value to match.
func set_value(val: Variant) -> void:
	if val != null:
		if typeof(val) == TYPE_DICTIONARY:
			_value_edit.set_variable(val, true)
		else:
			_value_edit.set_value(val)


## Get the current value from the UI.
func get_value() -> Variant:
	if _value_edit.is_selecting_variable():
		return _value_edit.get_selected_variable()
	return _value_edit.get_value()


func _on_remove_button_pressed() -> void:
	remove_requested.emit()


func _on_value_edit_value_changed() -> void:
	modified.emit()

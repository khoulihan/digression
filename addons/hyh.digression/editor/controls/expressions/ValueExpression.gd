@tool
extends "MoveableExpression.gd"
## An expression that represents a single value.


const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType

@onready var _value_edit = $PanelContainer/MC/ExpressionContainer/Header/VariableValueEdit


## Configure the expression.
func configure():
	super()
	_value_edit.variable_type = type


## Validate the expression.
func validate():
	if _value_edit.is_selecting_variable():
		if _value_edit.get_selected_variable() == null:
			_validation_warning.visible = true
			_validation_warning.tooltip_text = "You must select a variable, or enter a constant value."
			return "Variable not selected."
	_validation_warning.visible = false


## Serialise the expression to a dictionary.
func serialise():
	var exp = super()
	exp["expression_type"] = ExpressionType.VALUE
	if _value_edit.is_selecting_variable():
		exp["variable"] = _value_edit.get_selected_variable()
	else:
		exp["value"] = _value_edit.get_value()
	return exp


## Deserialise an expression dictionary.
func deserialise(serialised):
	super(serialised)
	_value_edit.set_variable_type(type)
	if "variable" in serialised:
		_value_edit.set_variable(serialised["variable"], true)
	else:
		_value_edit.set_value(serialised["value"])


func _on_variable_value_edit_value_changed():
	modified.emit()

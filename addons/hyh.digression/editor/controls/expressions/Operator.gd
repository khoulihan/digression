@tool
extends MarginContainer


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const OperatorType = preload("../../../resources/graph/expressions/ExpressionResource.gd").OperatorType
const ExpressionOperators = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionOperators
const ExpressionComponentType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionComponentType

const ADD_ICON = preload("../../../icons/icon_add_dark.svg")
const SUBTRACT_ICON = preload("../../../icons/icon_subtract_dark.svg")
const MULTIPLY_ICON = preload("../../../icons/icon_close_dark.svg")
const DIVIDE_ICON = preload("../../../icons/icon_divide_dark.svg")

## The type of variable operated on.
@export
var variable_type : VariableType

## The type of the operator (comparison vs operation).
@export
var operator_type : OperatorType

@onready var _options : OptionButton = $OperatorOptionButton


## Configure the expression.
func configure():
	_options.clear()
	if operator_type == OperatorType.COMPARISON:
		_populate_comparison_operators()
		return
	
	match variable_type:
		VariableType.TYPE_BOOL:
			_populate_boolean_operators()
		VariableType.TYPE_INT, VariableType.TYPE_FLOAT:
			_populate_numeric_operators()
		VariableType.TYPE_STRING:
			_populate_string_operators()


## Serialise the expression to a dictionary.
func serialise():
	return {
		"component_type": ExpressionComponentType.OPERATOR,
		"variable_type": variable_type,
		"operator_type": operator_type,
		"operator": _options.get_selected_id()
	}


## Deserialise an expression dictionary.
func deserialise(serialised):
	variable_type = serialised["variable_type"]
	operator_type = serialised["operator_type"]
	_options.select(_options.get_item_index(serialised["operator"]))


func _populate_boolean_operators():
	_options.add_item("And", ExpressionOperators.BOOL_AND)
	_options.add_item("Or", ExpressionOperators.BOOL_OR)


func _populate_numeric_operators():
	_options.add_icon_item(
		ADD_ICON,
		"",
		ExpressionOperators.NUMERIC_ADD
	)
	_options.add_icon_item(
		SUBTRACT_ICON,
		"",
		ExpressionOperators.NUMERIC_SUBTRACT
	)
	_options.add_icon_item(
		MULTIPLY_ICON,
		"",
		ExpressionOperators.NUMERIC_MULTIPLY
	)
	_options.add_icon_item(
		DIVIDE_ICON,
		"",
		ExpressionOperators.NUMERIC_DIVIDE
	)


func _populate_string_operators():
	_options.add_icon_item(
		ADD_ICON,
		"",
		ExpressionOperators.STRING_CONCATENATE
	)
	_options.add_icon_item(
		ADD_ICON,
		"(with space)",
		ExpressionOperators.STRING_CONCATENATE_WITH_SPACE
	)


func _populate_comparison_operators():
	# TODO: Would like icons for all these
	_options.add_item("==", ExpressionOperators.COMPARISON_EQUALS)
	_options.add_item("!=", ExpressionOperators.COMPARISON_NOT_EQUALS)
	_options.add_item(">", ExpressionOperators.COMPARISON_GREATER_THAN)
	_options.add_item(">=", ExpressionOperators.COMPARISON_GREATER_THAN_OR_EQUALS)
	_options.add_item("<", ExpressionOperators.COMPARISON_LESS_THAN)
	_options.add_item("<=", ExpressionOperators.COMPARISON_LESS_THAN_OR_EQUALS)

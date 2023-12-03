@tool
extends MarginContainer


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType

const AddIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_add.svg")
const SubtractIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_subtract.svg")
const MultiplyIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_close.svg")
const DivideIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_divide.svg")

@onready var _options : OptionButton = get_node("OperatorOptionButton")


@export
var variable_type : VariableType

@export
var operator_type : OperatorType


enum ExpressionOperators {
	BOOL_AND,
	BOOL_OR,
	NUMERIC_ADD,
	NUMERIC_SUBTRACT,
	NUMERIC_MULTIPLY,
	NUMERIC_DIVIDE,
	STRING_CONCATENATE,
	STRING_CONCATENATE_WITH_SPACE,
}

enum OperatorType {
	OPERATION,
	COMPARISON,
}


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


func _populate_boolean_operators():
	_options.add_item("And", ExpressionOperators.BOOL_AND)
	_options.add_item("Or", ExpressionOperators.BOOL_OR)


func _populate_numeric_operators():
	_options.add_icon_item(
		AddIcon,
		"",
		ExpressionOperators.NUMERIC_ADD
	)
	_options.add_icon_item(
		SubtractIcon,
		"",
		ExpressionOperators.NUMERIC_SUBTRACT
	)
	_options.add_icon_item(
		MultiplyIcon,
		"",
		ExpressionOperators.NUMERIC_MULTIPLY
	)
	_options.add_icon_item(
		DivideIcon,
		"",
		ExpressionOperators.NUMERIC_DIVIDE
	)


func _populate_string_operators():
	_options.add_icon_item(
		AddIcon,
		"",
		ExpressionOperators.STRING_CONCATENATE
	)
	_options.add_icon_item(
		AddIcon,
		"(with space)",
		ExpressionOperators.STRING_CONCATENATE_WITH_SPACE
	)


func _populate_comparison_operators():
	# TODO: Add the comparison operators
	pass

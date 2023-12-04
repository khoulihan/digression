@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"


# TODO: Maybe these are a problem?
const GroupExpression = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/GroupExpression.tscn")
const OperatorExpression = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/OperatorExpression.tscn")

const FunctionType = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/ExpressionEnums.gd").FunctionType

@onready var _arguments_container : VBoxContainer = get_node("PanelContainer/MC/ExpressionContainer/MC/ArgumentsContainer")


@export var function_type : FunctionType


const _functions = {
	VariableType.TYPE_BOOL: {
		FunctionType.NOT: {
			"display": "not ( x )",
			"arguments": {
				"x": VariableType.TYPE_BOOL,
			}
		}
	},
	VariableType.TYPE_INT: {
		FunctionType.MIN: {
			"display": "min ( ... )",
			"arguments": VariableType.TYPE_INT,
		},
		FunctionType.MAX: {
			"display": "max ( ... )",
			"arguments": VariableType.TYPE_INT,
		}
	},
	VariableType.TYPE_FLOAT: {
		FunctionType.MIN: {
			"display": "min ( ... )",
			"arguments": VariableType.TYPE_FLOAT,
		},
		FunctionType.MAX: {
			"display": "max ( ... )",
			"arguments": VariableType.TYPE_FLOAT,
		}
	},
	VariableType.TYPE_STRING: {
		FunctionType.CONTAINS: {
			"display": "contains ( in, query )",
			"arguments": {
				"in": VariableType.TYPE_STRING,
				"query": VariableType.TYPE_STRING,
			}
		},
		FunctionType.TO_LOWER: {
			"display": "to_lower ( what )",
			"arguments": {
				"what": VariableType.TYPE_STRING,
			}
		},
	},
}


func _ready():
	_panel.remove_theme_stylebox_override("panel")


func configure():
	super()
	var function_spec = _functions[type][function_type]
	set_title(function_spec["display"])
	var arguments = function_spec.get("arguments", null)
	var args_type = typeof(arguments)
	if args_type == TYPE_NIL:
		# No arguments
		pass
	elif args_type == TYPE_DICTIONARY:
		# Enumerated, named arguments
		_add_named_arguments(arguments)
	else:
		# Set of arguments of specified type
		_add_set_arguments(arguments)


func _add_named_arguments(args):
	for arg in args:
		var arg_name = Label.new()
		arg_name.text = "%s:" % arg
		_arguments_container.add_child(arg_name)
		var arg_expression = OperatorExpression.instantiate()
		arg_expression.type = args[arg]
		_arguments_container.add_child(arg_expression)
		arg_expression.configure()


func _add_set_arguments(type):
	var group = GroupExpression.instantiate()
	group.type = type
	_arguments_container.add_child(group)
	group.configure()


func validate():
	# TODO: Check all arguments are valid for the selected function
	return null

@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"


# TODO: Maybe these are a problem?
const GroupExpression = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/GroupExpression.tscn")
const OperatorExpression = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/OperatorExpression.tscn")

const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType
const FunctionType = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd").FunctionType
const FUNCTIONS = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd").EXPRESSION_FUNCTIONS


@onready var _arguments_container : VBoxContainer = get_node("PanelContainer/MC/ExpressionContainer/MC/ArgumentsContainer")


@export var function_type : FunctionType


func _ready():
	_panel.remove_theme_stylebox_override("panel")


func configure():
	super()
	var function_spec = FUNCTIONS[type][function_type]
	set_title(
		function_spec["display"],
		function_spec["tooltip"]
	)
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


func serialise():
	var exp = super()
	exp["expression_type"] = ExpressionType.FUNCTION
	exp["function_type"] = function_type
	exp["arguments"] = _serialise_arguments()
	return exp


func _serialise_arguments():
	var spec = FUNCTIONS[type][function_type]
	var spec_args = spec["arguments"]
	if spec_args == null:
		# No arguments - unlikely, but ok
		return null
	if typeof(spec_args) == TYPE_DICTIONARY:
		# Named arguments
		var args = {}
		# Every second child of the arguments container will be an expression
		for i in range(0, spec_args.size()):
			args[spec_args.keys()[i]] = _arguments_container.get_child((i*2) + 1).serialise()
		return args
	# Collection of arguments
	var arg_array = []
	for child in _arguments_container.get_children():
		arg_array.append(child.serialise())
	return arg_array
	
	
func deserialise(serialised):
	super(serialised)
	pass


# TODO: Might only need this for testing?
func clear():
	pass

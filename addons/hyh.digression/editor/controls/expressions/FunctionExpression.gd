@tool
extends "MoveableExpression.gd"
## Expression that executes a built-in function.


# TODO: Maybe these are a problem?
const GroupExpression = preload("GroupExpression.tscn")
const OperatorExpression = preload("OperatorExpression.tscn")
const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType
const FunctionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").FunctionType
const FUNCTIONS = preload("../../../resources/graph/expressions/ExpressionResource.gd").EXPRESSION_FUNCTIONS
const GROUP_PANEL_STYLE = preload("group_panel_style.tres")

## The type of the function.
@export var function_type : FunctionType

@onready var _arguments_container : VBoxContainer = $PanelContainer/MC/ExpressionContainer/MC/ArgumentsContainer


func _ready():
	_panel.add_theme_stylebox_override("panel", GROUP_PANEL_STYLE)


## Configure the expression.
func configure():
	if _arguments_container.get_child_count() > 0:
		# Already configured
		return
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
		var defaults = function_spec.get("defaults", {})
		# Enumerated, named arguments
		_add_named_arguments(arguments, defaults)
	else:
		# Set of arguments of specified type
		_add_set_arguments(arguments)


## Validate the expression.
func validate():
	var validation_result = _validate()
	if validation_result == null:
		_validation_warning.visible = false
		return null
	
	_validation_warning.visible = true
	if typeof(validation_result) == TYPE_STRING:
		_validation_warning.tooltip_text = validation_result
	else:
		if len(validation_result) > 1:
			_validation_warning.tooltip_text = "Invalid arguments."
		else:
			_validation_warning.tooltip_text = "Invalid argument."
	
	return validation_result


## Serialise the expression to a dictionary.
func serialise():
	var exp = super()
	exp["expression_type"] = ExpressionType.FUNCTION
	exp["function_type"] = function_type
	exp["arguments"] = _serialise_arguments()
	return exp


## Deserialise an expression dictionary.
func deserialise(serialised):
	super(serialised)
	function_type = serialised["function_type"]
	# This will create the argument expressions for us to populate
	configure()
	var arguments = serialised["arguments"]
	_deserialise_arguments(arguments)


# TODO: Might only need this for testing?
## Clear the expression of all children.
func clear():
	pass


func _add_named_arguments(args, defaults):
	for arg in args:
		var arg_name = Label.new()
		arg_name.text = "%s:" % arg
		_arguments_container.add_child(arg_name)
		var arg_type = typeof(args[arg])
		var has_default = arg in defaults
		
		if arg_type == TYPE_ARRAY:
			var group = GroupExpression.instantiate()
			group.type = args[arg][0]
			_arguments_container.add_child(group)
			group.allow_empty = has_default
			group.configure()
			group.modified.connect(_argument_expression_modified)
			group.size_changed.connect(_argument_expression_size_changed)
		else:
			var arg_expression = OperatorExpression.instantiate()
			arg_expression.type = args[arg]
			_arguments_container.add_child(arg_expression)
			arg_expression.allow_empty = has_default
			arg_expression.configure()
			arg_expression.modified.connect(_argument_expression_modified)
			arg_expression.size_changed.connect(_argument_expression_size_changed)


func _add_set_arguments(type):
	var group = GroupExpression.instantiate()
	group.type = type
	_arguments_container.add_child(group)
	group.configure()
	group.modified.connect(_argument_expression_modified)
	group.size_changed.connect(_argument_expression_size_changed)


func _argument_expression_modified():
	modified.emit()


func _argument_expression_size_changed(amount):
	size_changed.emit(amount)


func _validate():
	var spec = FUNCTIONS[type][function_type]
	var spec_args = spec["arguments"]
	if spec_args == null:
		# No arguments - unlikely, but ok
		return null
	if typeof(spec_args) == TYPE_DICTIONARY:
		# Named arguments
		var child_warnings = []
		# Every second child of the arguments container will be an expression
		for i in range(0, spec_args.size()):
			var arg_val = _arguments_container.get_child((i*2) + 1).validate()
			if arg_val != null:
				child_warnings.append(arg_val)
		if len(child_warnings) == 0:
			return null
		else:
			return child_warnings
	# Collection of arguments - but it is just one GroupExpression
	var group = _arguments_container.get_child(0)
	var group_validation = group.validate()
	if typeof(group_validation) == TYPE_STRING:
		# Dodgy assumption that this is what a string response means...
		return "Argument list is empty."
	return group_validation


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
	# Collection of arguments - but it is just one GroupExpression
	return _arguments_container.get_child(0).serialise()


func _deserialise_arguments(serialised):
	var spec = FUNCTIONS[type][function_type]
	var spec_args = spec["arguments"]
	if spec_args == null:
		# No arguments - unlikely, but ok
		return null
	if typeof(spec_args) == TYPE_DICTIONARY:
		# Named arguments
		for i in range(0, len(spec_args.keys())):
			var k = spec_args.keys()[i]
			var arg = serialised[k]
			_arguments_container.get_child((i * 2) + 1).deserialise(arg)
		return
	# Collection of arguments - but it is just one GroupExpression
	var group = _arguments_container.get_child(0)
	group.deserialise(serialised)

@tool
extends RefCounted
## Class for evaluating expressions at runtime.


const Logging = preload("../../utility/Logging.gd")
const ExpressionComponentType = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd").ExpressionComponentType
const ExpressionType = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd").ExpressionType
const FunctionType = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd").FunctionType
const ExpressionOperators = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd").ExpressionOperators
const OperatorType = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd").OperatorType
const EXPRESSION_FUNCTIONS = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd").EXPRESSION_FUNCTIONS
const VariableType = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableType
const VariableScope = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableScope

var transient_store : Dictionary
var cutscene_state_store : Dictionary
var global_store : Node
var local_store : Node

var _logger = Logging.new("Expression Evaluator", Logging.CGE_NODES_LOG_LEVEL)


## Evaluate the provided expression.
func evaluate(expression):
	var component_type = expression["component_type"]
	if component_type != ExpressionComponentType.EXPRESSION:
		_logger.error("Cannot evaluate this type of expression in isolation.")
		return null
	var variable_type = expression["variable_type"]
	var expression_type = expression["expression_type"]
	match expression_type:
		ExpressionType.VALUE:
			return _evaluate_value(variable_type, expression)
		ExpressionType.COMPARISON:
			return _evaluate_comparison(variable_type, expression)
		ExpressionType.FUNCTION:
			return _evaluate_function(variable_type, expression)
		ExpressionType.BRACKETS:
			return _evaluate_brackets(variable_type, expression)
		ExpressionType.GROUP:
			# Not sure what this would mean actually...
			return _evaluate_group(variable_type, expression)
		ExpressionType.OPERATOR_GROUP:
			return _evaluate_operator_group(variable_type, expression)


func _evaluate_value(variable_type, expression):
	if "variable" in expression:
		var variable = expression["variable"]
		return _get_variable(
			variable['name'],
			variable['scope'],
		)
	else:
		return expression["value"]
	_logger.error("Not a valid value expression.")


func _evaluate_comparison(variable_type, expression):
	# The type is redundant here - the result can only be boolean!
	# The sides will be operator groups, but of the `comparison_type`
	# instead of the `variable_type` of the parent.
	var comparison_type = expression["comparison_type"]
	var left = _evaluate_operator_group(
		comparison_type,
		expression["left_expression"]
	)
	var right = _evaluate_operator_group(
		comparison_type,
		expression["right_expression"]
	)
	var operator = expression["comparison_operator"]["operator"]
	match operator:
		ExpressionOperators.COMPARISON_EQUALS:
			return left == right
		ExpressionOperators.COMPARISON_GREATER_THAN:
			return left > right
		ExpressionOperators.COMPARISON_GREATER_THAN_OR_EQUALS:
			return left >= right
		ExpressionOperators.COMPARISON_LESS_THAN:
			return left < right
		ExpressionOperators.COMPARISON_LESS_THAN_OR_EQUALS:
			return left <= right
		ExpressionOperators.COMPARISON_NOT_EQUALS:
			return left != right
	# Ruh-roh
	_logger.error("Unsupported operator in comparison expression.")
	return null


func _evaluate_function(variable_type, expression):
	# This function will basically just need to branch to various more specific
	# functions for each function (or maybe function type), and could probably
	# pull out the arguments based on the function spec as well?
	var function_type = expression["function_type"]
	var function_spec = EXPRESSION_FUNCTIONS[variable_type][function_type]
	if function_spec == null:
		_logger.error("Unrecognised function in serialised expression.")
		return null
	var arguments_spec = function_spec["arguments"]
	var exp_arguments = expression["arguments"]
	var arguments
	if typeof(arguments_spec) == TYPE_DICTIONARY:
		arguments = {}
		for key in arguments_spec.keys():
			arguments[key] = evaluate(exp_arguments[key])
	else:
		arguments = _evaluate_group(arguments_spec, expression["arguments"])
	
	return _match_function(
		variable_type,
		function_type,
		expression,
		function_spec,
		arguments
	)


func _match_function(
	variable_type,
	function_type,
	expression,
	function_spec,
	arguments
):
	match variable_type:
		VariableType.TYPE_BOOL:
			return _match_bool_function(
				function_type,
				expression,
				function_spec,
				arguments
			)
		VariableType.TYPE_INT, VariableType.TYPE_FLOAT:
			return _match_numeric_function(
				variable_type,
				function_type,
				expression,
				function_spec,
				arguments
			)
		VariableType.TYPE_STRING:
			return _match_string_function(
				function_type,
				expression,
				function_spec,
				arguments
			)


func _match_bool_function(
	function_type,
	expression,
	function_spec,
	arguments
):
	match function_type:
		FunctionType.NOT:
			return not arguments["x"]
		FunctionType.CONTAINS:
			return arguments["in"].contains(arguments["query"])
	_logger.error("Unrecognised boolean function type.")
	return null


func _match_numeric_function(
	variable_type,
	function_type,
	expression,
	function_spec,
	arguments
):
	match function_type:
		FunctionType.MIN:
			return arguments.min()
		FunctionType.MAX:
			return arguments.max()
	_logger.error("Unrecognised numeric function type.")
	return null


func _match_string_function(
	function_type,
	expression,
	function_spec,
	arguments
):
	match function_type:
		FunctionType.TO_LOWER:
			return arguments["what"].to_lower()
	_logger.error("Unrecognised string function type.")
	return null


func _evaluate_brackets(variable_type, expression):
	# The child expression needs to do the work here.
	# And, the child can only be an operator group.
	return _evaluate_operator_group(variable_type, expression["contents"])


func _evaluate_group(variable_type, expression):
	# Group expressions only make sense in a context that gives them meaning
	# e.g. as a list of arguments to a function.
	# Evaluating one returns a list with all child expressions evaluated.
	var children = expression["children"]
	var result = []
	for child in children:
		result.append(evaluate(child))
	return result


func _evaluate_operator_group(variable_type, expression):
	# This function needs to first evaluate all child expressions, then apply
	# the operators in order of precedence.
	var serialised_children = expression["children"]
	var evaluated = []
	for child in serialised_children:
		if child["component_type"] == ExpressionComponentType.OPERATOR:
			evaluated.append(child)
			continue
		evaluated.append(evaluate(child))
	
	# Now we have child expressions evaluated, connected by operators.
	# Operator precedence is multiplication and division before addition and
	# subtraction, and before or for booleans. Any other operators will
	# currently be implemented as functions so don't need to worry about those.
	# The two string concatenation operators have equal precedence and would
	# only strictly require one pass to deal with, so the second pass does
	# nothing for string expressions.
	var result = _evaluate_operator_types(
		_evaluate_operator_types(
			evaluated,
			[
				ExpressionOperators.NUMERIC_MULTIPLY,
				ExpressionOperators.NUMERIC_DIVIDE,
				ExpressionOperators.BOOL_AND,
				ExpressionOperators.STRING_CONCATENATE,
				ExpressionOperators.STRING_CONCATENATE_WITH_SPACE,
			],
		),
		[
			ExpressionOperators.NUMERIC_ADD,
			ExpressionOperators.NUMERIC_SUBTRACT,
			ExpressionOperators.BOOL_OR
		],
	)
	if len(result) > 1:
		_logger.error("Expression was not fully evaluated.")
	return result[0]


func _evaluate_operator_types(expression_group, operators):
	var result = expression_group.duplicate()
	if len(result) < 3:
		# No operators present
		return result
	var completed = false
	# This loop might be a little bit dodgy if anything goes wrong?
	# Adding a counter as well to exit if too many iterations occur.
	var loops = 0
	while not completed:
		loops += 1
		for child in result:
			if _is_in_operator_list(child, operators):
				var op = child["operator"]
				var op_index = result.find(child)
				var left = result[op_index - 1]
				var right = result[op_index + 1]
				var value = _apply_operator(op, left, right)
				for i in range(op_index + 1, op_index - 2, -1):
					result.remove_at(i)
				result.insert(op_index - 1, value)
				# Need to start over because the array has changed.
				break
		if not _any_in_operator_list(result, operators):
			completed = true
		if loops > 10000:
			_logger.error("Operator type evaluation failed - too many iterations")
			return null
	return result


func _any_in_operator_list(expression_group, operators):
	return expression_group.any(func(c): return _is_in_operator_list(c, operators))


func _is_in_operator_list(operator, operator_list):
	if typeof(operator) == TYPE_DICTIONARY:
		if operator["component_type"] == ExpressionComponentType.OPERATOR:
			var op = operator["operator"]
			return op in operator_list
	return false


func _apply_operator(operator, left, right):
	match operator:
		ExpressionOperators.BOOL_AND:
			return left and right
		ExpressionOperators.BOOL_OR:
			return left or right
		ExpressionOperators.NUMERIC_ADD:
			return left + right
		ExpressionOperators.NUMERIC_SUBTRACT:
			return left - right
		ExpressionOperators.NUMERIC_MULTIPLY:
			return left * right
		ExpressionOperators.NUMERIC_DIVIDE:
			return left / right
		ExpressionOperators.STRING_CONCATENATE:
			return left + right
		ExpressionOperators.STRING_CONCATENATE_WITH_SPACE:
			return left + " " + right
	_logger.error("Invalid operator.")
	return null


func _get_variable(variable_name, scope):
	match scope:
		VariableScope.SCOPE_TRANSIENT:
			# We can deal with these internally for the duration of a cutscene
			return transient_store.get(variable_name)
		VariableScope.SCOPE_CUTSCENE:
			return cutscene_state_store.get(variable_name)
		VariableScope.SCOPE_LOCAL:
			if local_store == null:
				_logger.error(
					"Scene variable \"%s\" requested but no scene store is available" % variable_name
				)
				return null
			return local_store.get_variable(variable_name)
		VariableScope.SCOPE_GLOBAL:
			if global_store == null:
				_logger.error(
					"Global variable \"%s\" requested but no global store is available" % variable_name
				)
				return null
			return global_store.get_variable(variable_name)
	return null

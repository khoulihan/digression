@tool
extends Resource
## A resource for storing an expression.


## Types of expression components - expressions and operators.
enum ExpressionComponentType {
	EXPRESSION,
	OPERATOR,
}

## Expression types.
enum ExpressionType {
	VALUE,
	BRACKETS,
	COMPARISON,
	FUNCTION,
	CUSTOM_FUNCTION,
	GROUP,
	OPERATOR_GROUP,
}

## Possible function expression types.
## This enum does not distinguish the variable type,
## so MIN could refer to int or float variations of
## the function, for example.
enum FunctionType {
	CUSTOM,
	NOT,
	MIN,
	MAX,
	CONTAINS,
	TO_LOWER,
	FLOOR,
}

## Possible operators. Operators are mostly specific to types, but `int` and
## `float` types share operators (`NUMERIC_*`)
enum ExpressionOperators {
	COMPARISON_EQUALS,
	COMPARISON_NOT_EQUALS,
	COMPARISON_GREATER_THAN,
	COMPARISON_GREATER_THAN_OR_EQUALS,
	COMPARISON_LESS_THAN,
	COMPARISON_LESS_THAN_OR_EQUALS,
	BOOL_AND,
	BOOL_OR,
	NUMERIC_ADD,
	NUMERIC_SUBTRACT,
	NUMERIC_MULTIPLY,
	NUMERIC_DIVIDE,
	STRING_CONCATENATE,
	STRING_CONCATENATE_WITH_SPACE,
}

## Operator types - comparisons or operations.
enum OperatorType {
	OPERATION,
	COMPARISON,
}

const VariableType = preload("../VariableSetNode.gd").VariableType

const EXPRESSION_FUNCTIONS = {
	VariableType.TYPE_BOOL: {
		FunctionType.NOT: {
			"display": "not ( x )",
			"tooltip": "Negates the argument.",
			"arguments": {
				"x": VariableType.TYPE_BOOL,
			}
		},
		FunctionType.CONTAINS: {
			"display": "contains ( in, query )",
			"tooltip": "Returns true if \"in\" contains the substring \"query\".",
			"arguments": {
				"in": VariableType.TYPE_STRING,
				"query": VariableType.TYPE_STRING,
			}
		},
	},
	VariableType.TYPE_INT: {
		FunctionType.FLOOR: {
			"display": "floori ( x )",
			"tooltip": "Rounds x downward (towards negative infinity), returning the largest whole number that is not more than x.",
			"arguments": { "x": VariableType.TYPE_FLOAT },
		},
		FunctionType.MIN: {
			"display": "mini ( ... )",
			"tooltip": "Returns the smallest of the arguments.",
			"arguments": VariableType.TYPE_INT,
		},
		FunctionType.MAX: {
			"display": "maxi ( ... )",
			"tooltip": "Returns the largest of the arguments.",
			"arguments": VariableType.TYPE_INT,
		}
	},
	VariableType.TYPE_FLOAT: {
		FunctionType.FLOOR: {
			"display": "floorf ( x )",
			"tooltip": "Rounds x downward (towards negative infinity), returning the largest whole number that is not more than x.",
			"arguments": { "x": VariableType.TYPE_FLOAT },
		},
		FunctionType.MIN: {
			"display": "minf ( ... )",
			"tooltip": "Returns the smallest of the arguments.",
			"arguments": VariableType.TYPE_FLOAT,
		},
		FunctionType.MAX: {
			"display": "maxf ( ... )",
			"tooltip": "Returns the largest of the arguments.",
			"arguments": VariableType.TYPE_FLOAT,
		}
	},
	VariableType.TYPE_STRING: {
		FunctionType.TO_LOWER: {
			"display": "to_lower ( what )",
			"tooltip": "Converts the argument to lowercase.",
			"arguments": {
				"what": VariableType.TYPE_STRING,
			}
		},
	},
}

## A dictionary describing the expression.
@export var expression : Dictionary = {}

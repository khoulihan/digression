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
	CEIL,
	ABS,
	CLAMP,
	MOD,
	POSMOD,
	NEAREST_PO2,
	PINGPONG,
	RAND,
	RAND_FN,
	RAND_RANGE,
	ROUND,
	SIGN,
	SNAPPED,
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
		FunctionType.ABS: {
			"display": "absi ( x )",
			"tooltip": "Returns the absolute value of a Variant parameter x (i.e. non-negative value).",
			"arguments": { "x": VariableType.TYPE_INT },
		},
		FunctionType.CEIL: {
			"display": "ceili ( x )",
			"tooltip": "Rounds x upward (towards positive infinity), returning the smallest whole number that is not less than x.",
			"arguments": { "x": VariableType.TYPE_FLOAT },
		},
		FunctionType.CLAMP: {
			"display": "clampi ( value, min, max )",
			"tooltip": "Clamps the value, returning an int not less than min and not more than max.",
			"arguments": {
				"value": VariableType.TYPE_INT,
				"min": VariableType.TYPE_INT,
				"max": VariableType.TYPE_INT,
			},
		},
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
		},
		FunctionType.MOD: {
			"display": "mod ( x, y )",
			"tooltip": "Returns the integer remainder of x divided by y (x % y in GDScript).",
			"arguments": {
				"x": VariableType.TYPE_INT,
				"y": VariableType.TYPE_INT,
			},
		},
		FunctionType.NEAREST_PO2: {
			"display": "nearest_po2 ( value )",
			"tooltip": "Returns the smallest integer power of 2 that is greater than or equal to value.",
			"arguments": {
				"value": VariableType.TYPE_INT,
			},
		},
		FunctionType.POSMOD: {
			"display": "posmod ( x, y )",
			"tooltip": "Returns the integer modulus of x divided by y that wraps equally in positive and negative.",
			"arguments": {
				"x": VariableType.TYPE_INT,
				"y": VariableType.TYPE_INT,
			},
		},
		FunctionType.RAND: {
			"display": "randi ( )",
			"tooltip": "Returns a random unsigned 32-bit integer.",
			"arguments": {},
		},
		FunctionType.RAND_RANGE: {
			"display": "randi_range ( from, to )",
			"tooltip": "Returns a random signed 32-bit integer between from and to (inclusive). If to is lesser than from, they are swapped.",
			"arguments": {
				"from": VariableType.TYPE_INT,
				"to": VariableType.TYPE_INT,
			},
		},
		FunctionType.ROUND: {
			"display": "roundi ( x )",
			"tooltip": "Rounds x to the nearest whole number, with halfway cases rounded away from 0.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.SIGN: {
			"display": "signi ( x )",
			"tooltip": "Returns -1 if x is negative, 1 if x is positive, and 0 if x is zero.",
			"arguments": {
				"x": VariableType.TYPE_INT,
			},
		},
		FunctionType.SNAPPED: {
			"display": "snappedi ( x, step )",
			"tooltip": "Returns the multiple of step that is the closest to x.",
			"arguments": {
				"x": VariableType.TYPE_INT,
				"step": VariableType.TYPE_INT,
			},
		},
	},
	VariableType.TYPE_FLOAT: {
		FunctionType.ABS: {
			"display": "absf ( x )",
			"tooltip": "Returns the absolute value of a Variant parameter x (i.e. non-negative value).",
			"arguments": { "x": VariableType.TYPE_FLOAT },
		},
		FunctionType.CEIL: {
			"display": "ceilf ( x )",
			"tooltip": "Rounds x upward (towards positive infinity), returning the smallest whole number that is not less than x.",
			"arguments": { "x": VariableType.TYPE_FLOAT },
		},
		FunctionType.CLAMP: {
			"display": "clampf ( value, min, max )",
			"tooltip": "Clamps the value, returning a float not less than min and not more than max.",
			"arguments": {
				"value": VariableType.TYPE_FLOAT,
				"min": VariableType.TYPE_FLOAT,
				"max": VariableType.TYPE_FLOAT,
			},
		},
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
		},
		FunctionType.MOD: {
			"display": "fmod ( x, y )",
			"tooltip": "Returns the floating-point remainder of x divided by y, keeping the sign of x.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
				"y": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.PINGPONG: {
			"display": "pingpong ( value, length )",
			"tooltip": "Wraps value between 0 and the length. If the limit is reached, the next value the function returns is decreased to the 0 side or increased to the length side (like a triangle wave). If length is less than zero, it becomes positive.",
			"arguments": {
				"value": VariableType.TYPE_FLOAT,
				"length": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.POSMOD: {
			"display": "fposmod ( x, y )",
			"tooltip": "Returns the floating-point modulus of x divided by y, wrapping equally in positive and negative.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
				"y": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.RAND: {
			"display": "randf ( )",
			"tooltip": "Returns a random floating-point value between 0.0 and 1.0 (inclusive).",
			"arguments": {},
		},
		FunctionType.RAND_FN: {
			"display": "randfn ( mean, deviation )",
			"tooltip": "Returns a normally-distributed, pseudo-random floating-point value from the specified mean and a standard deviation. This is also known as a Gaussian distribution.",
			"arguments": {
				"mean": VariableType.TYPE_FLOAT,
				"deviation": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.RAND_RANGE: {
			"display": "randf_range ( from, to )",
			"tooltip": "Returns a random floating-point value between from and to (inclusive).",
			"arguments": {
				"from": VariableType.TYPE_FLOAT,
				"to": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.ROUND: {
			"display": "roundf ( x )",
			"tooltip": "Rounds x to the nearest whole number, with halfway cases rounded away from 0.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.SIGN: {
			"display": "signf ( x )",
			"tooltip": "Returns -1.0 if x is negative, 1.0 if x is positive, and 0.0 if x is zero. For nan values of x it returns 0.0.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.SNAPPED: {
			"display": "snappedf ( x, step )",
			"tooltip": "Returns the multiple of step that is the closest to x.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
				"step": VariableType.TYPE_FLOAT,
			},
		},
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

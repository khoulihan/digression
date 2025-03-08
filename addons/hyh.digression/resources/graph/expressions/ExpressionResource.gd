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
	ABS,
	BEGINS_WITH,
	CAPITALIZE,
	CEIL,
	CLAMP,
	CONTAINS,
	CONTAINSN,
	ENDS_WITH,
	FORMAT,
	IS_EMPTY,
	IS_SUBSEQUENCE_OF,
	IS_SUBSEQUENCE_OFN,
	FLOOR,
	IS_EQUAL_APPROX,
	IS_FINITE,
	IS_INFINITE,
	IS_NAN,
	IS_ZERO_APPROX,
	MATCH,
	MATCHN,
	MAX,
	MIN,
	MOD,
	NEAREST_PO2,
	NOT,
	PINGPONG,
	POSMOD,
	RAND,
	RAND_FN,
	RAND_RANGE,
	ROUND,
	SIGN,
	SNAPPED,
	TO_CAMEL_CASE,
	TO_LOWER,
	TO_PASCAL_CASE,
	TO_SNAKE_CASE,
	TO_UPPER,
	WRAP,
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
		FunctionType.BEGINS_WITH: {
			"display": "value.begins_with ( text )",
			"tooltip": "Returns true if value begins with the given text.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"text": VariableType.TYPE_STRING,
			}
		},
		FunctionType.CONTAINS: {
			"display": "value.contains ( what )",
			"tooltip": "Returns true if value contains what.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
			}
		},
		FunctionType.CONTAINSN: {
			"display": "value.containsn ( what )",
			"tooltip": "Returns true if value contains what, ignoring case.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
			}
		},
		FunctionType.ENDS_WITH: {
			"display": "value.ends_with ( text )",
			"tooltip": "Returns true if value ends with the given text.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"text": VariableType.TYPE_STRING,
			}
		},
		FunctionType.IS_EMPTY: {
			"display": "value.is_empty ( )",
			"tooltip": "Returns true if the string's length is 0.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.IS_EQUAL_APPROX: {
			"display": "is_equal_approx ( a, b )",
			"tooltip": "Returns true if a and b are approximately equal to each other.",
			"arguments": {
				"a": VariableType.TYPE_FLOAT,
				"b": VariableType.TYPE_FLOAT,
			}
		},
		FunctionType.IS_FINITE: {
			"display": "is_finite ( x )",
			"tooltip": "Returns whether x is a finite value, i.e. it is not NAN, positive infinity, or negative infinity.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
			}
		},
		FunctionType.IS_INFINITE: {
			"display": "is_inf ( x )",
			"tooltip": "Returns true if x is either positive infinity or negative infinity.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
			}
		},
		FunctionType.IS_NAN: {
			"display": "is_nan ( x )",
			"tooltip": "Returns true if x is a NaN (\"Not a Number\" or invalid) value.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
			}
		},
		FunctionType.IS_SUBSEQUENCE_OF: {
			"display": "value.is_subsequence_of ( text )",
			"tooltip": "Returns true if all characters of value can be found in text in their original order.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"text": VariableType.TYPE_STRING,
			}
		},
		FunctionType.IS_SUBSEQUENCE_OFN: {
			"display": "value.is_subsequence_ofn ( text )",
			"tooltip": "Returns true if all characters of value can be found in text in their original order, ignoring case.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"text": VariableType.TYPE_STRING,
			}
		},
		FunctionType.IS_ZERO_APPROX: {
			"display": "is_zero_approx ( x )",
			"tooltip": "Returns true if x is zero or almost zero.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
			}
		},
		FunctionType.MATCH: {
			"display": "value.match ( expr )",
			"tooltip": "Does a simple expression match (also called \"glob\" or \"globbing\"), where * matches zero or more arbitrary characters and ? matches any single character except a period (.).",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"expr": VariableType.TYPE_STRING,
			}
		},
		FunctionType.MATCHN: {
			"display": "value.match ( expr )",
			"tooltip": "Does a simple case-insensitive expression match (also called \"glob\" or \"globbing\"), where * matches zero or more arbitrary characters and ? matches any single character except a period (.).",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"expr": VariableType.TYPE_STRING,
			}
		},
		FunctionType.NOT: {
			"display": "not ( x )",
			"tooltip": "Negates the argument.",
			"arguments": {
				"x": VariableType.TYPE_BOOL,
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
		FunctionType.WRAP: {
			"display": "wrapi ( value, min, max )",
			"tooltip": "Wraps the integer value between min and max.",
			"arguments": {
				"value": VariableType.TYPE_INT,
				"min": VariableType.TYPE_INT,
				"max": VariableType.TYPE_INT,
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
		FunctionType.WRAP: {
			"display": "wrapf ( value, min, max )",
			"tooltip": "Wraps the float value between min and max.",
			"arguments": {
				"value": VariableType.TYPE_FLOAT,
				"min": VariableType.TYPE_FLOAT,
				"max": VariableType.TYPE_FLOAT,
			},
		},
	},
	VariableType.TYPE_STRING: {
		FunctionType.CAPITALIZE: {
			"display": "value.capitalize ( )",
			"tooltip": "Converts value to a format more suitable for display (see the Godot docs for more details).",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.FORMAT: {
			"display": "template.format ( values )",
			"tooltip": "Formats the string by replacing all occurrences of placeholders with the provided values. Unlike the GDScript method, the placeholder cannot be customised and only ordered placeholders are supported.",
			"arguments": {
				"template": VariableType.TYPE_STRING,
				"values": [VariableType.TYPE_STRING],
			}
		},
		FunctionType.TO_CAMEL_CASE: {
			"display": "value.to_camel_case ( )",
			"tooltip": "Converts value to camelCase.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.TO_LOWER: {
			"display": "value.to_lower ( )",
			"tooltip": "Converts value to lowercase.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.TO_PASCAL_CASE: {
			"display": "value.to_pascal_case ( )",
			"tooltip": "Returns the string converted to PascalCase.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.TO_SNAKE_CASE: {
			"display": "value.to_snake_case ( )",
			"tooltip": "Returns the string converted to snake_case.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.TO_UPPER: {
			"display": "value.to_upper ( )",
			"tooltip": "Converts value to UPPERCASE.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
	},
}

## A dictionary describing the expression.
@export var expression : Dictionary = {}

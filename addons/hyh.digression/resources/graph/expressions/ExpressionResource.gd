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
	C_ESCAPE,
	CHR,
	CLAMP,
	CONTAINS,
	CONTAINSN,
	COUNT,
	COUNTN,
	C_UNESCAPE,
	EASE,
	ENDS_WITH,
	ERASE,
	FIND,
	FINDN,
	FORMAT,
	GET_SLICE,
	GET_SLICE_COUNT,
	INSERT,
	INVERSE_LERP,
	IS_EMPTY,
	IS_SUBSEQUENCE_OF,
	IS_SUBSEQUENCE_OFN,
	FLOOR,
	IS_EQUAL_APPROX,
	IS_FINITE,
	IS_INFINITE,
	IS_NAN,
	IS_ZERO_APPROX,
	JOIN,
	LEFT,
	LENGTH,
	LERP,
	LERP_ANGLE,
	LPAD,
	LSTRIP,
	MATCH,
	MATCHN,
	MAX,
	MD5_TEXT,
	MIN,
	MOD,
	MOVE_TOWARD,
	NEAREST_PO2,
	NOT,
	PINGPONG,
	POSMOD,
	POW,
	RAND,
	RAND_FN,
	RAND_RANGE,
	REMAP,
	REPEAT,
	REPLACE,
	REPLACEN,
	REVERSE,
	RFIND,
	RFINDN,
	RIGHT,
	ROTATE_TOWARD,
	ROUND,
	RPAD,
	RSTRIP,
	SHA1_TEXT,
	SHA256_TEXT,
	SIGN,
	SIMILARITY,
	SMOOTHSTEP,
	SNAPPED,
	SQRT,
	STRIP_EDGES,
	STRIP_ESCAPES,
	SUBSTR,
	TO_CAMEL_CASE,
	TO_FLOAT,
	TO_INT,
	TO_LOWER,
	TO_PASCAL_CASE,
	TO_SNAKE_CASE,
	TO_UPPER,
	TRIM_PREFIX,
	TRIM_SUFFIX,
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
		FunctionType.COUNT: {
			"display": "value.count ( what, from=0, to=0 )",
			"tooltip": "Returns the number of occurrences of the substring whatbetween from and to positions.\nIf to is 0, the search continues until the end of the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
				"from": VariableType.TYPE_INT,
				"to": VariableType.TYPE_INT,
			},
			"defaults": {
				"from": 0,
				"to": 0,
			}
		},
		FunctionType.COUNTN: {
			"display": "value.countn ( what, from=0, to=0 )",
			"tooltip": "Returns the number of occurrences of the substring what, ignoring case.\nIf to is 0, the search continues until the end of the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
				"from": VariableType.TYPE_INT,
				"to": VariableType.TYPE_INT,
			},
			"defaults": {
				"from": 0,
				"to": 0,
			}
		},
		FunctionType.FIND: {
			"display": "value.find ( what, from=0 )",
			"tooltip": "Returns the index of the first occurrence of what in this string, or -1 if there are none.\nThe search's start can be specified with from, continuing to the end of the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
				"from": VariableType.TYPE_INT,
			},
			"defaults": {
				"from": 0,
			}
		},
		FunctionType.FINDN: {
			"display": "value.findn ( what, from=0 )",
			"tooltip": "Returns the index of the first case-insensitive occurrence of what in this string, or -1 if there are none.\nThe search's start can be specified with from, continuing to the end of the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
				"from": VariableType.TYPE_INT,
			},
			"defaults": {
				"from": 0,
			}
		},
		FunctionType.FLOOR: {
			"display": "floori ( x )",
			"tooltip": "Rounds x downward (towards negative infinity), returning the largest whole number that is not more than x.",
			"arguments": { "x": VariableType.TYPE_FLOAT },
		},
		FunctionType.GET_SLICE_COUNT: {
			"display": "value.get_slice_count ( delimiter )",
			"tooltip": "Returns the total number of slices when the string is split with the given delimiter.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"delimiter": VariableType.TYPE_STRING,
			}
		},
		FunctionType.LENGTH: {
			"display": "value.length ( )",
			"tooltip": "Returns the number of characters in the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
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
		FunctionType.RFIND: {
			"display": "value.rfind ( what, from=-1 )",
			"tooltip": "Returns the index of the last occurrence of what in this string, or -1 if there are none.\nThe search's start can be specified with from, continuing to the beginning of the string. ",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
				"from": VariableType.TYPE_INT,
			},
			"defaults": {
				"from": -1
			}
		},
		FunctionType.RFINDN: {
			"display": "value.rfindn ( what, from=-1 )",
			"tooltip": "Returns the index of the last case-insensitive occurrence of what in this string, or -1 if there are none.\nThe search's start can be specified with from, continuing to the beginning of the string. ",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
				"from": VariableType.TYPE_INT,
			},
			"defaults": {
				"from": -1
			}
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
		FunctionType.TO_INT: {
			"display": "value.to_int ( )",
			"tooltip": "Converts the string representing an integer number into an int.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
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
		FunctionType.EASE: {
			"display": "ease ( x, curve )",
			"tooltip": "Returns an \"eased\" value of x based on an easing function defined with curve.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
				"curve": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.FLOOR: {
			"display": "floorf ( x )",
			"tooltip": "Rounds x downward (towards negative infinity), returning the largest whole number that is not more than x.",
			"arguments": { "x": VariableType.TYPE_FLOAT },
		},
		FunctionType.INVERSE_LERP: {
			"display": "inverse_lerp ( from, to, weight )",
			"tooltip": "Returns an interpolation or extrapolation factor considering the range specified in from and to, and the interpolated value specified in weight.",
			"arguments": {
				"from": VariableType.TYPE_FLOAT,
				"to": VariableType.TYPE_FLOAT,
				"weight": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.LERP: {
			"display": "lerpf ( from, to, weight )",
			"tooltip": "Linearly interpolates between two values by the factor defined in weight.",
			"arguments": {
				"from": VariableType.TYPE_FLOAT,
				"to": VariableType.TYPE_FLOAT,
				"weight": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.LERP_ANGLE: {
			"display": "lerp_angle ( from, to, weight )",
			"tooltip": "Linearly interpolates between two angles (in radians) by a weight value between 0.0 and 1.0.",
			"arguments": {
				"from": VariableType.TYPE_FLOAT,
				"to": VariableType.TYPE_FLOAT,
				"weight": VariableType.TYPE_FLOAT,
			},
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
		FunctionType.MOVE_TOWARD: {
			"display": "move_toward ( from, to, delta )",
			"tooltip": "Moves from toward to by the delta amount. Will not go past to.",
			"arguments": {
				"from": VariableType.TYPE_FLOAT,
				"to": VariableType.TYPE_FLOAT,
				"delta": VariableType.TYPE_FLOAT,
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
		FunctionType.POW: {
			"display": "pow ( base, exp )",
			"tooltip": "Returns the result of base raised to the power of exp.",
			"arguments": {
				"base": VariableType.TYPE_FLOAT,
				"exp": VariableType.TYPE_FLOAT,
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
		FunctionType.REMAP: {
			"display": "remap ( value, istart, istop, ostart, ostop )",
			"tooltip": "Maps a value from range [istart, istop] to [ostart, ostop].",
			"arguments": {
				"value": VariableType.TYPE_FLOAT,
				"istart": VariableType.TYPE_FLOAT,
				"istop": VariableType.TYPE_FLOAT,
				"ostart": VariableType.TYPE_FLOAT,
				"ostop": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.ROTATE_TOWARD: {
			"display": "rotate_toward ( from, to, delta )",
			"tooltip": "Rotates from toward to by the delta amount. Will not go past to.",
			"arguments": {
				"from": VariableType.TYPE_FLOAT,
				"to": VariableType.TYPE_FLOAT,
				"delta": VariableType.TYPE_FLOAT,
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
		FunctionType.SIMILARITY: {
			"display": "value.similarity ( text )",
			"tooltip": "Returns the similarity index (Sørensen-Dice coefficient) of this string compared to another.\nA result of 1.0 means totally similar, while 0.0 means totally dissimilar.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"text": VariableType.TYPE_STRING,
			}
		},
		FunctionType.SMOOTHSTEP: {
			"display": "smoothstep ( from, to, x )",
			"tooltip": "Returns a smooth cubic Hermite interpolation between 0 and 1.",
			"arguments": {
				"from": VariableType.TYPE_FLOAT,
				"to": VariableType.TYPE_FLOAT,
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
		FunctionType.SQRT: {
			"display": "sqrt ( x )",
			"tooltip": "Returns the square root of x, where x is a non-negative number.",
			"arguments": {
				"x": VariableType.TYPE_FLOAT,
			},
		},
		FunctionType.TO_FLOAT: {
			"display": "value.to_float ( )",
			"tooltip": "Converts the string representing a decimal number into a float.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
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
		FunctionType.C_ESCAPE: {
			"display": "value.c_escape ( )",
			"tooltip": "Returns a copy of the string with special characters escaped using the C language standard.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.CHR: {
			"display": "String.chr ( char )",
			"tooltip": "Returns a single Unicode character from the decimal char.",
			"arguments": {
				"char": VariableType.TYPE_INT,
			}
		},
		FunctionType.C_UNESCAPE: {
			"display": "value.c_unescape ( )",
			"tooltip": "Returns a copy of the string with escaped characters replaced by their meanings. ",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.ERASE: {
			"display": "value.erase ( position, chars=1 )",
			"tooltip": "Returns a string with chars characters erased starting from position.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"position": VariableType.TYPE_INT,
				"chars": VariableType.TYPE_INT,
			},
			"defaults": {
				"chars": 1
			}
		},
		FunctionType.FORMAT: {
			"display": "template.format ( values, placeholder=\"{_}\" )",
			"tooltip": "Formats the string by replacing all occurrences of placeholders with the provided values. Unlike the GDScript method, only ordered placeholders are supported.",
			"arguments": {
				"template": VariableType.TYPE_STRING,
				"values": [VariableType.TYPE_STRING],
				"placeholder": VariableType.TYPE_STRING,
			},
			"defaults": {
				"placeholder": "{_}"
			}
		},
		FunctionType.GET_SLICE: {
			"display": "value.get_slice ( delimiter, slice )",
			"tooltip": "Splits the string using a delimiter and returns the substring at index slice.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"delimiter": VariableType.TYPE_STRING,
				"slice": VariableType.TYPE_INT,
			}
		},
		FunctionType.INSERT: {
			"display": "value.insert ( position, what )",
			"tooltip": "Inserts what at the given position in the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"position": VariableType.TYPE_INT,
				"what": VariableType.TYPE_STRING,
			}
		},
		FunctionType.JOIN: {
			"display": "value.join ( parts )",
			"tooltip": "Concatenates all members of parts, separated by value.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"parts": [VariableType.TYPE_STRING],
			}
		},
		FunctionType.LEFT: {
			"display": "value.left ( length )",
			"tooltip": "Returns the first length characters from the beginning of the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"length": VariableType.TYPE_INT,
			}
		},
		FunctionType.LPAD: {
			"display": "value.lpad ( min_length, character=\" \" )",
			"tooltip": "Formats the string to be at least min_length long by adding characters to the left of the string, if necessary.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"min_length": VariableType.TYPE_INT,
				"character": VariableType.TYPE_STRING,
			},
			"defaults": {
				"character": " "
			}
		},
		FunctionType.LSTRIP: {
			"display": "value.lstrip ( chars )",
			"tooltip": "Removes a set of characters defined in chars from the string's beginning.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"chars": VariableType.TYPE_STRING,
			}
		},
		FunctionType.MD5_TEXT: {
			"display": "value.md5_text ( )",
			"tooltip": "Returns the MD5 hash of the string as another String.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.REPEAT: {
			"display": "value.repeat ( count )",
			"tooltip": "Repeats value a number of times.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"count": VariableType.TYPE_INT,
			}
		},
		FunctionType.REPLACE: {
			"display": "value.replace ( what, forwhat )",
			"tooltip": "Replaces all occurrences of what inside the string with the given forwhat.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
				"forwhat": VariableType.TYPE_STRING,
			}
		},
		FunctionType.REPLACEN: {
			"display": "value.replacen ( what, forwhat )",
			"tooltip": "Replaces all case-insensitive occurrences of what inside the string with the given forwhat.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"what": VariableType.TYPE_STRING,
				"forwhat": VariableType.TYPE_STRING,
			}
		},
		FunctionType.REVERSE: {
			"display": "value.reverse ( )",
			"tooltip": "Returns the copy of this string in reverse order. ",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.RIGHT: {
			"display": "value.right ( length )",
			"tooltip": "Returns the first length characters from the end of the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"length": VariableType.TYPE_INT,
			}
		},
		FunctionType.RPAD: {
			"display": "value.rpad ( min_length, character=\" \" )",
			"tooltip": "Formats the string to be at least min_length long by adding characters to the right of the string, if necessary.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"min_length": VariableType.TYPE_INT,
				"character": VariableType.TYPE_STRING,
			},
			"defaults": {
				"character": " "
			}
		},
		FunctionType.RSTRIP: {
			"display": "value.rstrip ( chars )",
			"tooltip": "Removes a set of characters defined in chars from the string's end.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"chars": VariableType.TYPE_STRING,
			}
		},
		FunctionType.SHA1_TEXT: {
			"display": "value.sha1_text ( )",
			"tooltip": "Returns the SHA-1 hash of the string as another String.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.SHA256_TEXT: {
			"display": "value.sha256_text ( )",
			"tooltip": "Returns the SHA-256 hash of the string as another String.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.STRIP_EDGES: {
			"display": "value.strip_edges ( left=true, right=true )",
			"tooltip": "Strips all non-printable characters from the beginning and the end of the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"left": VariableType.TYPE_BOOL,
				"right": VariableType.TYPE_BOOL,
			},
			"defaults": {
				"left": true,
				"right": true,
			}
		},
		FunctionType.STRIP_ESCAPES: {
			"display": "value.strip_escapes ( )",
			"tooltip": "Strips all escape characters from the string.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
			}
		},
		FunctionType.SUBSTR: {
			"display": "value.substr ( from, len=-1 )",
			"tooltip": "Returns part of the string from the position from with length len. If len is -1 (the default), returns the rest of the string starting from the given position.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"from": VariableType.TYPE_INT,
				"len": VariableType.TYPE_INT,
			},
			"defaults": {
				"len": -1
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
		FunctionType.TRIM_PREFIX: {
			"display": "value.trim_prefix ( prefix )",
			"tooltip": "Removes the given prefix from the start of the string, or returns the string unchanged.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"prefix": VariableType.TYPE_STRING,
			}
		},
		FunctionType.TRIM_SUFFIX: {
			"display": "value.trim_suffix ( suffix )",
			"tooltip": "Removes the given suffix from the end of the string, or returns the string unchanged.",
			"arguments": {
				"value": VariableType.TYPE_STRING,
				"suffix": VariableType.TYPE_STRING,
			}
		},
	},
}

## A dictionary describing the expression.
@export var expression : Dictionary = {}

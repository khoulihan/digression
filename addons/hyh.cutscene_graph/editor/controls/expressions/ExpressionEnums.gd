extends Object

enum ExpressionType {
	VALUE,
	BRACKETS,
	COMPARISON,
	FUNCTION,
	CUSTOM_FUNCTION,
}

# This enum does not distinguish the variable type,
# so MIN could refer to int or float variations of
# the function, for example.
enum FunctionType {
	CUSTOM,
	NOT,
	MIN,
	MAX,
	CONTAINS,
	TO_LOWER,
}

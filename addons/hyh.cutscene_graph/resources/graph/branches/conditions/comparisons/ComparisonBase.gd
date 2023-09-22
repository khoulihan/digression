@tool
extends Resource

const Highlighting = preload("../../../../../utility/Highlighting.gd")

enum ComparisonType {
	EQUALS,
	GREATER_THAN,
	GREATER_THAN_OR_EQUALS,
	LESS_THAN,
	LESS_THAN_OR_EQUALS,
	RANGE,
	SET
}

@export var comparison_type: ComparisonType

func evaluate(val) -> bool:
	# Nothing to evaluate in the base class
	return false


func custom_duplicate(subresources=false):
	return self.duplicate(subresources)


func get_highlighted_syntax(variable) -> String:
	print ("Base comparison")
	return "[color=%s]%s[/color]" % [
		Highlighting.TEXT_COLOUR,
		variable
	]


func _get_value_colour(val):
	if val is String:
		return Highlighting.STRING_COLOUR
	return Highlighting.BASE_TYPE_COLOUR


func _get_value_display(val):
	if val is String:
		return "\"%s\"" % val
	return "%s" % val

@tool
extends "ComparisonBase.gd"

var value


# This is necessary to ensure that "value" is saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "value",
		"type": null,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties


func evaluate(val) -> bool:
	match comparison_type:
		ComparisonType.EQUALS:
			return val == self.value
		ComparisonType.GREATER_THAN:
			return val > self.value
		ComparisonType.GREATER_THAN_OR_EQUALS:
			return val >= self.value
		ComparisonType.LESS_THAN:
			return val < self.value
		ComparisonType.LESS_THAN_OR_EQUALS:
			return val <= self.value
	# Any other comparson type is invalid here
	return false


func get_highlighted_syntax(variable) -> String:
	if value is bool:
		if value:
			return "%s" % Highlighting.highlight(
				variable,
				Highlighting.TEXT_COLOUR
			)
		else:
			return "%s %s" % [
				Highlighting.highlight("not", Highlighting.KEYWORD_COLOUR),
				Highlighting.highlight(variable, Highlighting.TEXT_COLOUR)
			]
	return "%s %s %s" % [
		Highlighting.highlight(variable, Highlighting.TEXT_COLOUR),
		Highlighting.highlight(_get_comparison_symbol(), Highlighting.SYMBOL_COLOUR),
		Highlighting.highlight(_get_value_display(value), _get_value_colour(value))
	]


func _get_comparison_symbol():
	match comparison_type:
		ComparisonType.EQUALS:
			return "=="
		ComparisonType.GREATER_THAN:
			return ">"
		ComparisonType.GREATER_THAN_OR_EQUALS:
			return ">="
		ComparisonType.LESS_THAN:
			return "<"
		ComparisonType.LESS_THAN_OR_EQUALS:
			return "<="
	# Any other comparson type is invalid here
	return ""




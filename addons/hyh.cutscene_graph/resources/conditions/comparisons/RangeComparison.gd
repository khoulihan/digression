@tool
extends "ComparisonBase.gd"

var min_value
var max_value

# This is necessary to ensure that the range properties are saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "min_value",
		"type": null,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	properties.append({
		"name": "max_value",
		"type": null,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties


func evaluate(val) -> bool:
	if comparison_type != ComparisonType.RANGE:
		return false
	return val >= min_value and val <= max_value


func get_highlighted_syntax(variable) -> String:
	return "%s%s %s %s %s %s %s %s%s" % [
		Highlighting.highlight("(", Highlighting.SYMBOL_COLOUR),
		Highlighting.highlight(variable, Highlighting.TEXT_COLOUR),
		Highlighting.highlight(">=", Highlighting.SYMBOL_COLOUR),
		Highlighting.highlight(_get_value_display(min_value), _get_value_colour(min_value)),
		Highlighting.highlight("and", Highlighting.KEYWORD_COLOUR),
		Highlighting.highlight(variable, Highlighting.TEXT_COLOUR),
		Highlighting.highlight("<=", Highlighting.SYMBOL_COLOUR),
		Highlighting.highlight(_get_value_display(max_value), _get_value_colour(max_value)),
		Highlighting.highlight(")", Highlighting.SYMBOL_COLOUR),
	]

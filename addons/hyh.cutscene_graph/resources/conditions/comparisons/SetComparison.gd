@tool
extends "ComparisonBase.gd"

var value_set: Array

# This is necessary to ensure that "value_set" is saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "value_set",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties


func evaluate(val) -> bool:
	if comparison_type != ComparisonType.SET:
		return false
	return val in value_set


func get_highlighted_syntax(variable) -> String:
	return "%s %s %s" % [
		Highlighting.highlight(variable, Highlighting.TEXT_COLOUR),
		Highlighting.highlight("in", Highlighting.KEYWORD_COLOUR),
		_get_value_displays(),
	]


func _get_value_displays():
	var vals = []
	for val in value_set:
		vals.append(
			Highlighting.highlight(
				_get_value_display(val),
				_get_value_colour(val)
			)
		)
	return "%s%s%s" % [
		Highlighting.highlight("[", Highlighting.SYMBOL_COLOUR),
		Highlighting.highlight(", ", Highlighting.SYMBOL_COLOUR).join(vals),
		Highlighting.highlight("]", Highlighting.SYMBOL_COLOUR),
	]

@tool
extends RefCounted

const VariableType = preload("../VariableSetNode.gd").VariableType

const KEYWORD_COLOUR = "#ff7085"
const CONTROL_FLOW_COLOUR = "#ff8ccc"
const SYMBOL_COLOUR = "#abc9ff"
const STRING_COLOUR = "#ffeda1"
const TEXT_COLOUR = "#cdcfd2"
const BASE_TYPE_COLOUR = "#8fffdb"
const NUMERIC_CONSTANT_COLOUR = BASE_TYPE_COLOUR

static func highlight(val, colour):
	return "[color=%s]%s[/color]" % [colour, val]


static func get_colour_for_variable_type(variable_type):
	match variable_type:
		VariableType.TYPE_BOOL:
			return KEYWORD_COLOUR
		VariableType.TYPE_STRING:
			return STRING_COLOUR
	return NUMERIC_CONSTANT_COLOUR

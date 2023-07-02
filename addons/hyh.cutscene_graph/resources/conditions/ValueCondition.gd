@tool
extends "ConditionBase.gd"

const VariableScope = preload("../VariableSetNode.gd").VariableScope
const VariableType = preload("../VariableSetNode.gd").VariableType
const ComparisonBase = preload("comparisons/ComparisonBase.gd")


@export var scope: VariableScope
@export var variable: String
@export var variable_type: VariableType
@export var comparison: ComparisonBase


func evaluate(value) -> bool:
	return comparison.evaluate(value)


func get_highlighted_syntax() -> String:
	return comparison.get_highlighted_syntax(variable)

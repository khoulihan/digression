@tool
extends "ConditionBase.gd"

const VariableScope = preload("../../VariableSetNode.gd").VariableScope
const VariableType = preload("../../VariableSetNode.gd").VariableType
const ComparisonBase = preload("comparisons/ComparisonBase.gd")


@export var scope: VariableScope
@export var variable: String
@export var variable_type: VariableType
@export var comparison: ComparisonBase


func evaluate(value) -> bool:
	return comparison.evaluate(value)


func custom_duplicate(subresources=false):
	var dup = super(subresources)
	if not subresources:
		return dup
	if self.comparison != null:
		dup.comparison = self.comparison.custom_duplicate(true)
	return dup


func get_highlighted_syntax() -> String:
	return comparison.get_highlighted_syntax(variable)

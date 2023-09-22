@tool
extends Resource

const ConditionBase = preload("conditions/ConditionBase.gd")
const BooleanCondition = preload("conditions/BooleanCondition.gd")


@export var display: String
@export var display_translation_key: String

# These properties are untyped to allow nulls
@export var next: int = -1
@export var condition: ConditionBase


func duplicate(subresources=false):
	var dup = super(subresources)
	if not subresources:
		return dup
	if self.condition != null:
		# For some reason, this does not call the override methods on any
		# class in the hierarchy!
		#dup.condition = self.condition.duplicate(true)
		# Had to implement a custom alternative method.
		dup.condition = self.condition.custom_duplicate(true)
	return dup

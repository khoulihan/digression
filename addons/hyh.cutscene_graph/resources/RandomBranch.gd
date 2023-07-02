@tool
extends Resource

const ConditionBase = preload("conditions/ConditionBase.gd")

# These properties are untyped to allow nulls
@export var next: int = -1
@export var condition: ConditionBase

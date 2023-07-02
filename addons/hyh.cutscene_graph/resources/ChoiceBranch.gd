@tool
extends Resource

const ConditionBase = preload("conditions/ConditionBase.gd")


@export var display: String
@export var display_translation_key: String

# These properties are untyped to allow nulls
@export var next: int = -1
@export var condition: ConditionBase

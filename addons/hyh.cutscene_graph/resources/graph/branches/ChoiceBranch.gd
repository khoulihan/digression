@tool
extends Resource


const ExpressionResource = preload("../expressions/ExpressionResource.gd")


@export var display: String
@export var display_translation_key: String

@export var next: int = -1
@export var condition: ExpressionResource

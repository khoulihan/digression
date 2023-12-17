@tool
extends Resource


const ExpressionResource = preload("../expressions/ExpressionResource.gd")


@export var next: int = -1
@export var condition: ExpressionResource

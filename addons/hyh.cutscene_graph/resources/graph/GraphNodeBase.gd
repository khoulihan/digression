@tool
extends Resource

@export var id: int
# The node to move to next. This may be a default fallback for some node types.
# TODO: Could maybe remove the type hint here and allow it to be null again.
@export var next: int = -1
# Specifically for display in custom graph editor
@export var offset: Vector2


func _init():
	pass

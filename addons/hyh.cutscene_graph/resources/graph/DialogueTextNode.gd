@tool
extends "GraphNodeBase.gd"


@export var dialogue_type: String
@export var text: String
@export var text_translation_key: String
@export var character: Character
@export var character_variant: CharacterVariant

# This is used only for recreating the node state in the editor
@export var size: Vector2

func _init():
	pass


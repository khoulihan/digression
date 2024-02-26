@tool
extends Resource

class_name PropertyCollection

const PropertyUse = preload("../../editor/inspector/character_property_edit/CharacterPropertySelector.gd").PropertyUse


@export
var use_restriction: PropertyUse


@export
var properties: Dictionary

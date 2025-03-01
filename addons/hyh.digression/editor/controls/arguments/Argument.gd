@tool
extends MarginContainer

# TODO: Maybe a better icon for this?
const ARGUMENT_ICON = preload("../../../icons/icon_drag_vertical_light.svg")

@onready var OrdinalLabel: Label = get_node("ExpressionContainer/OrdinalLabel")
@onready var DragHandle: TextureRect = get_node("ExpressionContainer/DragHandle")
@onready var ValidationWarning : TextureRect = get_node("ExpressionContainer/ValidationWarning")

@export var ordinal: int

signal modified()
signal remove_requested(ord)
signal remove_immediately(ord)


func configure():
	OrdinalLabel.text = str(ordinal)
	DragHandle.target = self


func refresh():
	OrdinalLabel.text = str(ordinal)


func _on_remove_button_pressed():
	remove_requested.emit(ordinal)


func get_drag_preview():
	var preview = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.texture = ARGUMENT_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	var ptext = Label.new()
	ptext.text = "%s Argument" % _get_type_name()
	preview.add_child(icon)
	preview.add_child(ptext)
	preview.modulate = Color.from_string("#777777FF", Color.DIM_GRAY)
	return preview


func _get_type_name():
	return "Argument"


func remove_from_parent():
	remove_immediately.emit(ordinal)


func validate():
	pass

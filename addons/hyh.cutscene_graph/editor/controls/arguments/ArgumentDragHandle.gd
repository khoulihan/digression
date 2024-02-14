@tool
extends TextureRect


@export var target : Node


func _get_drag_data(at_position):
	if target == null:
		return
	set_drag_preview(target.get_drag_preview())
	return {
		"cge_drag_class": "argument",
		"control": target,
	}

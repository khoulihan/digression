@tool
extends TextureRect
# TODO: Deprecated. Switch to generic DragHandle class instead.


@export var target : Node


func _get_drag_data(at_position):
	if target == null:
		return
	set_drag_preview(target.get_drag_preview())
	return {
		"dge_drag_class": "argument",
		"control": target,
	}

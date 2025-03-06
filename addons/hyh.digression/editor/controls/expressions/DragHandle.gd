@tool
extends TextureRect
## Control to serve as a drag handle for expressions.
# TODO: Deprecated. Switch to generic DragHandle class instead.


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const DragClass = preload("../drag/DragHandle.gd").DragClass

## The expression node that this handle drags.
@export var target : Node
## The type of value that the expression describes.
@export var type: VariableType


func _get_drag_data(at_position):
	if target == null:
		return
	set_drag_preview(target.get_drag_preview())
	return {
		"dge_drag_class": DragClass.EXPRESSION,
		"control": target,
		"type": type,
	}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event()

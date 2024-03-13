@tool
extends TextureRect
## Control to serve as a drag handle for expressions.


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType

## The expression node that this handle drags.
@export var target : Node
## The type of value that the expression describes.
@export var type: VariableType


func _get_drag_data(at_position):
	if target == null:
		return
	set_drag_preview(target.get_drag_preview())
	return {
		"cge_drag_class": "expression",
		"control": target,
		"type": type,
	}

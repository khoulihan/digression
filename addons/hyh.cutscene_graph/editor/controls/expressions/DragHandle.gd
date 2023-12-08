@tool
extends TextureRect


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType


@export var target : Node
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

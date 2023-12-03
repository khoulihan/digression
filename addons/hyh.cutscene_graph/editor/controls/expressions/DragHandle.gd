extends TextureRect


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType


@export var target : Node
@export var type: VariableType


func _get_drag_data(at_position):
	if target == null:
		return
	# TODO: Create a proper preview here
	var preview = Label.new()
	preview.text = "Being dragged rn"
	set_drag_preview(preview)
	return {
		"cge_drag_class": "expression",
		"control": target,
		"type": type,
	}

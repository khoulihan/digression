@tool
extends Control


signal dropped(arg, at_position)
signal can_drop(at_position, data)


const DragClass = preload("res://addons/hyh.digression/editor/controls/drag/DragHandle.gd").DragClass
const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const DragVariableTypeRestriction = preload("DragHandle.gd").DragVariableTypeRestriction

@export var accepted_classes : Array[DragClass]
@export var accepted_type_restriction : DragVariableTypeRestriction


func _can_drop_data(at_position, data):
	if not typeof(data) == TYPE_DICTIONARY:
		return false
	if not "dge_drag_class" in data:
		return false
	if not data["dge_drag_class"] in accepted_classes:
		return false
	
	if "dge_drag_variable_type" in data:
		# We have a type restriction.
		if not accepted_type_restriction == DragVariableTypeRestriction.NONE:
			if not data["dge_drag_variable_type"] == _map_type_restriction(accepted_type_restriction):
				return false
	
	can_drop.emit(at_position, data)
	return true


func _drop_data(at_position, data):
	var target = data["control"]
	dropped.emit(target, at_position)


func _map_type_restriction(restriction_type: DragVariableTypeRestriction) -> VariableType:
	match (restriction_type):
		DragVariableTypeRestriction.BOOL:
			return VariableType.TYPE_BOOL
		DragVariableTypeRestriction.INT:
			return VariableType.TYPE_INT
		DragVariableTypeRestriction.FLOAT:
			return VariableType.TYPE_FLOAT
		DragVariableTypeRestriction.STRING:
			return VariableType.TYPE_STRING
		_:
			# We should never end up here.
			return VariableType.TYPE_BOOL

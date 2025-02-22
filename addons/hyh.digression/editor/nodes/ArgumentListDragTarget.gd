@tool
extends MarginContainer
# TODO: Deprecated. Switch to generic DragTarget class instead.


signal argument_dropped(arg, at_position)


const DragClass = preload("../controls/drag/DragHandle.gd").DragClass


func _can_drop_data(at_position, data):
	if not typeof(data) == TYPE_DICTIONARY:
		return false
	if not "dge_drag_class" in data:
		return false
	if data["dge_drag_class"] != DragClass.ARGUMENT:
		return false
	return true


func _drop_data(at_position, data):
	var target = data["control"]
	argument_dropped.emit(target, at_position)

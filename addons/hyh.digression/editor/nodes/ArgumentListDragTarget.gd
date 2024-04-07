@tool
extends MarginContainer


signal argument_dropped(arg, at_position)


func _can_drop_data(at_position, data):
	if not typeof(data) == TYPE_DICTIONARY:
		return false
	if not "dge_drag_class" in data:
		return false
	if data["dge_drag_class"] != "argument":
		return false
	# TODO: I assume this would be the place to highlight the drop location?
	return true


func _drop_data(at_position, data):
	var target = data["control"]
	argument_dropped.emit(target, at_position)

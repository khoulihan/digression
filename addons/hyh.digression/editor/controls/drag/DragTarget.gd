@tool
extends Control


signal dropped(arg, at_position)
signal can_drop(at_position, data)


const DragClass = preload("res://addons/hyh.digression/editor/controls/drag/DragHandle.gd").DragClass


@export var accepted_classes : Array[DragClass]


func _can_drop_data(at_position, data):
	if not typeof(data) == TYPE_DICTIONARY:
		return false
	if not "dge_drag_class" in data:
		return false
	if not data["dge_drag_class"] in accepted_classes:
		return false
	
	can_drop.emit(at_position, data)
	return true


func _drop_data(at_position, data):
	var target = data["control"]
	dropped.emit(target, at_position)

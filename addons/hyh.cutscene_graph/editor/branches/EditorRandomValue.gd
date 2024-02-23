@tool
extends MarginContainer


signal remove_requested()
signal modified()
signal size_changed(size_change)


const RandomBranch = preload("../../resources/graph/branches/RandomBranch.gd")


@onready var ConditionControl = get_node("VBoxContainer/HBoxContainer/VariableContainer/ConditionControl")
@onready var WeightControl = get_node("VBoxContainer/HBoxContainer/VariableContainer/WeightControl")


var branch_resource


func get_branch():
	branch_resource.condition = ConditionControl.condition_resource
	return branch_resource


func set_branch(branch):
	self.branch_resource = branch
	ConditionControl.condition_resource = self.branch_resource.condition
	WeightControl.configure_for_weight(self.branch_resource.weight)


func _on_RemoveButton_pressed():
	emit_signal("remove_requested")


func _on_condition_control_size_changed(size_change):
	size_changed.emit(size_change)


func _on_weight_control_changed(weight: int) -> void:
	branch_resource.weight = weight
	modified.emit()


func _on_weight_control_cleared() -> void:
	branch_resource.weight = -1
	modified.emit()

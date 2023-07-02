@tool
extends MarginContainer


signal remove_requested()
signal modified()
signal set_condition_requested()
signal edit_condition_requested()
signal clear_condition_requested()


const RandomBranch = preload("../../resources/graph/branches/RandomBranch.gd")


@onready var ConditionControl = get_node("VBoxContainer/HBoxContainer/VariableContainer/ConditionControl")


var branch_resource


func get_branch():
	branch_resource.condition = ConditionControl.condition_resource
	return branch_resource


func set_branch(branch):
	self.branch_resource = branch
	ConditionControl.condition_resource = self.branch_resource.condition


func _on_RemoveButton_pressed():
	emit_signal("remove_requested")


func _on_condition_control_set_condition_requested():
	emit_signal("set_condition_requested")

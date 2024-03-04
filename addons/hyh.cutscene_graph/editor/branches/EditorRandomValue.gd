@tool
extends MarginContainer
## Branch control for Random nodes.


signal remove_requested()
signal modified()
signal size_changed(size_change)

const RandomBranch = preload("../../resources/graph/branches/RandomBranch.gd")

var branch_resource: RandomBranch

@onready var _condition_control = $VB/HB/VariableContainer/ConditionControl
@onready var _weight_control = $VB/HB/VariableContainer/WeightControl


## Get the branch resource with the current values.
func get_branch() -> RandomBranch:
	branch_resource.condition = _condition_control.condition_resource
	return branch_resource


## Assign a branch resource to the control.
func set_branch(branch: RandomBranch) -> void:
	self.branch_resource = branch
	_condition_control.condition_resource = self.branch_resource.condition
	_weight_control.configure_for_weight(self.branch_resource.weight)


func _on_remove_button_pressed() -> void:
	remove_requested.emit()


func _on_condition_control_size_changed(size_change) -> void:
	size_changed.emit(size_change)


func _on_weight_control_changed(weight: int) -> void:
	branch_resource.weight = weight
	modified.emit()


func _on_weight_control_cleared() -> void:
	branch_resource.weight = -1
	modified.emit()

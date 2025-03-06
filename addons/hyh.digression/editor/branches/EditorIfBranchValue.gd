@tool
extends MarginContainer
## Control for a branch of an IfBranch node.


signal remove_requested()
signal modified()
signal preparing_to_change_parent()
signal dropped_after(section)
signal size_changed(size_change)

const IfBranch = preload("../../resources/graph/branches/IfBranch.gd")

var _branch_resource: IfBranch

@onready var _condition_expression = $VB/Condition/PC/MC/ConditionExpression
@onready var _if_label = $VB/Condition/Label


## Get the branch resource updated with the current values.
func get_branch() -> IfBranch:
	_branch_resource.condition = _condition_expression.serialise()
	return _branch_resource


## Assign a branch resource to the UI.
func set_branch(branch: IfBranch) -> void:
	_branch_resource = branch
	_condition_expression.deserialise(_branch_resource.condition)
	_condition_expression.configure()


# TODO: Since this should only be one of two values, an enum should maybe be used instead.
## Set the text of the label that describes the branch (if/elif).
func set_label(text: String) -> void:
	_if_label.text = text


func prepare_to_change_parent():
	preparing_to_change_parent.emit()


func _on_remove_button_pressed() -> void:
	remove_requested.emit()


func _on_condition_expression_modified() -> void:
	modified.emit()


func _on_condition_expression_size_changed(amount) -> void:
	size_changed.emit(amount)


func _on_drag_target_dropped(arg: Variant, at_position: Variant) -> void:
	dropped_after.emit(arg)

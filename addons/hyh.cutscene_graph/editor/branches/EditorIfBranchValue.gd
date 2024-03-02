@tool
extends MarginContainer


signal remove_requested()
signal modified()
signal size_changed(size_change)


const IfBranch = preload("res://addons/hyh.cutscene_graph/resources/graph/branches/IfBranch.gd")


@onready var ConditionExpression = $Condition/PC/MC/ConditionExpression
@onready var IfLabel = $Condition/Label


var _branch_resource: IfBranch


func get_branch() -> IfBranch:
	_branch_resource.condition = ConditionExpression.serialise()
	return _branch_resource


func set_branch(branch: IfBranch) -> void:
	_branch_resource = branch
	ConditionExpression.deserialise(_branch_resource.condition)
	ConditionExpression.configure()


func set_label(text: String) -> void:
	IfLabel.text = text


func _on_remove_button_pressed() -> void:
	remove_requested.emit()


func _on_condition_expression_modified() -> void:
	modified.emit()


func _on_condition_expression_size_changed(amount) -> void:
	size_changed.emit(amount)

@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/arguments/Argument.gd"

const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType

@onready var OperatorExpression = get_node("ExpressionContainer/PC/ArgumentValueContainer/OperatorExpression")

@export
var type : VariableType


func configure():
	super()
	OperatorExpression.type = type
	OperatorExpression.configure()


func _get_type_name():
	return "Expression"


func get_expression():
	return OperatorExpression.serialise()


func set_expression(expression):
	OperatorExpression.deserialise(expression)
	validate()


func validate():
	var warnings = OperatorExpression.validate()
	if warnings == null:
		ValidationWarning.visible = false
	else:
		ValidationWarning.visible = true
		if typeof(warnings) == TYPE_STRING:
			ValidationWarning.tooltip_text = warnings
		else:
			ValidationWarning.tooltip_text = "Invalid Expression"


func _on_operator_expression_modified():
	validate()
	modified.emit()

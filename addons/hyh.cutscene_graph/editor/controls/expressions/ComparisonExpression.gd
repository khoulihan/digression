@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"

const OperatorClass = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/Operator.gd")
const OperatorType = preload("../../../resources/graph/expressions/ExpressionResource.gd").OperatorType
const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType


# TODO: For some reason chose a different style for these variables
@onready var LeftExpression = get_node("PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/LeftPanel/MC/LeftExpression")
@onready var RightExpression = get_node("PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/RightPanel/MC/RightExpression")
@onready var ComparisonOperator = get_node("PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/ComparisonOperator")


@export var comparison_type : VariableType


func _ready():
	_panel.remove_theme_stylebox_override("panel")
	_panel.get_child(0).add_theme_constant_override("margin_bottom", 10)
	_title.tooltip_text = "Compares two values, returning a boolean result."


func configure():
	super()
	LeftExpression.type = comparison_type
	LeftExpression.configure()
	RightExpression.type = comparison_type
	RightExpression.configure()
	ComparisonOperator.variable_type = comparison_type
	ComparisonOperator.operator_type = OperatorType.COMPARISON
	ComparisonOperator.configure()


func validate():
	var left_warning = LeftExpression.validate()
	var right_warning = RightExpression.validate()
	if left_warning == null and right_warning == null:
		_validation_warning.visible = false
		return null
	_validation_warning.visible = true
	_validation_warning.tooltip_text = ""
	if typeof(left_warning) == TYPE_STRING:
		_validation_warning.tooltip_text = left_warning
	elif typeof(left_warning) == TYPE_ARRAY:
		_validation_warning.tooltip_text = "There are problems with one or more child expressions on the left side of the comparison."
	else:
		if typeof(right_warning) == TYPE_STRING:
			_validation_warning.tooltip_text = right_warning
		elif typeof(right_warning) == TYPE_ARRAY:
			_validation_warning.tooltip_text = "There are problems with one or more child expressions on the right side of the comparison."
	
	if right_warning == null:
		return left_warning
	return [left_warning, right_warning]


func _on_left_expression_modified():
	modified.emit()


func _on_right_expression_modified():
	modified.emit()


func serialise():
	var exp = super()
	exp["expression_type"] = ExpressionType.COMPARISON
	# Type of the expressions being compared - not the same as the type of
	# THIS expression...
	exp["comparison_type"] = comparison_type
	exp["left_expression"] = LeftExpression.serialise()
	exp["right_expression"] = RightExpression.serialise()
	exp["comparison_operator"] = ComparisonOperator.serialise()
	return exp


func deserialise(serialised):
	super(serialised)
	LeftExpression.deserialise(serialised["left_expression"])
	RightExpression.deserialise(serialised["right_expression"])
	# Had to defer this to get it to select the correct operator, despite this
	# not being required for operation operators.
	call_deferred("_deserialise_operator", serialised["comparison_operator"])


func _deserialise_operator(serialised):
	ComparisonOperator.deserialise(serialised)


# TODO: Might only need this for testing?
func clear():
	LeftExpression.clear()
	RightExpression.clear()
	ComparisonOperator.clear()

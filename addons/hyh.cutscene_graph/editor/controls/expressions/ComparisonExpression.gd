@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"
## An expression for comparing two values.


const OperatorClass = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/Operator.gd")
const OperatorType = preload("../../../resources/graph/expressions/ExpressionResource.gd").OperatorType
const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType

const GROUP_PANEL_STYLE = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/group_panel_style.tres")

@export var comparison_type : VariableType

@onready var _left_expression = $PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/LeftPanel/MC/LeftExpression
@onready var _right_expression = $PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/RightPanel/MC/RightExpression
@onready var _comparison_operator = $PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/ComparisonOperator


func _ready():
	_panel.add_theme_stylebox_override("panel", GROUP_PANEL_STYLE)
	_panel.get_child(0).add_theme_constant_override("margin_bottom", 10)
	_title.tooltip_text = "Compares two values, returning a boolean result."


## Configure the expression.
func configure():
	super()
	_left_expression.type = comparison_type
	_left_expression.configure()
	_right_expression.type = comparison_type
	_right_expression.configure()
	_comparison_operator.variable_type = comparison_type
	_comparison_operator.operator_type = OperatorType.COMPARISON
	_comparison_operator.configure()


## Validate the expression.
func validate():
	var left_warning = _left_expression.validate()
	var right_warning = _right_expression.validate()
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


## Serialise the expression to a dictionary.
func serialise():
	var exp = super()
	exp["expression_type"] = ExpressionType.COMPARISON
	# Type of the expressions being compared - not the same as the type of
	# THIS expression...
	exp["comparison_type"] = comparison_type
	exp["left_expression"] = _left_expression.serialise()
	exp["right_expression"] = _right_expression.serialise()
	exp["comparison_operator"] = _comparison_operator.serialise()
	return exp


## Deserialise an expression dictionary.
func deserialise(serialised):
	super(serialised)
	_left_expression.deserialise(serialised["left_expression"])
	_right_expression.deserialise(serialised["right_expression"])
	# Had to defer this to get it to select the correct operator, despite this
	# not being required for operation operators.
	call_deferred("_deserialise_operator", serialised["comparison_operator"])


# TODO: Might only need this for testing?
## Clear the expression of all children.
func clear():
	_left_expression.clear()
	_right_expression.clear()
	_comparison_operator.clear()


func _deserialise_operator(serialised):
	_comparison_operator.deserialise(serialised)


func _on_left_expression_modified():
	modified.emit()


func _on_right_expression_modified():
	modified.emit()


func _on_expression_size_changed(amount):
	size_changed.emit(amount)

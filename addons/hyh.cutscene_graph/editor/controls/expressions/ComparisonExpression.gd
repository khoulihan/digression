@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"

const OperatorType = preload("Operator.gd").OperatorType


@onready var LeftExpression = get_node("PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/LeftPanel/MC/LeftExpression")
@onready var RightExpression = get_node("PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/RightPanel/MC/RightExpression")
@onready var ComparisonOperator = get_node("PanelContainer/MC/ExpressionContainer/MC/VBoxContainer/ComparisonOperator")


@export var comparison_type : VariableType


func _ready():
	_panel.remove_theme_stylebox_override("panel")
	_panel.get_child(0).add_theme_constant_override("margin_bottom", 10)


func configure():
	super()
	LeftExpression.type = comparison_type
	LeftExpression.configure()
	RightExpression.type = comparison_type
	RightExpression.configure()
	ComparisonOperator.variable_type = comparison_type
	ComparisonOperator.operator_type = OperatorType.COMPARISON
	ComparisonOperator.configure()

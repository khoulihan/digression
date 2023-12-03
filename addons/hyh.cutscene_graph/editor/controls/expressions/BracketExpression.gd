@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"


@onready var _child_expression = get_node("PanelContainer/MC/ExpressionContainer/MC/ChildExpression")


# Called when the node enters the scene tree for the first time.
func _ready():
	_panel.remove_theme_stylebox_override("panel")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func configure():
	super()
	_child_expression.type = type
	_child_expression.configure()

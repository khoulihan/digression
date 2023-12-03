@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"


@onready var _value_edit = get_node("PanelContainer/MC/ExpressionContainer/Header/VariableValueEdit")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func configure():
	super()
	_value_edit.variable_type = type

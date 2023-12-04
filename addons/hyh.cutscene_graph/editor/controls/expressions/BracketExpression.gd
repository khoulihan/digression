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


func validate():
	var warning = _child_expression.validate()
	if warning == null:
		_validation_warning.visible = false
		return null
	_validation_warning.visible = true
	_validation_warning.tooltip_text = ""
	if typeof(warning) == TYPE_STRING:
		_validation_warning.tooltip_text = warning
	else:
		_validation_warning.tooltip_text = "There are problems with one or more child expressions."
	return warning


func _on_child_expression_modified():
	modified.emit()

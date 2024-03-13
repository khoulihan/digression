@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"
## Expression for grouping other expressions to be evaluated first.


const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType
const GROUP_PANEL_STYLE = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/group_panel_style.tres")

@onready var _child_expression = $PanelContainer/MC/ExpressionContainer/MC/ChildExpression


func _ready():
	_panel.add_theme_stylebox_override("panel", GROUP_PANEL_STYLE)
	_title.tooltip_text = "Groups expressions to be evaluated with priority."


## Configure the expression.
func configure():
	super()
	_child_expression.type = type
	_child_expression.configure()


## Validate the expression.
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


## Serialise the expression to a dictionary.
func serialise():
	var exp = super()
	exp["expression_type"] = ExpressionType.BRACKETS
	exp["contents"] = _child_expression.serialise()
	return exp


## Deserialise an expression dictionary.
func deserialise(serialised):
	super(serialised)
	_child_expression.deserialise(serialised["contents"])


# TODO: Might only need this for testing?
## Clear the expression of all children.
func clear():
	_child_expression.clear()


func _on_child_expression_modified():
	modified.emit()


func _on_child_expression_size_changed(amount):
	size_changed.emit(amount)

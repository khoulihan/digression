@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"


const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType

const _group_panel_style = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/group_panel_style.tres")

@onready var _child_expression = get_node("PanelContainer/MC/ExpressionContainer/MC/ChildExpression")


# Called when the node enters the scene tree for the first time.
func _ready():
	_panel.add_theme_stylebox_override("panel", _group_panel_style)
	_title.tooltip_text = "Groups expressions to be evaluated with priority."


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


func serialise():
	var exp = super()
	exp["expression_type"] = ExpressionType.BRACKETS
	exp["contents"] = _child_expression.serialise()
	return exp


func deserialise(serialised):
	super(serialised)
	_child_expression.deserialise(serialised["contents"])


# TODO: Might only need this for testing?
func clear():
	_child_expression.clear()

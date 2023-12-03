@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/Expression.gd"


const FunctionType = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/ExpressionEnums.gd").FunctionType
const ExpressionType = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/ExpressionEnums.gd").ExpressionType

#const ValueExpression = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/ValueExpression.tscn")
#const BracketExpression = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/BracketExpression.tscn")
#const ComparisonExpression = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/ComparisonExpression.tscn")
#const FunctionExpression = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/FunctionExpression.tscn")


@onready var _add_element_button = get_node("AddElementButton")


func configure():
	super()
	# This is necessary because configuring the button loads derivatives of
	# this class, which Godot doesn't like, and it can corrupt the scenes.
	#await _add_element_button.ready
	_configure_button()
	#call_deferred("_configure_button")


func _configure_button():
	_add_element_button.configure(type)


func _on_add_element_button_add_requested(
	variable_type,
	expression_type,
	function_type
):
	match expression_type:
		ExpressionType.VALUE:
			_add_value(variable_type)
		ExpressionType.BRACKETS:
			_add_brackets(variable_type)
		ExpressionType.COMPARISON:
			_add_comparison(variable_type)
		ExpressionType.FUNCTION:
			_add_function(variable_type, function_type)
	# TODO: Have skipped custom functions for now


func _add_to_bottom(child):
	add_child(child)
	move_child(_add_element_button, -1)
	child.remove_requested.connect(_remove_child_requested.bind(child))
	call_deferred("_configure_child", child)


func _configure_child(child):
	child.configure()


func _add_value(variable_type):
	var exp = load("res://addons/hyh.cutscene_graph/editor/controls/expressions/ValueExpression.tscn").instantiate()
	exp.type = variable_type
	_add_to_bottom(exp)


func _add_brackets(variable_type):
	var exp = load("res://addons/hyh.cutscene_graph/editor/controls/expressions/BracketExpression.tscn").instantiate()
	exp.type = variable_type
	_add_to_bottom(exp)


func _add_comparison(variable_type):
	var exp = load("res://addons/hyh.cutscene_graph/editor/controls/expressions/ComparisonExpression.tscn").instantiate()
	exp.type = variable_type
	_add_to_bottom(exp)


func _add_function(variable_type, function_type):
	var exp = load("res://addons/hyh.cutscene_graph/editor/controls/expressions/FunctionExpression.tscn").instantiate()
	exp.type = variable_type
	exp.function_type = function_type
	_add_to_bottom(exp)


func _remove_child_requested(child):
	remove_child(child)
	child.queue_free()

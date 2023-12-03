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


func refresh():
	pass


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


func _can_drop_data(at_position, data):
	if not typeof(data) == TYPE_DICTIONARY:
		return false
	if not "cge_drag_class" in data:
		return false
	if data["cge_drag_class"] != "expression":
		return false
	if type != data["type"]:
		return false
	# TODO: I assume this would be the place to highlight the drop location?
	return true


func _drop_data(at_position, data):
	var target = data["control"]
	var parent = target.get_parent()
	# TODO: Likely the parent has other stuff to do to the child first
	parent.remove_child(target)
	parent.refresh()
	# TODO: We do not actually want to add to the bottom, but to the drag location.
	#_add_to_bottom(target)
	_add_at_position(at_position, target)


func _add_at_position(at_position, target):
	# I think what we have to do here is find the MoveableExpression
	# under the point, and then determine if we are closer to the top or
	# bottom of it, and insert accordingly.
	var children = get_children().slice(0, -1)
	var distance_to_child = null
	var closest = null
	var add_before = false
	var y = at_position.y
	for child in children:
		var top = child.offset_top
		var bottom = child.offset_bottom
		if y >= top and y <= bottom:
			# We are over this child!
			closest = child
			if y - top < bottom - y:
				add_before = true
				distance_to_child = y - top
			else:
				add_before = false
				distance_to_child = bottom - y
			break
		if closest == null or y - top < distance_to_child or bottom - y < distance_to_child:
			closest = child
			if y - top < bottom - y:
				add_before = true
				distance_to_child = y - top
			else:
				add_before = false
				distance_to_child = bottom - y
			
	
	add_child(target)
	if closest != null:
		if add_before:
			move_child(target, closest.get_index())
		else:
			move_child(target, closest.get_index() + 1)
	else:
		# Leave it at the bottom, but move the add button down
		move_child(_add_element_button, -1)
	target.remove_requested.connect(_remove_child_requested.bind(target))


func _get_child_expression_at_position(at_position):
	pass

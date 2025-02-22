@tool
extends "Expression.gd"
## Expression that groups other expressions.


const FunctionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").FunctionType
const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType
const DragClass = preload("../drag/DragHandle.gd").DragClass

@onready var _add_element_button = $AddElementButton


## Configure the expression.
func configure():
	super()
	_configure_button()


func refresh():
	pass


## Remove one of the expression's children.
func remove_child_expression(child):
	var size_before = self.size.y
	remove_child(child)
	child.remove_requested.disconnect(_remove_child_requested)
	child.modified.disconnect(_child_modified)
	child.size_changed.disconnect(_child_size_changed)
	call_deferred("_emit_modified")
	call_deferred("_emit_size_changed", size_before, 10)


## Validate the expression.
func validate():
	var children = get_children().slice(0, -1)
	if len(children) == 0:
		return "Group expression has no children."
	var child_warnings = []
	for child in children:
		var warning = child.validate()
		if warning == null:
			continue
		child_warnings.append(warning)
	if len(child_warnings) == 0:
		return null
	else:
		return child_warnings


## Serialise the expression to a dictionary.
func serialise():
	var exp = super()
	exp["expression_type"] = ExpressionType.GROUP
	exp["children"] = _serialise_children()
	return exp


## Deserialise an expression dictionary.
func deserialise(serialised):
	super(serialised)
	for sc in serialised["children"]:
		_deserialise_child(sc)


# TODO: Might only need this for testing?
## Clear the expression of all children.
func clear():
	var children = get_children().slice(0, -1)
	for child in children:
		remove_child(child)


func _configure_button():
	_add_element_button.configure(type)


func _on_add_element_button_add_requested(
	variable_type,
	expression_type,
	function_type,
	comparison_type
):
	match expression_type:
		ExpressionType.VALUE:
			_add_value(variable_type)
		ExpressionType.BRACKETS:
			_add_brackets(variable_type)
		ExpressionType.COMPARISON:
			_add_comparison(variable_type, comparison_type)
		ExpressionType.FUNCTION:
			_add_function(variable_type, function_type)
	# TODO: Have skipped custom functions for now


func _add_to_bottom(child, deserialising=false):
	var size_before = self.size.y
	add_child(child)
	move_child(_add_element_button, -1)
	child.remove_requested.connect(_remove_child_requested.bind(child))
	child.modified.connect(_child_modified)
	child.size_changed.connect(_child_size_changed)
	call_deferred("_configure_child", child)
	if not deserialising:
		call_deferred("_emit_modified")
		call_deferred("_emit_size_changed", size_before)


func _emit_modified():
	modified.emit()


func _configure_child(child):
	child.configure()


func _add_value(variable_type, deserialising=false):
	var exp = load("res://addons/hyh.digression/editor/controls/expressions/ValueExpression.tscn").instantiate()
	exp.type = variable_type
	_add_to_bottom(exp, deserialising)
	return exp


func _add_brackets(variable_type, deserialising=false):
	var exp = load("res://addons/hyh.digression/editor/controls/expressions/BracketExpression.tscn").instantiate()
	exp.type = variable_type
	_add_to_bottom(exp, deserialising)
	return exp


func _add_comparison(variable_type, comparison_type, deserialising=false):
	var exp = load("res://addons/hyh.digression/editor/controls/expressions/ComparisonExpression.tscn").instantiate()
	# I think the type will always be boolean here
	exp.type = variable_type
	exp.comparison_type = comparison_type
	_add_to_bottom(exp, deserialising)
	return exp


func _add_function(variable_type, function_type, deserialising=false):
	var exp = load("res://addons/hyh.digression/editor/controls/expressions/FunctionExpression.tscn").instantiate()
	exp.type = variable_type
	exp.function_type = function_type
	_add_to_bottom(exp, deserialising)
	return exp


func _remove_child_requested(child):
	var size_before = self.size.y
	remove_child(child)
	child.queue_free()
	call_deferred("_emit_modified")
	call_deferred("_emit_size_changed", size_before, 10)


func _child_modified():
	modified.emit()


func _child_size_changed(amount):
	size_changed.emit(amount)


func _can_drop_data(at_position, data):
	if not typeof(data) == TYPE_DICTIONARY:
		return false
	if not "dge_drag_class" in data:
		return false
	if data["dge_drag_class"] != DragClass.EXPRESSION:
		return false
	if type != data["type"]:
		return false
	# TODO: I assume this would be the place to highlight the drop location?
	return true


func _drop_data(at_position, data):
	var target = data["control"]
	var parent = target.get_parent()
	parent.remove_child_expression(target)
	parent.refresh()
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
	var distances = {}

	# Calculate the distance to each child.
	for child in children:
		var top = child.offset_top
		var bottom = child.offset_bottom
		# This calculates the centre of the child.
		distances[child] = abs(y - (top + bottom) / 2.0)
	
	# Determine which child is the closest.
	for child in distances:
		if distance_to_child == null:
			distance_to_child = distances[child]
			closest = child
			continue
		if distances[child] < distance_to_child:
			distance_to_child = distances[child]
			closest = child
	
	# Determine if we are before or after the identified closest child
	if closest != null:
		var top = closest.offset_top
		var bottom = closest.offset_bottom
		var centre = (top + bottom) / 2.0
		add_before = y < centre
	
	var size_before = self.size.y
	# Don't insert if the target was closest to itself!
	if closest == null or closest != target:
		add_child(target)
	if closest != null:
		# Don't move if the target was closest to itself!
		if closest != target:
			if add_before:
				move_child(target, closest.get_index())
			else:
				move_child(target, closest.get_index() + 1)
	else:
		# Leave it at the bottom, but move the add button down
		move_child(_add_element_button, -1)
	target.remove_requested.connect(_remove_child_requested.bind(target))
	target.modified.connect(_child_modified)
	target.size_changed.connect(_child_size_changed)
	call_deferred("_emit_modified")
	call_deferred("_emit_size_changed", size_before)


func _get_child_expression_at_position(at_position):
	pass


func _serialise_children():
	var child_exps = []
	var children = get_children().slice(0, -1)
	for child in children:
		child_exps.append(child.serialise())
	return child_exps


func _deserialise_child(serialised):
	var child
	var expression_type = serialised["expression_type"]
	match expression_type:
		ExpressionType.VALUE:
			child = _add_value(type, true)
		ExpressionType.BRACKETS:
			child = _add_brackets(type, true)
		ExpressionType.COMPARISON:
			child = _add_comparison(type, serialised["comparison_type"], true)
		ExpressionType.FUNCTION:
			child = _add_function(type, serialised["function_type"], true)
	child.deserialise(serialised)

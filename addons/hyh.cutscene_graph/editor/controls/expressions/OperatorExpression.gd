@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/GroupExpression.gd"


const Operator = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/Operator.tscn")
const OperatorClass = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/Operator.gd")


func refresh():
	super()
	_rectify_operators()


func _add_to_bottom(child):
	super(child)
	_rectify_operators()


func _remove_child_requested(child):
	super(child)
	_rectify_operators()


func _add_at_position(at_position, target):
	super(at_position, target)
	_rectify_operators()


func _rectify_operators():
	# Go through all children and ensure that every pair of expressions has
	# exactly one operator between them.
	var children = get_children().slice(0, -1)
	var to_remove = []
	var previous = null
	for child in children:
		if child is OperatorClass:
			if previous == null:
				to_remove.append(child)
				continue
			if previous is OperatorClass:
				# Decide which operator has precedence and remove the other
				# Set previous to the winner
				var winner = _operator_to_keep(previous, child, to_remove)
				previous = winner
			else:
				previous = child
			continue
		
		# child is Expression
		if previous == null:
			previous = child
			continue
		if not previous is OperatorClass:
			# Insert an operator between previous and child
			var operator = Operator.instantiate()
			operator.operator_type = OperatorClass.OperatorType.OPERATION
			operator.variable_type = type
			add_child(operator)
			move_child(operator, child.get_index())
			operator.configure()
		previous = child
	
	# Make sure an operator is not left dangling
	if previous != null:
		if previous is OperatorClass:
			to_remove.append(previous)
	
	for child in to_remove:
		remove_child(child)


func _operator_to_keep(previous, current, to_remove):
	if previous.operator_type > current.operator_type:
		to_remove.append(current)
		return previous
	to_remove.append(previous)
	return current


func validate():
	var children = get_children().slice(0, -1)
	if len(children) == 0:
		return "Group expression has no children."
	var child_warnings = []
	for child in children:
		if child is OperatorClass:
			continue
		var warning = child.validate()
		if warning == null:
			continue
		child_warnings.append(warning)
	if len(child_warnings) == 0:
		return null
	else:
		return child_warnings

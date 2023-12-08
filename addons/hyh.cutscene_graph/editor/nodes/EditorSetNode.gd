@tool
extends "EditorGraphNodeBase.gd"


@onready var VariableSelectionControl = get_node("MarginContainer/GridContainer/VariableSelectionControl")
@onready var SelectVariableLabel = get_node("MarginContainer/GridContainer/SelectVariableLabel")
@onready var ExpressionControl = get_node("MarginContainer/GridContainer/Expression")


var _variable_name
var _variable_scope
var _variable_type


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	set_variable(n.variable)
	set_type(n.variable_type)
	set_scope(n.scope)
	if _variable_name != null and not _variable_name.is_empty():
		VariableSelectionControl.configure_for_variable(
			_variable_name,
			_variable_scope,
			_variable_type,
		)
		SelectVariableLabel.hide()
		ExpressionControl.show()
		ExpressionControl.configure()
		set_value_expression(n.get_value_expression())
	else:
		ExpressionControl.hide()
		SelectVariableLabel.show()
	if n.size != null and n.size != Vector2.ZERO:
		size = n.size


func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.variable = get_variable()
	node_resource.variable_type = get_type()
	node_resource.set_value_expression(get_value_expression())
	node_resource.scope = get_scope()
	node_resource.size = self.size


func get_variable():
	return _variable_name


func set_variable(val):
	_variable_name = val


func get_value_expression():
	return ExpressionControl.serialise()


func set_value_expression(val):
	ExpressionControl.clear()
	ExpressionControl.deserialise(val)


func get_scope():
	return _variable_scope


func set_scope(val):
	_variable_scope = val


func get_type():
	return _variable_type


func set_type(val):
	_variable_type = val
	ExpressionControl.clear()
	ExpressionControl.type = val
	ExpressionControl.configure()


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_expression_modified():
	# TODO: Need somewhere to display the overall result of this
	ExpressionControl.validate()
	emit_signal("modified")


func _on_resize_request(new_minsize):
	size = Vector2(new_minsize.x, 0)


func _on_variable_selection_control_variable_selected(variable):
	set_variable(variable['name'])
	set_scope(variable['scope'])
	set_type(variable['type'])
	VariableSelectionControl.configure_for_variable(
		_variable_name,
		_variable_scope,
		_variable_type,
	)
	SelectVariableLabel.hide()
	ExpressionControl.show()
	ExpressionControl.configure()
	emit_signal("modified")

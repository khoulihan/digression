@tool
extends "EditorGraphNodeBase.gd"
## Editor node for managing a Set node resource.


var _variable_name
var _variable_scope
var _variable_type

@onready var _variable_selection_control = $MC/GC/VariableSelectionControl
@onready var _select_variable_label = $MC/GC/SelectVariableLabel
@onready var _expression_control = $MC/GC/Expression


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	set_variable(n.variable)
	set_type(n.variable_type)
	set_scope(n.scope)
	if _variable_name != null and not _variable_name.is_empty():
		_variable_selection_control.configure_for_variable(
			_variable_name,
			_variable_scope,
			_variable_type,
		)
		_select_variable_label.hide()
		_expression_control.show()
		_expression_control.configure()
		set_value_expression(n.get_value_expression())
	else:
		_expression_control.hide()
		_select_variable_label.show()
	if n.size != null and n.size != Vector2.ZERO:
		size = n.size


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.variable = get_variable()
	node_resource.variable_type = get_type()
	node_resource.set_value_expression(get_value_expression())
	node_resource.scope = get_scope()
	node_resource.size = self.size


## Get the variable selected to be set by the node.
func get_variable():
	return _variable_name


## Set the selected variable.
func set_variable(val):
	_variable_name = val


## Get the expression.
func get_value_expression():
	return _expression_control.serialise()


## Set the expression.
func set_value_expression(val):
	_expression_control.clear()
	_expression_control.deserialise(val)


## Get the scope of the selected variable.
func get_scope():
	return _variable_scope


## Set the scope of the variable.
func set_scope(val):
	_variable_scope = val


## Get the type of the variable.
func get_type():
	return _variable_type


## Set the type of the variable.
func set_type(val):
	_variable_type = val
	_expression_control.clear()
	_expression_control.type = val
	_expression_control.configure()


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_expression_modified():
	# TODO: Need somewhere to display the overall result of this
	_expression_control.validate()
	modified.emit()


func _on_resize_request(new_minsize):
	size = Vector2(new_minsize.x, 0)


func _on_variable_selection_control_variable_selected(variable):
	set_variable(variable['name'])
	set_scope(variable['scope'])
	set_type(variable['type'])
	_variable_selection_control.configure_for_variable(
		_variable_name,
		_variable_scope,
		_variable_type,
	)
	_select_variable_label.hide()
	_expression_control.show()
	_expression_control.configure()
	modified.emit()

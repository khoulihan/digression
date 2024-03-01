@tool
extends "EditorGraphNodeBase.gd"

var _branch_value_scene = preload("../branches/EditorMatchBranchValue.tscn")

const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType


@onready var VariableSelectionControl = get_node("MarginContainer/VBoxContainer/HeaderContainer/GridContainer/VariableSelectionControl")
@onready var AddValueButton : Button = get_node("MarginContainer/VBoxContainer/HeaderContainer/AddValueButton")

var _original_size: Vector2

var _variable_name
var _variable_scope
var _variable_type


func get_variable():
	return _variable_name


func set_variable(val):
	_variable_name = val


func get_values():
	var values = []
	for index in range(1, get_child_count()):
		values.append(get_child(index).get_value())
	return values


func set_values(values):
	clear_branches()
	for index in range(0, values.size()):
		_add_branch(values[index])


func get_scope():
	return _variable_scope


func set_scope(val):
	_variable_scope = val


func get_type():
	return _variable_type


func set_type(val):
	_variable_type = val
	for index in range(1, get_child_count()):
		get_child(index).set_type(val)


func _add_branch(value):
	var line = _create_branch()
	line.set_value(value)


func clear_branches():
	for index in range(get_child_count() - 1, 0, -1):
		remove_branch(index)


func remove_branch(index):
	emit_signal("removing_slot", index)
	var node = get_child(index)
	remove_child(node)
	node.disconnect("remove_requested", Callable(self, "_value_remove_requested"))
	node.disconnect("modified", Callable(self, "_value_modified"))
	reconnect_signals()
	# This should resize the control to the maximum required for the remaining
	# branches, vertically.
	size = _original_size


func _create_branch():
	var new_value_line = _branch_value_scene.instantiate()
	add_child(new_value_line)
	new_value_line.set_type(node_resource.variable_type)
	new_value_line.connect("remove_requested", Callable(self, "_value_remove_requested").bind(get_child_count() - 1))
	new_value_line.connect("modified", Callable(self, "_value_modified").bind(get_child_count() - 1))
	set_slot(get_child_count() - 1, false, 0, CONNECTOR_COLOUR, true, 0, CONNECTOR_COLOUR)
	return new_value_line


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	# We want to retain the original width, but the original height
	# includes sample branches which are not yet removed.
	_original_size = Vector2(size.x, 0.0)
	set_variable(n.variable)
	set_scope(n.scope)
	set_type(n.variable_type)
	if _variable_name != null and not _variable_name.is_empty():
		VariableSelectionControl.configure_for_variable(
			_variable_name,
			_variable_scope,
			_variable_type,
		)
		AddValueButton.disabled = false
	else:
		AddValueButton.disabled = true
		
	set_values(n.get_values())


func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.variable = get_variable()
	node_resource.scope = get_scope()
	node_resource.variable_type = get_type()
	var values = get_values()
	node_resource.branch_count = len(values)
	node_resource.set_values(values)


func clear_node_relationships():
	super.clear_node_relationships()
	node_resource.branches = []
	var values = node_resource.get_values()
	for index in range(0, values.size()):
		node_resource.branches.append(null)


func _on_AddValueButton_pressed():
	var new_value_line = _create_branch()
	emit_signal("modified")


func _value_remove_requested(index):
	remove_branch(index)


func _value_modified(index):
	emit_signal("modified")


func reconnect_signals():
	if get_child_count() > 1:
		for index in range(1, get_child_count()):
			get_child(index).disconnect("remove_requested", Callable(self, "_value_remove_requested"))
			get_child(index).disconnect("modified", Callable(self, "_value_modified"))
			get_child(index).connect("remove_requested", Callable(self, "_value_remove_requested").bind(index))
			get_child(index).connect("modified", Callable(self, "_value_modified").bind(index))


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_variable_selection_control_variable_selected(variable):
	set_variable(variable['name'])
	set_scope(variable['scope'])
	set_type(variable['type'])
	VariableSelectionControl.configure_for_variable(
		_variable_name,
		_variable_scope,
		_variable_type,
	)
	for i in range(1, get_child_count()):
		get_child(i).set_type(_variable_type)
	AddValueButton.disabled = false
	emit_signal("modified")

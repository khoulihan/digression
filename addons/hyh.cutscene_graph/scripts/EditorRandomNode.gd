@tool
extends "EditorGraphNodeBase.gd"

const VariableScope = preload("../resources/VariableSetNode.gd").VariableScope
const VariableType = preload("../resources/VariableSetNode.gd").VariableType


var _random_value_scene = preload("../scenes/RandomValue.tscn")


var _original_size: Vector2


func get_variables() -> Array[String]:
	var variables: Array[String] = []
	for index in range(1, get_child_count()):
		variables.append(get_child(index).get_variable())
	return variables


func get_types() -> Array[VariableType]:
	var var_types: Array[VariableType] = []
	for index in range(1, get_child_count()):
		var_types.append(get_child(index).get_type())
	return var_types


func get_values():
	var values = []
	for index in range(1, get_child_count()):
		values.append(get_child(index).get_value())
	return values


func get_scopes() -> Array[VariableScope]:
	var scopes: Array[VariableScope] = []
	for index in range(1, get_child_count()):
		scopes.append(get_child(index).get_scope())
	return scopes


func set_branches(variables, variable_types, scopes, values):
	clear_branches()
	for index in range(0, values.size()):
		_add_branch(
			variables[index],
			variable_types[index],
			scopes[index],
			values[index]
		)


func _add_branch(variable, variable_type, scope, value):
	var line = _create_branch()
	line.set_random(
		variable,
		variable_type,
		scope,
		value
	)


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
	# This should restore the control to the minimum required for the remaining
	# choices, but a bit more than strictly necessary horizontally.
	size = _original_size


func _create_branch():
	var new_value_line = _random_value_scene.instantiate()
	add_child(new_value_line)
	new_value_line.connect("remove_requested", Callable(self, "_value_remove_requested").bind(get_child_count() - 1))
	new_value_line.connect("modified", Callable(self, "_value_modified").bind(get_child_count() - 1))
	set_slot(get_child_count() - 1, false, 0, Color("#cff44c"), true, 0, Color("#cff44c"))
	return new_value_line


func configure_for_node(n):
	super.configure_for_node(n)
	# We want to retain the original width, but the original height
	# includes sample choices which are not yet removed.
	_original_size = Vector2(size.x, 0.0)
	set_branches(n.variables, n.variable_types, n.scopes, n.get_values())


func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.variables = get_variables()
	node_resource.variable_types = get_types()
	node_resource.set_values(get_values())
	node_resource.scopes = get_scopes()


func clear_node_relationships():
	super.clear_node_relationships()
	node_resource.branches = []
	for index in range(0, node_resource.variables.size()):
		node_resource.branches.append(null)


func _on_AddBranchButton_pressed():
	var new_value_line = _create_branch()
	emit_signal("modified")


func _value_remove_requested(index):
	remove_branch(index)
	emit_signal("modified")


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


@tool
extends "EditorGraphNodeBase.gd"

const IfBranch = preload("../../resources/graph/branches/IfBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType


var _if_value_scene = preload("../branches/EditorIfBranchValue.tscn")


var _original_size: Vector2


func get_branches():
	var t: Array[IfBranch] = []
	for index in range(1, get_child_count()):
		t.append(get_child(index).get_branch())
	return t


func set_branches(branches):
	clear_branches()
	for index in range(0, branches.size()):
		_add_branch(
			branches[index],
			index == 0,
		)


func _add_branch(branch, is_first: bool) -> void:
	var line = _create_branch()
	line.set_branch(
		branch
	)
	_set_label(line, is_first)


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


func _set_label(line, is_first: bool) -> void:
	if is_first:
		line.set_label("if")
	else:
		line.set_label("elif")


func _create_branch():
	var new_value_line = _if_value_scene.instantiate()
	var branch_resource = IfBranch.new()
	var is_first = get_child_count() - 1 == 0
	add_child(new_value_line)
	new_value_line.set_branch(branch_resource)
	_set_label(new_value_line, is_first)
	new_value_line.connect("remove_requested", _value_remove_requested.bind(get_child_count() - 1))
	new_value_line.connect("modified", _value_modified.bind(get_child_count() - 1))
	#new_value_line.size_changed.connect(_value_size_changed)
	set_slot(get_child_count() - 1, false, 0, CONNECTOR_COLOUR, true, 0, CONNECTOR_COLOUR)
	return new_value_line


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	# We want to retain the original width, but the original height
	# includes sample choices which are not yet removed.
	_original_size = Vector2(size.x, 0.0)
	set_branches(n.branches)


func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.branches = get_branches()


func clear_node_relationships():
	super.clear_node_relationships()
	for branch in node_resource.branches:
		branch.next = -1


func _value_remove_requested(index):
	remove_branch(index)
	_correct_labels()
	emit_signal("modified")


func _correct_labels() -> void:
	if get_child_count() > 1:
		for index in range(1, get_child_count()):
			_set_label(get_child(index), index == 1)


func _value_modified(index):
	emit_signal("modified")


func reconnect_signals():
	if get_child_count() > 1:
		for index in range(1, get_child_count()):
			get_child(index).disconnect("remove_requested", Callable(self, "_value_remove_requested"))
			get_child(index).disconnect("modified", Callable(self, "_value_modified"))
			get_child(index).connect("remove_requested", Callable(self, "_value_remove_requested").bind(index))
			get_child(index).connect("modified", Callable(self, "_value_modified").bind(index))


func _on_add_branch_button_pressed():
	var new_value_line = _create_branch()
	emit_signal("modified")

@tool
extends "EditorGraphNodeBase.gd"

const RandomBranch = preload("../../resources/graph/branches/RandomBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType


var _random_value_scene = preload("../branches/EditorRandomValue.tscn")


var _original_size: Vector2


func get_branches():
	var t: Array[RandomBranch] = []
	for index in range(1, get_child_count()):
		t.append(get_child(index).get_branch())
	return t


func set_branches(branches):
	clear_branches()
	for index in range(0, branches.size()):
		_add_branch(
			branches[index]
		)


func _add_branch(branch):
	var line = _create_branch()
	line.set_branch(
		branch
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
	var branch_resource = RandomBranch.new()
	new_value_line.branch_resource = branch_resource
	add_child(new_value_line)
	new_value_line.connect("remove_requested", Callable(self, "_value_remove_requested").bind(get_child_count() - 1))
	new_value_line.connect("modified", Callable(self, "_value_modified").bind(get_child_count() - 1))
	set_slot(get_child_count() - 1, false, 0, Color("#cff44c"), true, 0, Color("#cff44c"))
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


@tool
extends "EditorGraphNodeBase.gd"
## Editor node for managing Branch nodes with "if" semantics.


const IfBranch = preload("../../resources/graph/branches/IfBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType


var _if_value_scene = preload("../branches/EditorIfBranchValue.tscn")
var _original_size: Vector2


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


func get_branches():
	var t: Array[IfBranch] = []
	for index in range(1, get_child_count() - 1):
		t.append(get_child(index).get_branch())
	return t


func set_branches(branches):
	clear_branches()
	for index in range(0, branches.size()):
		_add_branch(
			branches[index],
			index == 0,
		)


func clear_branches():
	for index in range(get_child_count() - 2, 0, -1):
		remove_branch(index)


func remove_branch(index):
	removing_slot.emit(index)
	var node = get_child(index)
	remove_child(node)
	node_resource.remove_branch(node.get_branch())
	# This is the button slot
	set_slot(
		get_child_count() - 1,
		false,
		0,
		CONNECTOR_COLOUR,
		false,
		0,
		CONNECTOR_COLOUR
	)
	_disconnect_signals_for_branch(node)
	_reconnect_signals()
	# This should restore the control to the minimum required for the remaining
	# choices, but a bit more than strictly necessary horizontally.
	size = _original_size


func _add_branch(branch, is_first: bool) -> void:
	var line = _create_branch()
	line.set_branch(
		branch
	)
	_set_label(line, is_first)


func _set_label(line, is_first: bool) -> void:
	if is_first:
		line.set_label("if")
	else:
		line.set_label("elif")


func _move_dropped_branch_to_index(dropped, index):
	if dropped.get_parent() == self:
		if dropped.get_index() < index:
			index = index - 1
		if dropped.get_index() == index:
			return
		_move_branch_to_position(
			dropped,
			index
		)
	else:
		# This indicates a drag from a different node.
		dropped.prepare_to_change_parent()
		_add_branch_at_position(
			dropped,
			index
		)
	_correct_labels()
	modified.emit()


func _move_branch_to_position(branch, index):
	var current_index = branch.get_index()
	self.move_child(branch, index)
	
	# The resources will be at indices one less than in the GUI
	# because of the initial header section of the GUI
	node_resource.branches.insert(
		index - 1,
		node_resource.branches.pop_at(current_index - 1)
	)


func _add_branch_at_position(branch, index):
	self.add_child(branch)
	self.move_child(branch, index)
	# The resources will be at indices one less than in the GUI
	# because of the initial header section of the GUI
	node_resource.branches.insert(index - 1, branch.get_branch())
	_connect_signals_for_branch(branch, index)
	# This is the slot that will have been opened up by the insertion of the
	# dropped branch.
	set_slot(
		get_child_count() - 2,
		false,
		0,
		CONNECTOR_COLOUR,
		true,
		0,
		CONNECTOR_COLOUR
	)
	_reconnect_signals()


func _create_branch():
	var new_value_line = _if_value_scene.instantiate()
	var branch_resource = IfBranch.new()
	var is_first = get_child_count() - 2 == 0
	add_child(new_value_line)
	move_child(new_value_line, get_child_count() - 2)
	new_value_line.set_branch(branch_resource)
	_set_label(new_value_line, is_first)
	_connect_signals_for_branch(
		new_value_line,
		get_child_count() - 2
	)
	# This is the new branch
	set_slot(
		get_child_count() - 2,
		false,
		0,
		CONNECTOR_COLOUR,
		true,
		0,
		CONNECTOR_COLOUR
	)
	# This is the button slot
	set_slot(
		get_child_count() - 1,
		false,
		0,
		CONNECTOR_COLOUR,
		false,
		0,
		CONNECTOR_COLOUR
	)
	return new_value_line


func _on_branch_remove_requested(index):
	remove_branch(index)
	_correct_labels()
	modified.emit()


func _correct_labels() -> void:
	if get_child_count() > 2:
		for index in range(1, get_child_count() - 1):
			_set_label(get_child(index), index == 1)


func _on_branch_modified(index):
	modified.emit()


func _connect_signals_for_branch(branch, index):
	branch.remove_requested.connect(
		_on_branch_remove_requested.bind(
			index
		)
	)
	branch.modified.connect(
		_on_branch_modified.bind(
			index
		)
	)
	branch.dropped_after.connect(
		_on_branch_dropped_after.bind(
			branch
		)
	)
	branch.preparing_to_change_parent.connect(
		_on_branch_preparing_to_change_parent.bind(
			branch
		)
	)


func _disconnect_signals_for_branch(branch):
	branch.remove_requested.disconnect(
		_on_branch_remove_requested
	)
	branch.modified.disconnect(
		_on_branch_modified
	)
	branch.dropped_after.disconnect(
		_on_branch_dropped_after
	)
	branch.preparing_to_change_parent.disconnect(
		_on_branch_preparing_to_change_parent
	)


func _reconnect_signals():
	if get_child_count() > 2:
		for index in range(1, get_child_count() - 1):
			_disconnect_signals_for_branch(get_child(index))
			_connect_signals_for_branch(get_child(index), index)


func _on_add_branch_button_pressed():
	var new_value_line = _create_branch()
	modified.emit()


func _on_branch_dropped_after(dropped, after) -> void:
	_move_dropped_branch_to_index(
		dropped,
		after.get_index() + 1
	)


func _on_branch_preparing_to_change_parent(branch):
	# Remove the GUI branch and the resource branch from their parents.
	self.remove_branch(branch.get_index())
	node_resource.remove_branch(branch.get_branch())
	_correct_labels()


func _on_drag_target_dropped(arg, at_position) -> void:
	# Drop at the topmost separator - move the target to the top.
	_move_dropped_branch_to_index(
		arg,
		1
	)

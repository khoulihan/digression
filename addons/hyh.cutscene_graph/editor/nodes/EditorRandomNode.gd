@tool
extends "EditorGraphNodeBase.gd"
## Editor node for managing a Random branch resource node.

const RandomBranch = preload("../../resources/graph/branches/RandomBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

var _random_value_scene = preload("../branches/EditorRandomValue.tscn")
var _original_size: Vector2


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	# We want to retain the original width, but the original height
	# includes sample choices which are not yet removed.
	_original_size = Vector2(size.x, 0.0)
	set_branches(n.branches)


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.branches = get_branches()


## Clear the relationships of the underlying graph node.
func clear_node_relationships():
	super.clear_node_relationships()
	for branch in node_resource.branches:
		branch.next = -1


## Get the branch resources.
func get_branches():
	var t: Array[RandomBranch] = []
	for index in range(1, get_child_count()):
		t.append(get_child(index).get_branch())
	return t


## Set the branches in the UI from the provided array of resources.
func set_branches(branches):
	clear_branches()
	for index in range(0, branches.size()):
		_add_branch(
			branches[index]
		)


## Clear all branches.
func clear_branches():
	for index in range(get_child_count() - 1, 0, -1):
		remove_branch(index)


## Remove the specified branch.
func remove_branch(index):
	removing_slot.emit(index)
	var node = get_child(index)
	remove_child(node)
	node.remove_requested.disconnect(_on_branch_remove_requested)
	node.modified.disconnect(_on_branch_modified)
	_reconnect_signals()
	# This should restore the control to the minimum required for the remaining
	# choices, but a bit more than strictly necessary horizontally.
	size = _original_size


## Get an array of the port numbers for output connections.
func get_output_port_numbers() -> Array[int]:
	var ports: Array[int] = [0]
	for i in range(1, get_child_count()):
		ports.append(i)
	return ports


func _add_branch(branch):
	var line = _create_branch()
	line.set_branch(
		branch
	)


func _create_branch():
	var new_value_line = _random_value_scene.instantiate()
	var branch_resource = RandomBranch.new()
	new_value_line.branch_resource = branch_resource
	add_child(new_value_line)
	new_value_line.remove_requested.connect(
		_on_branch_remove_requested.bind(
			get_child_count() - 1
		)
	)
	new_value_line.modified.connect(
		_on_branch_modified.bind(
			get_child_count() - 1
		)
	)
	set_slot(
		get_child_count() - 1,
		false,
		0,
		CONNECTOR_COLOUR,
		true,
		0,
		CONNECTOR_COLOUR
	)
	return new_value_line


func _reconnect_signals():
	if get_child_count() > 1:
		for index in range(1, get_child_count()):
			get_child(index).remove_requested.disconnect(
				_on_branch_remove_requested
			)
			get_child(index).modified.disconnect(
				_on_branch_modified
			)
			get_child(index).remove_requested.connect(
				_on_branch_remove_requested.bind(index)
			)
			get_child(index).modified.connect(
				_on_branch_modified.bind(index)
			)


func _on_add_branch_button_pressed():
	var new_value_line = _create_branch()
	modified.emit()


func _on_branch_remove_requested(index):
	remove_branch(index)
	modified.emit()


func _on_branch_modified(index):
	modified.emit()


func _on_gui_input(ev):
	super._on_gui_input(ev)


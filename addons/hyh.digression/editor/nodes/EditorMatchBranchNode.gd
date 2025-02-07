@tool
extends "EditorGraphNodeBase.gd"
## Editor node for Branch nodes with "match" semantics.


const MatchBranch = preload("../../resources/graph/branches/MatchBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

var _branch_value_scene = preload("../branches/EditorMatchBranchValue.tscn")
var _original_size: Vector2
var _variable_name
var _variable_scope
var _variable_type

@onready var _variable_selection_control = $MC/VB/HeaderContainer/GC/VariableSelectionControl
@onready var _add_branch_button : Button = $AddBranchContainer/AddBranchButton


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	# We want to retain the original width, but the original height
	# includes sample branches which are not yet removed.
	_original_size = Vector2(size.x, 0.0)
	set_variable(n.variable)
	set_scope(n.scope)
	set_type(n.variable_type)
	if _variable_name != null and not _variable_name.is_empty():
		_variable_selection_control.configure_for_variable(
			_variable_name,
			_variable_scope,
			_variable_type,
		)
		_add_branch_button.disabled = false
	else:
		_add_branch_button.disabled = true
		
	set_branches(n.branches)


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.variable = get_variable()
	node_resource.scope = get_scope()
	node_resource.variable_type = get_type()
	node_resource.branches = get_branches()


## Clear the relationships of the underlying graph node.
func clear_node_relationships():
	super.clear_node_relationships()
	for branch in node_resource.branches:
		branch.next = -1


func get_variable():
	return _variable_name


func set_variable(val):
	_variable_name = val


func get_branches():
	var t: Array[MatchBranch] = []
	for index in range(1, get_child_count() - 1):
		t.append(get_child(index).get_branch())
	return t


func set_branches(branches):
	clear_branches()
	for branch in branches:
		_add_branch(branch)


func get_scope():
	return _variable_scope


func set_scope(val):
	_variable_scope = val


func get_type():
	return _variable_type


func set_type(val):
	_variable_type = val
	for index in range(1, get_child_count() - 1):
		get_child(index).set_type(val)


func clear_branches():
	for index in range(get_child_count() - 2, 0, -1):
		remove_branch(index)


func remove_branch(index):
	removing_slot.emit(index)
	var node = get_child(index)
	remove_child(node)
	node.remove_requested.disconnect(
		_on_branch_remove_requested
	)
	node.modified.disconnect(
		_on_branch_modified
	)
	node.dropped_after.disconnect(
		_on_branch_dropped_after
	)
	_reconnect_signals()
	# This should resize the control to the maximum required for the remaining
	# branches, vertically.
	size = _original_size


func _add_branch(branch):
	var line = _create_branch()
	line.set_branch(branch)


func _create_branch():
	var new_value_line = _branch_value_scene.instantiate()
	add_child(new_value_line)
	move_child(new_value_line, get_child_count() - 2)
	new_value_line.set_type(node_resource.variable_type)
	new_value_line.remove_requested.connect(
		_on_branch_remove_requested.bind(
			get_child_count() - 2
		)
	)
	new_value_line.modified.connect(
		_on_branch_modified.bind(
			get_child_count() - 2
		)
	)
	new_value_line.dropped_after.connect(
		_on_branch_dropped_after.bind(
			new_value_line
		)
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


func _reconnect_signals():
	if get_child_count() > 1:
		for index in range(1, get_child_count() - 1):
			get_child(index).remove_requested.disconnect(
				_on_branch_remove_requested
			)
			get_child(index).modified.disconnect(
				_on_branch_modified
			)
			get_child(index).dropped_after.disconnect(
				_on_branch_dropped_after
			)
			get_child(index).remove_requested.connect(
				_on_branch_remove_requested.bind(index)
			)
			get_child(index).modified.connect(
				_on_branch_modified.bind(index)
			)
			get_child(index).dropped_after.connect(
				_on_branch_dropped_after.bind(
					get_child(index)
				)
			)


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
		# TODO: Ensure this is implemented.
		dropped.prepare_to_change_parent()
		_add_branch_at_position(
			dropped,
			index
		)
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
	# TODO: Implement this to enable drag from other nodes
	#var size_diff = section.size.y
	#_sections_container.add_child(section)
	#_sections_container.move_child(section, index)
	#self.size = Vector2(self.size.x, self.size.y + size_diff)
	#node_resource.sections.insert(
	#	index,
	#	section.section_resource
	#)
	#section.populate_variants(_get_variants_for_selected_character())
	#_connect_signals_for_section(section)
	pass


func _on_add_branch_button_pressed():
	var new_value_line = _create_branch()
	new_value_line.set_branch(
		MatchBranch.new()
	)
	modified.emit()


func _on_branch_remove_requested(index):
	remove_branch(index)


func _on_branch_modified(index):
	modified.emit()


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_variable_selection_control_variable_selected(variable):
	set_variable(variable['name'])
	set_scope(variable['scope'])
	set_type(variable['type'])
	_variable_selection_control.configure_for_variable(
		_variable_name,
		_variable_scope,
		_variable_type,
	)
	for i in range(1, get_child_count() - 1):
		get_child(i).set_type(_variable_type)
	_add_branch_button.disabled = false
	modified.emit()


func _on_branch_dropped_after(dropped, after):
	_move_dropped_branch_to_index(
		dropped,
		after.get_index() + 1
	)


func _on_drag_target_dropped(arg: Variant, at_position: Variant) -> void:
	# Drop at the topmost separator - move the target to the top.
	_move_dropped_branch_to_index(
		arg,
		1
	)

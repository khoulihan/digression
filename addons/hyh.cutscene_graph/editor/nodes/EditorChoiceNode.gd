@tool
extends "EditorGraphNodeBase.gd"

const TranslationKey = preload("../../utility/TranslationKey.gd")

const ChoiceBranch = preload("../../resources/graph/branches/ChoiceBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

var _choice_value_scene = preload("../branches/EditorChoiceValue.tscn")

var _original_size: Vector2


func clear_choices():
	for index in range(get_child_count() - 1, 0, -1):
		remove_choice(index)


func remove_choice(index):
	emit_signal("removing_slot", index)
	var node = get_child(index)
	remove_child(node)
	node.disconnect("remove_requested", Callable(self, "_value_remove_requested"))
	reconnect_removal_signals()
	# This should restore the control to the minimum required for the remaining
	# choices, but a bit more than strictly necessary horizontally.
	# TODO: This is insufficient to reclaim the space used by condition nodes.
	size = _original_size


func set_choices(
	choices
):
	clear_choices()
	for index in range(0, choices.size()):
		_add_choice(
			choices[index]
		)


func get_choices():
	var t: Array[ChoiceBranch] = []
	for index in range(1, get_child_count()):
		t.append(get_child(index).get_choice())
	return t


func _add_choice(
	choice
):
	var line = _create_line()
	line.set_choice(
		choice
	)


func _create_line():
	var new_value_line = _choice_value_scene.instantiate()
	var choice_resource = ChoiceBranch.new()
	choice_resource.display_translation_key = TranslationKey.generate(
		graph.name,
		"choice"
	)
	new_value_line.choice_resource = choice_resource
	add_child(new_value_line)
	new_value_line.connect("remove_requested", Callable(self, "_value_remove_requested").bind(get_child_count() - 1))
	new_value_line.connect("modified", Callable(self, "_line_modified").bind(get_child_count() - 1))
	set_slot(get_child_count() - 1, false, 0, CONNECTOR_COLOUR, true, 0, CONNECTOR_COLOUR)
	return new_value_line


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	# We want to retain the original width, but the original height
	# includes sample choices which are not yet removed.
	_original_size = Vector2(size.x, 0.0)
	set_choices(
		n.choices
	)


func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.choices = get_choices()


func clear_node_relationships():
	super.clear_node_relationships()
	for choice in node_resource.choices:
		choice.next = -1


func _on_AddValueButton_pressed():
	_create_line()
	emit_signal("modified")


func _value_remove_requested(index):
	remove_choice(index)
	emit_signal("modified")


func _line_modified(index):
	emit_signal("modified")


func _get_theme(control):
	var theme = null
	while control != null && "theme" in control:
		theme = control.theme
		if theme != null: break
		control = control.get_parent()
	return theme


func reconnect_removal_signals():
	if get_child_count() > 1:
		for index in range(1, get_child_count()):
			get_child(index).disconnect("remove_requested", Callable(self, "_value_remove_requested"))
			get_child(index).connect("remove_requested", Callable(self, "_value_remove_requested").bind(index))


func _on_gui_input(ev):
	super._on_gui_input(ev)

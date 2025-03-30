@tool
extends "EditorGraphNodeBase.gd"
## Node for exiting a graph or stopping all graph processing, optionally with
## and exit value.


@onready var _exit_type_option := $MC/VB/HB/ExitTypeOption
@onready var _exit_value := $MC/VB/ExitValue


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	_exit_type_option.select(n.exit_type)
	_exit_value.value_resource = n.value


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.exit_type = _exit_type_option.selected
	node_resource.value = _exit_value.value_resource


func _on_exit_type_option_item_selected(index: int) -> void:
	node_resource.exit_type = index
	modified.emit()

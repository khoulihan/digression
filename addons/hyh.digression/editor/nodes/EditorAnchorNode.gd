@tool
extends "EditorGraphNodeBase.gd"


@onready var _name_line_edit = $MC/GC/NameLineEdit


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	self.set_name(n.name)


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.name = self.get_name()


## Return the name of the anchor.
func get_name():
	return _name_line_edit.text


## Set the anchor name.
func set_name(name):
	_name_line_edit.text = name


func _on_name_line_edit_text_changed(new_text):
	persist_changes_to_node()
	modified.emit()


func _on_gui_input(ev):
	super._on_gui_input(ev)

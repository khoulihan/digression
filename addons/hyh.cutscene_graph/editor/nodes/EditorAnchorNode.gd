@tool
extends "EditorGraphNodeBase.gd"


@onready var NameLineEdit = get_node("MarginContainer/GridContainer/NameLineEdit")


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	self.set_name(n.name)


func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.name = self.get_name()


func get_name():
	return NameLineEdit.text


func set_name(name):
	NameLineEdit.text = name


func _on_name_line_edit_text_changed(new_text):
	persist_changes_to_node()
	modified.emit()


func _on_gui_input(ev):
	super._on_gui_input(ev)

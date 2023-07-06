@tool
extends "EditorGraphNodeBase.gd"


@onready var CommentEdit = get_node("MarginContainer/CommentEdit")


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	self.set_comment(n.comment)


func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.comment = self.get_comment()


func get_comment():
	return CommentEdit.text


func set_comment(comment):
	CommentEdit.text = comment


func _on_comment_edit_text_changed():
	emit_signal("modified")


func _on_resize_request(new_minsize):
	self.set_size(new_minsize)


func _on_node_selected():
	self.show_close = true
	self.resizable = true


func _on_node_deselected():
	self.show_close = false
	self.resizable = false

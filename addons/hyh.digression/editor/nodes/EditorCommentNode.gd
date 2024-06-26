@tool
extends "EditorGraphNodeBase.gd"
## A non-functional, non-connectable node for displaying comments in the editor.


@onready var _comment_edit = $MC/CommentEdit


## Configure the editor node for the provided resource node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	if n.size != Vector2.ZERO:
		size = n.size
	self.set_comment(n.comment)


## Save the state of the editor node to the resource.
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.size = self.size
	node_resource.comment = self.get_comment()


## Get the comment displayed in the UI.
func get_comment():
	return _comment_edit.text


## Set the comment text.
func set_comment(comment):
	_comment_edit.text = comment


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

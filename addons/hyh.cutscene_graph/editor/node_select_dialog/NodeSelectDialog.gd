@tool
extends Window


signal cancelled()
signal selected(node)



func _on_node_select_dialog_contents_cancelled():
	cancelled.emit()


func _on_node_select_dialog_contents_selected(node):
	selected.emit(node)


func _on_close_requested():
	cancelled.emit()

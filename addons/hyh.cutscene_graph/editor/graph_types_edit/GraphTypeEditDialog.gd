@tool
extends Window


signal closing()


func configure():
	$GraphTypeEditDialogContents.configure()


func _on_graph_type_edit_dialog_contents_closing():
	closing.emit()


func _on_close_requested():
	closing.emit()

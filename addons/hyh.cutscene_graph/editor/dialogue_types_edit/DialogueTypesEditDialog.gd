@tool
extends Window


signal closing()


func configure():
	$DialogueTypesEditDialogContents.configure()


func _on_dialogue_types_edit_dialog_contents_closing():
	closing.emit()


func _on_close_requested():
	closing.emit()

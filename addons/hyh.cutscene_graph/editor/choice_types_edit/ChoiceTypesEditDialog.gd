@tool
extends Window


signal closing()


func configure():
	$ChoiceTypesEditDialogContents.configure()


func _on_close_requested():
	closing.emit()


func _on_choice_types_edit_dialog_contents_closing():
	closing.emit()

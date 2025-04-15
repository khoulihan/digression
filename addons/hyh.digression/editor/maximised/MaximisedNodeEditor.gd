@tool
extends MarginContainer


signal restore_requested()


func _on_restore_button_pressed() -> void:
	restore_requested.emit()

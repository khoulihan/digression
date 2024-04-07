@tool
extends Window
## Dialogue type definition dialog.


signal closing()

@onready var _background_panel = $BackgroundPanel


func _ready() -> void:
	_background_panel.color = get_theme_color("base_color", "Editor")


## Prepare the dialog for display.
func configure():
	$DialogueTypesEditDialogContents.configure()


func _on_dialogue_types_edit_dialog_contents_closing():
	closing.emit()


func _on_close_requested():
	closing.emit()

@tool
extends Window
## Choice type definition dialog.


signal closing()

@onready var _background_panel = $BackgroundPanel


func _ready() -> void:
	_background_panel.color = get_theme_color("base_color", "Editor")


## Prepare the dialog for display.
func configure() -> void:
	$ChoiceTypesEditDialogContents.configure()


func _on_close_requested() -> void:
	closing.emit()


func _on_choice_types_edit_dialog_contents_closing() -> void:
	closing.emit()

@tool
extends Window
## Graph type definition dialog.


signal closing()


@onready var _background_panel = $BackgroundPanel


func _ready() -> void:
	_background_panel.color = get_theme_color("base_color", "Editor")


## Prepare the dialog for display.
func configure() -> void:
	$GraphTypeEditDialogContents.configure()


func _on_graph_type_edit_dialog_contents_closing():
	closing.emit()


func _on_close_requested():
	closing.emit()

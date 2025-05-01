@tool
extends Window
## Dialog for defining custom properties to be assigned to resources.


signal closing()

@onready var _background_panel = get_node("BackgroundPanel")


func _ready() -> void:
	_background_panel.color = get_theme_color("base_color", "Editor")


## Prepare the dialog for display.
func configure() -> void:
	$PropertyDefinitionEditDialogContents.configure()


func _on_close_requested():
	closing.emit()


func _on_property_definition_edit_dialog_contents_closing():
	closing.emit()

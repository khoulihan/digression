@tool
extends Window


@onready var BackgroundPanel = get_node("BackgroundPanel")


signal closing()


func _ready() -> void:
	BackgroundPanel.color = get_theme_color("base_color", "Editor")


func configure():
	$PropertyDefinitionEditDialogContents.configure()


func _on_close_requested():
	closing.emit()


func _on_property_definition_edit_dialog_contents_closing():
	closing.emit()

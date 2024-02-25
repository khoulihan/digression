@tool
extends Window


enum PropertyUse {
	SCENES,
	CHARACTERS,
	VARIANTS,
	CHOICES,
	DIALOGUE,
}


signal selected(property)
signal cancelled()

@onready var BackgroundPanel = get_node("BackgroundPanel")

var use_restriction : PropertyUse


func _ready() -> void:
	BackgroundPanel.color = get_theme_color("base_color", "Editor")


func _on_property_select_dialog_contents_selected(property):
	selected.emit(property)


func _on_close_requested():
	cancelled.emit()


func _on_property_select_dialog_contents_cancelled():
	cancelled.emit()

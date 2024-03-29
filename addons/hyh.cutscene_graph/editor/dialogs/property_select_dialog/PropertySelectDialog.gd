@tool
extends Window
## Dialog for selecting custom properties.


signal selected(property)
signal cancelled()

## The use cases for custom properties.
enum PropertyUse {
	SCENES,
	CHARACTERS,
	VARIANTS,
	CHOICES,
	DIALOGUE,
}

## The use that is applicable to the context in which the search is being performed.
var use_restriction : PropertyUse

@onready var _background_panel = get_node("BackgroundPanel")


func _ready() -> void:
	_background_panel.color = get_theme_color("base_color", "Editor")


func _on_property_select_dialog_contents_selected(property):
	selected.emit(property)


func _on_close_requested():
	cancelled.emit()


func _on_property_select_dialog_contents_cancelled():
	cancelled.emit()

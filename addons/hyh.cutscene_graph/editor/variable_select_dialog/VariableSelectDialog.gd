@tool
extends Window
## Dialog for selecting variables.


signal selected(variable)
signal cancelled()

const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

## The type to limit the results to.
var type_restriction : Variant

@onready var _background_panel = $BackgroundPanel


func _ready() -> void:
	_background_panel.color = get_theme_color("base_color", "Editor")


func _on_variable_select_dialog_contents_cancelled():
	cancelled.emit()


func _on_variable_select_dialog_contents_selected(variable):
	selected.emit(variable)


func _on_close_requested():
	cancelled.emit()

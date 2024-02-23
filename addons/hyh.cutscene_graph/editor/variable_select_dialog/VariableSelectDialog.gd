@tool
extends Window


const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType


signal selected(variable)
signal cancelled()

@onready var BackgroundPanel = get_node("BackgroundPanel")

var type_restriction : Variant


func _ready() -> void:
	BackgroundPanel.color = get_theme_color("base_color", "Editor")


func _on_variable_select_dialog_contents_cancelled():
	cancelled.emit()


func _on_variable_select_dialog_contents_selected(variable):
	selected.emit(variable)


func _on_close_requested():
	cancelled.emit()

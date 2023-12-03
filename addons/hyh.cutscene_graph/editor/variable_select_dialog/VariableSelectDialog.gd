@tool
extends Window


const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType


signal selected(variable)
signal cancelled()


var type_restriction : Variant


func _on_variable_select_dialog_contents_cancelled():
	cancelled.emit()


func _on_variable_select_dialog_contents_selected(variable):
	selected.emit(variable)


func _on_close_requested():
	cancelled.emit()

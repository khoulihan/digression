@tool
extends HBoxContainer


const NodeSelectDialog = preload("res://addons/hyh.cutscene_graph/editor/node_select_dialog/NodeSelectDialog.tscn")


@onready var SelectionName = $SelectionName
@onready var ValidationWarning = $ValidationWarning

@export var required = true


signal node_selected(path)
signal node_cleared()


var _path: NodePath


func populate(path):
	_path = path
	if _path != null and not _path.is_empty():
		SelectionName.text = path.get_concatenated_names()
		ValidationWarning.clear_warning()
	else:
		SelectionName.text = ""
		if required:
			ValidationWarning.set_warning("A node is required.")


func get_selected_path():
	return _path


func _on_search_button_pressed():
	var dialog = NodeSelectDialog.instantiate()
	dialog.cancelled.connect(_node_selection_cancelled.bind(dialog))
	dialog.selected.connect(_node_selected.bind(dialog))
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	get_tree().root.add_child(dialog)
	dialog.popup()


func _node_selected(path, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	populate(path)
	node_selected.emit(_path)


func _node_selection_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _on_clear_button_pressed():
	SelectionName.text = ""
	_path = NodePath()
	if required:
		ValidationWarning.set_warning("A node is required.")
	node_cleared.emit()

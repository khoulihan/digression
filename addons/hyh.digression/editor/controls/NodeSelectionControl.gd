@tool
extends HBoxContainer
## Control for allowing a NodePath to be selected from the currently edited scene.


signal node_selected(path)
signal node_cleared()

const NodeSelectDialog = preload("../dialogs/node_select_dialog/NodeSelectDialog.tscn")

@export var required = true

var _path: NodePath

@onready var _selection_name = $SelectionName
@onready var _validation_warning = $ValidationWarning


## Populate the control with the specified path.
func populate(path):
	_path = path
	if _path != null and not _path.is_empty():
		if _path == NodePath("."):
			var root = EditorInterface.get_edited_scene_root()
			_selection_name.text = root.name
		else:
			_selection_name.text = path.get_concatenated_names()
		_validation_warning.clear_warning()
	else:
		_selection_name.text = ""
		if required:
			_validation_warning.set_warning("A node is required.")


## Get the selected path.
func get_selected_path():
	return _path


func _on_search_button_pressed():
	var dialog = NodeSelectDialog.instantiate()
	dialog.cancelled.connect(_on_node_selection_cancelled.bind(dialog))
	dialog.selected.connect(_on_node_selected.bind(dialog))
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	get_tree().root.add_child(dialog)
	dialog.popup()


func _on_node_selected(path, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	populate(path)
	node_selected.emit(_path)


func _on_node_selection_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _on_clear_button_pressed():
	_selection_name.text = ""
	_path = NodePath()
	if required:
		_validation_warning.set_warning("A node is required.")
	node_cleared.emit()

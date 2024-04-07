@tool
extends "EditorGraphNodeBase.gd"
## Editor node for a Sub-Graph resource node.


signal sub_graph_open_requested(path)
signal display_filesystem_path_requested(path)

enum SubGraphMenuItems {
	CREATE_NEW,
	SEP1,
	LOAD,
	EDIT,
	CLEAR,
	MAKE_UNIQUE,
	SAVE,
	SEP2,
	SHOW_IN_FILESYSTEM,
	SEP3,
	COPY,
	PASTE
}

const ResourceHelper = preload("../../utility/ResourceHelper.gd")
const DIALOGUE_GRAPH_ICON = preload("../../icons/icon_chat.svg")

var _popup: PopupMenu
var _resource_clipboard

@onready var _resource_button: Button = $MC/VB/HB/ResourceButton
@onready var _resource_menu_button: MenuButton = $MC/VB/HB/ResourceMenuButton


func _ready():
	_popup = _resource_menu_button.get_popup()
	_popup.index_pressed.connect(_on_popup_index_pressed)
	
	# Couldn't find a way to get this control to use the custom theme...
	# Otherwise it would have been very handy.
	#var res_picker = EditorResourcePicker.new()
	#get_node("MarginContainer/VBoxContainer").add_child(res_picker)
	#res_picker.base_type = "DigressionDialogueGraph"
	#res_picker.theme = self.theme
	
	super()


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	_display_sub_graph_on_button()


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	# Selecting the resource should already persist it to the node


## Set the clipboard.
func set_resource_clipboard(clipboard):
	_resource_clipboard = clipboard


func _sub_graph_selected(sub_graph):
	node_resource.sub_graph = sub_graph
	_display_sub_graph_on_button()
	modified.emit()


func _create_file_dialog(title, file_mode):
	var file_dialog = EditorFileDialog.new()
	file_dialog.title = title
	file_dialog.add_filter("*.tres")
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.file_mode = file_mode
	
	return file_dialog


func _display_error_dialog(message):
	var error_dialog = AcceptDialog.new()
	error_dialog.dialog_text = message
	get_tree().root.add_child(error_dialog)
	error_dialog.confirmed.connect(
		_on_error_dialog_confirmed.bind(error_dialog)
	)
	error_dialog.popup_centered()


func _clear():
	# TODO: This should definitely require confirmation
	node_resource.sub_graph = null
	_display_sub_graph_on_button()
	modified.emit()


func _configure_popup():
	var has_sub_graph = node_resource != null and node_resource.sub_graph != null
	var has_resource = node_resource != null
	_popup.set_item_disabled(SubGraphMenuItems.CREATE_NEW, false)
	_popup.set_item_disabled(SubGraphMenuItems.LOAD, false)
	_popup.set_item_disabled(SubGraphMenuItems.EDIT, not has_sub_graph)
	_popup.set_item_disabled(SubGraphMenuItems.CLEAR, not has_sub_graph)
	_popup.set_item_disabled(SubGraphMenuItems.COPY, not has_sub_graph)
	_popup.set_item_disabled(SubGraphMenuItems.MAKE_UNIQUE, not has_sub_graph)
	_popup.set_item_disabled(SubGraphMenuItems.SAVE, not has_sub_graph)
	_popup.set_item_disabled(
		SubGraphMenuItems.SHOW_IN_FILESYSTEM,
		not has_sub_graph or _resource_is_embedded()
	)
	_popup.set_item_disabled(
		SubGraphMenuItems.PASTE,
		not has_resource or not _clipboard_contents_pasteable()
	)


func _convert_position(pos):
	return get_screen_transform() * pos


func _copy_resource_to_clipboard():
	if node_resource == null:
		return
	if node_resource.sub_graph == null:
		return
	_resource_clipboard.contents = node_resource.sub_graph


func _paste_resource_from_clipboard():
	if node_resource == null:
		return
	if not _clipboard_contents_pasteable():
		return
	# TODO: If the clipboard contents is embedded and from a different scene
	# then it needs to be duplicated here I think, not just set.
	node_resource.sub_graph = _resource_clipboard.contents
	modified.emit()
	_display_sub_graph_on_button()


func _show_in_filesystem():
	if node_resource != null and node_resource.sub_graph != null:
		display_filesystem_path_requested.emit(
			node_resource.sub_graph.resource_path
		)


func _make_unique():
	if node_resource == null:
		return
	if node_resource.sub_graph == null:
		return
	
	var duplicate = node_resource.sub_graph.duplicate_with_nodes()
	node_resource.sub_graph = duplicate
	modified.emit()
	_display_sub_graph_on_button()


func _save_to_disk():
	var dialog = _create_file_dialog(
		"Save Dialogue Graph",
		EditorFileDialog.FILE_MODE_SAVE_FILE
	)
	dialog.file_selected.connect(
		_on_sub_graph_file_selected_for_saving.bind(dialog)
	)
	dialog.canceled.connect(
		_on_sub_graph_dialog_cancelled.bind(dialog)
	)
	get_tree().root.add_child(dialog)
	dialog.popup_centered_clamped(Vector2(800, 700))


func _display_load_dialog():
	var dialog = _create_file_dialog(
		"Load Dialogue Graph",
		EditorFileDialog.FILE_MODE_OPEN_FILE
	)
	dialog.file_selected.connect(
		_on_sub_graph_file_selected_for_opening.bind(dialog)
	)
	dialog.canceled.connect(
		_on_sub_graph_dialog_cancelled.bind(dialog)
	)
	get_tree().root.add_child(dialog)
	dialog.popup_centered_clamped(Vector2(800, 700))


func _display_sub_graph_on_button():
	if node_resource != null and node_resource.sub_graph != null:
		_resource_button.icon = DIALOGUE_GRAPH_ICON
		if node_resource.sub_graph.display_name != null and node_resource.sub_graph.display_name != "":
			_resource_button.text = node_resource.sub_graph.display_name
		elif node_resource.sub_graph.name != null and node_resource.sub_graph.name != "":
			_resource_button.text = node_resource.sub_graph.name
		else:
			_resource_button.text = "DigressionDialogueGraph"
	else:
		_resource_button.icon = null
		_resource_button.text = "<empty>"


func _resource_is_embedded():
	if node_resource == null:
		return false
	if node_resource.sub_graph == null:
		return false
	
	return ResourceHelper.is_embedded(node_resource.sub_graph)


func _clipboard_contents_pasteable():
	if _resource_clipboard == null:
		return false
	if _resource_clipboard.contents == null:
		return false
	return _resource_clipboard.contents is DigressionDialogueGraph


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_resource_button_pressed():
	if node_resource != null:
		if node_resource.sub_graph != null:
			sub_graph_open_requested.emit(node_resource.sub_graph)
			return
	
	_configure_popup()
	_popup.position = _convert_position(
		_resource_button.position + Vector2(0, _resource_button.size.y)
	)
	_popup.popup(Rect2(_popup.position, Vector2(_resource_button.size.x, 0)))


func _on_popup_index_pressed(index):
	match index:
		SubGraphMenuItems.CREATE_NEW:
			_sub_graph_selected(DigressionDialogueGraph.new())
		SubGraphMenuItems.LOAD:
			_display_load_dialog()
		SubGraphMenuItems.EDIT:
			sub_graph_open_requested.emit(node_resource.sub_graph)
		SubGraphMenuItems.CLEAR:
			_clear()
		SubGraphMenuItems.MAKE_UNIQUE:
			_make_unique()
		SubGraphMenuItems.SAVE:
			_save_to_disk()
		SubGraphMenuItems.SHOW_IN_FILESYSTEM:
			_show_in_filesystem()
		SubGraphMenuItems.COPY:
			_copy_resource_to_clipboard()
		SubGraphMenuItems.PASTE:
			_paste_resource_from_clipboard()


func _on_resource_menu_button_about_to_popup():
	_configure_popup()


func _on_sub_graph_file_selected_for_opening(path, dialog):
	get_tree().root.remove_child(dialog)
	var res = load(path)
	if not res is DigressionDialogueGraph:
		_display_error_dialog("The selected resource is not a DigressionDialogueGraph.")
		return
	_sub_graph_selected(res)


func _on_sub_graph_file_selected_for_saving(path, dialog):
	get_tree().root.remove_child(dialog)
	ResourceSaver.save(node_resource.sub_graph, path)
	# Does the reource also need to "take over" the path?
	node_resource.sub_graph.take_over_path(path)
	modified.emit()
	_display_sub_graph_on_button()


func _on_sub_graph_dialog_cancelled(dialog):
	get_tree().root.remove_child(dialog)


func _on_error_dialog_confirmed(d):
	get_tree().root.remove_child(d)

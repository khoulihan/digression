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

const Dialogs = preload("../dialogs/Dialogs.gd")
const ResourceHelper = preload("../../utility/ResourceHelper.gd")
const DIALOGUE_GRAPH_ICON = preload("../../icons/icon_chat.svg")
const EditorEntryPointAnchorNode = preload("../../editor/nodes/EditorEntryPointAnchorNode.gd")

var _popup: PopupMenu
var _resource_clipboard

@onready var _resource_button: Button = $MC/VB/HB/ResourceButton
@onready var _resource_menu_button: MenuButton = $MC/VB/HB/ResourceMenuButton
@onready var _entry_point_option: OptionButton = $MC/VB/HB2/EntryPointOption


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
	_configure_entry_point_options()


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	# Selecting the resource should already persist it to the node


## Set the clipboard.
func set_resource_clipboard(clipboard):
	_resource_clipboard = clipboard


func _sub_graph_selected(sub_graph):
	node_resource.sub_graph = sub_graph
	_configure_entry_point_options()
	_display_sub_graph_on_button()
	modified.emit()


func _display_error_dialog(message):
	Dialogs.show_error(message)


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


func _configure_entry_point_options():
	if node_resource == null:
		return
	
	_entry_point_option.clear()
	var id: int = 0
	_entry_point_option.add_item(
		EditorEntryPointAnchorNode.ENTRY_POINT_ANCHOR_NAME,
		id
	)
	_entry_point_option.selected = 0
	if node_resource.sub_graph == null:
		return
	var anchor_maps = node_resource.sub_graph.get_anchor_maps()
	var by_name = anchor_maps[0]
	var names = by_name.keys()
	names.sort()
	for name in names:
		if name == EditorEntryPointAnchorNode.ENTRY_POINT_ANCHOR_NAME:
			continue
		id += 1
		_entry_point_option.add_item(name, id)
		if node_resource.entry_point != null and name == node_resource.entry_point.name:
			_entry_point_option.selected = _entry_point_option.item_count - 1


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
	var path := await Dialogs.select_file_for_save(
		["*.tres", "Digression Graph Resource Files"],
		self,
		"Save Dialogue Graph Resource",
		EditorFileDialog.ACCESS_RESOURCES,
	)
	if not path.is_empty():
		_save_graph_to_file(path)


func _save_graph_to_file(path):
	ResourceSaver.save(node_resource.sub_graph, path)
	# Does the reource also need to "take over" the path?
	node_resource.sub_graph.take_over_path(path)
	modified.emit()
	_display_sub_graph_on_button()


func _display_load_dialog():
	var path := await Dialogs.select_file_for_open(
		["*.tres", "Digression Graph Resource Files"],
		self,
		"Load Dialogue Graph Resource",
		EditorFileDialog.ACCESS_RESOURCES,
	)
	if not path.is_empty():
		_load_graph_from_file(path)


func _load_graph_from_file(path):
	var res = load(path)
	if not res is DigressionDialogueGraph:
		_display_error_dialog("The selected resource is not a DigressionDialogueGraph.")
		return
	_sub_graph_selected(res)


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


func _on_entry_point_option_item_selected(index: int) -> void:
	if node_resource == null:
		return
	if node_resource.sub_graph == null:
		return
	var anchor_maps = node_resource.sub_graph.get_anchor_maps()
	var name = _entry_point_option.get_item_text(index)
	if name == EditorEntryPointAnchorNode.ENTRY_POINT_ANCHOR_NAME:
		node_resource.entry_point = null
	else:
		node_resource.entry_point = node_resource.sub_graph.nodes[anchor_maps[0][name]]
	modified.emit()

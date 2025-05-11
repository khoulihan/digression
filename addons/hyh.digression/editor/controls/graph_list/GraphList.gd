@tool
extends ItemList


signal toggle_panel_requested


enum GraphListPopupMenuIndices {
	SAVE,
	SAVE_AS,
	CLOSE,
	CLOSE_ALL,
	CLOSE_OTHERS,
	SEPARATOR1,
	COPY_PATH,
	SHOW_IN_FILESYSTEM,
	SEPARATOR2,
	MOVE_UP,
	MOVE_DOWN,
	SORT,
	TOGGLE_PANEL,
}


const OpenGraphManager = preload("../../open_graphs/OpenGraphManager.gd")
const OpenGraph = OpenGraphManager.OpenGraph
const GRAPH_ICON = preload("res://addons/hyh.digression/icons/icon_chat.svg")
const UNNAMED_GRAPH = "Unnamed Graph"


@onready var _popup_menu: PopupMenu = $"../../PopupMenu"


var _manager: OpenGraphManager
var _current_filter : String = ""
var _filtered : Array[OpenGraph]


func _ready() -> void:
	self.item_selected.connect(_on_item_selected)
	_configure_popup_menu()


## Configure the list for the provided OpenGraphManager.
func configure(manager: OpenGraphManager) -> void:
	_manager = manager
	_manager.graph_edited.connect(_on_manager_graph_edited)
	_manager.list_changed.connect(_on_manager_list_changed)


## Clear the list
func clear_list() -> void:
	self.clear()


## Select the first graph with the specified name.
func select_graph(name: String) -> void:
	self.deselect_all()
	if self.item_count == 0 or name == "":
		return
	for index in range(0, self.item_count):
		if self.get_item_metadata(index).graph.name == name:
			self.select(index)
			return


## Select the graph with the specified resource path.
func select_graph_by_resource_path(path: String) -> void:
	self.deselect_all()
	if self.item_count == 0 or path == "":
		return
	for index in range(0, self.item_count):
		if self.get_item_metadata(index).graph.resource_path == path:
			self.select(index)
			return


## Select the first graph in the list. This is primarily used when the filter
## control is submitted.
func select_first_graph() -> void:
	if self.item_count > 0:
		self.select(0)
		_on_item_selected(0)


## Set the current filter and refresh the control.
func filter(f: String) -> void:
	_current_filter = f
	_refresh()


func _configure_popup_menu() -> void:
	# TODO: This seems very convoluted
	# Also, incomplete.
	# Also, maybe these shortcuts should be configurable.
	var save_shortcut := Shortcut.new()
	var save_shortcut_event := InputEventKey.new()
	save_shortcut_event.ctrl_pressed = true
	save_shortcut_event.alt_pressed = true
	save_shortcut_event.keycode = KEY_S
	save_shortcut.events.append(save_shortcut_event)
	_popup_menu.set_item_shortcut(GraphListPopupMenuIndices.SAVE, save_shortcut)


func _refresh() -> void:
	_filtered = _manager.filter(_current_filter)
	
	self.clear()
	for g in _filtered:
		var new_index = self.add_item(_item_text_for_graph(g), GRAPH_ICON)
		self.set_item_metadata(new_index, g)
		self.set_item_tooltip(new_index, g.path)


func _item_text_for_graph(graph: OpenGraph) -> String:
	return graph.graph.get_combined_name()


func _close_graph(item_index: int) -> void:
	pass


func _copy_path(item_index: int) -> void:
	var graph: OpenGraph = get_item_metadata(item_index)
	DisplayServer.clipboard_set(graph.graph.resource_path)


func _show_in_filesystem(item_index: int) -> void:
	var graph: OpenGraph = get_item_metadata(item_index)
	EditorInterface.get_file_system_dock().navigate_to_path(
		_strip_resource_id(
			graph.path
		)
	)


func _move_up(item_index: int) -> void:
	var graph: OpenGraph = get_item_metadata(item_index)
	_manager.move_up(graph)


func _move_down(item_index: int) -> void:
	var graph: OpenGraph = get_item_metadata(item_index)
	_manager.move_down(graph)


func _sort() -> void:
	_manager.sort()


func _toggle_panel() -> void:
	toggle_panel_requested.emit()


func _strip_resource_id(path: String) -> String:
	if not path.contains("::"):
		return path
	var index := path.find("::")
	return path.substr(0, index)


func _on_manager_graph_edited(graph: Variant) -> void:
	# TODO: Could update the list in a more targeted way...
	_refresh()
	select_graph_by_resource_path(graph.graph.resource_path)


func _on_manager_list_changed() -> void:
	_refresh()
	select_graph_by_resource_path(_manager.current.graph.resource_path)


func _on_item_selected(index: int) -> void:
	var g := self.get_item_metadata(index) as OpenGraph
	_manager.request_open(g.graph)


func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	_popup_menu.position = self.global_position + at_position + Vector2(0.0, _popup_menu.size.y)
	_popup_menu.index_pressed.connect(_on_popup_menu_index_pressed.bind(index))
	_popup_menu.popup()
	await _popup_menu.popup_hide
	call_deferred("_disconnect_menu")


func _disconnect_menu() -> void:
	_popup_menu.index_pressed.disconnect(_on_popup_menu_index_pressed)


func _on_popup_menu_index_pressed(index: int, item_index: int) -> void:
	match index as GraphListPopupMenuIndices:
		GraphListPopupMenuIndices.CLOSE:
			_close_graph(item_index)
		GraphListPopupMenuIndices.COPY_PATH:
			_copy_path(item_index)
		GraphListPopupMenuIndices.SHOW_IN_FILESYSTEM:
			_show_in_filesystem(item_index)
		GraphListPopupMenuIndices.MOVE_UP:
			_move_up(item_index)
		GraphListPopupMenuIndices.MOVE_DOWN:
			_move_down(item_index)
		GraphListPopupMenuIndices.SORT:
			_sort()
		GraphListPopupMenuIndices.TOGGLE_PANEL:
			_toggle_panel()


func _on_popup_menu_popup_hide() -> void:
	pass

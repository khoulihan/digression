@tool
extends MarginContainer
## Graph type definition dialog contents.


signal closing()

enum GraphTypeTreeColumns {
	IS_DEFAULT,
	NAME,
	SPLIT_DIALOGUE,
}

enum GraphTypePopupMenuItem {
	SET_DEFAULT,
	UNSET_DEFAULT,
	REMOVE,
}

const Dialogs = preload("../../dialogs/Dialogs.gd")
const DigressionSettings = preload("../../settings/DigressionSettings.gd")
const Logging = preload("../../../utility/Logging.gd")
const DEFAULT_ICON = preload("../../../icons/icon_favourites.svg")
const WARNING_ICON = preload("../../../icons/icon_node_warning.svg")
const NEW_TYPE_NAME = "new_graph_type"

var _logger = Logging.new(Logging.DGE_EDITOR_LOG_NAME, Logging.DGE_EDITOR_LOG_LEVEL)

@onready var _type_tree: Tree = $VB/Tree
@onready var _remove_button: Button = $VB/HeaderButtonsContainer/RemoveButton
@onready var _set_default_button: Button = $VB/HeaderButtonsContainer/SetDefaultButton


func _ready() -> void:
	var types = DigressionSettings.get_graph_types()
	var root = _type_tree.create_item()
	_type_tree.set_column_title(
		GraphTypeTreeColumns.IS_DEFAULT,
		"Default"
	)
	_type_tree.set_column_expand(
		GraphTypeTreeColumns.IS_DEFAULT,
		false
	)
	_type_tree.set_column_title(
		GraphTypeTreeColumns.NAME,
		"Name"
	)
	_type_tree.set_column_expand(
		GraphTypeTreeColumns.NAME,
		true
	)
	_type_tree.set_column_title(
		GraphTypeTreeColumns.SPLIT_DIALOGUE,
		"Split Dialogue?"
	)
	_type_tree.set_column_expand(
		GraphTypeTreeColumns.SPLIT_DIALOGUE,
		false
	)
	for t in types:
		var item: TreeItem = _type_tree.create_item(root)
		_populate_item_for_type(item, t)


func _populate_item_for_type(item, type):
	item.set_cell_mode(
		GraphTypeTreeColumns.IS_DEFAULT,
		TreeItem.CELL_MODE_ICON
	)
	if type["default"]:
		item.set_icon(
			GraphTypeTreeColumns.IS_DEFAULT,
			DEFAULT_ICON
		)
	item.set_text(
		GraphTypeTreeColumns.NAME,
		type["name"]
	)
	item.set_editable(
		GraphTypeTreeColumns.NAME,
		true
	)
	item.set_cell_mode(
		GraphTypeTreeColumns.SPLIT_DIALOGUE,
		TreeItem.CELL_MODE_CHECK
	)
	item.set_checked(
		GraphTypeTreeColumns.SPLIT_DIALOGUE,
		type["split_dialogue"]
	)
	item.set_editable(
		GraphTypeTreeColumns.SPLIT_DIALOGUE,
		true
	)


func _perform_save():
	var root = _type_tree.get_root()
	var graph_types := []
	for gt in root.get_children():
		var t = {}
		t["name"] = gt.get_text(GraphTypeTreeColumns.NAME)
		# If true, dialogue nodes with multiple lines will be split and each line
		# treated separately. Otherwise the entire dialogue is returned at once.
		t["split_dialogue"] = gt.is_checked(GraphTypeTreeColumns.SPLIT_DIALOGUE)
		t["default"] = gt.get_icon(GraphTypeTreeColumns.IS_DEFAULT) != null
		graph_types.append(t)
	DigressionSettings.save_graph_types(graph_types)


func _set_selected_as_default():
	var selected = _type_tree.get_selected()
	for item in _type_tree.get_root().get_children():
		if item == selected:
			item.set_icon(
				GraphTypeTreeColumns.IS_DEFAULT,
				DEFAULT_ICON
			)
		else:
			item.set_icon(
				GraphTypeTreeColumns.IS_DEFAULT,
				null
			)


func _unset_selected_as_default():
	var selected = _type_tree.get_selected()
	selected.set_icon(
		GraphTypeTreeColumns.IS_DEFAULT,
		null
	)


func _remove_selected():
	var selected = _type_tree.get_selected()
	if selected == null:
		return
	selected.free()
	_set_button_states(false)


func _get_default_type_name():
	var existing = _get_default_name_count()
	if existing == 0:
		return NEW_TYPE_NAME
	return "%s_%s" % [
		NEW_TYPE_NAME,
		existing
	]


func _get_default_name_count():
	var count = 0
	var root = _type_tree.get_root()
	for gt in root.get_children():
		var name = gt.get_text(GraphTypeTreeColumns.NAME)
		if name.begins_with(NEW_TYPE_NAME):
			count += 1
	return count


func _set_button_states(item_selected):
	_remove_button.disabled = not item_selected
	_set_default_button.disabled = not item_selected


func _validate():
	var issues = false
	var all_names = {}
	var root = _type_tree.get_root()
	for gt in root.get_children():
		gt.set_icon(
			GraphTypeTreeColumns.NAME,
			null
		)
		gt.set_tooltip_text(
			GraphTypeTreeColumns.NAME,
			""
		)
		var name = gt.get_text(GraphTypeTreeColumns.NAME)
		if name in all_names.keys():
			all_names[name] += 1
		else:
			all_names[name] = 1
	for name in all_names.keys():
		if all_names[name] > 1:
			issues = true
			for gt in root.get_children():
				if gt.get_text(GraphTypeTreeColumns.NAME) == name:
					gt.set_icon(
						GraphTypeTreeColumns.NAME,
						WARNING_ICON
					)
					gt.set_tooltip_text(
						GraphTypeTreeColumns.NAME,
						"Duplicate name"
					)
	return issues


func _on_cancel_button_pressed():
	closing.emit()


func _on_save_button_pressed():
	if not _validate():
		_perform_save()
		closing.emit()
	else:
		Dialogs.show_error(
			"""There are graph items with duplicate names.
			Please correct the values and try again.""",
			self,
			Dialogs.VALIDATION_FAILED_DIALOG_TITLE
		)


func _on_tree_item_mouse_selected(position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var selected = _type_tree.get_selected()
		$PopupMenu.set_item_disabled(
			GraphTypePopupMenuItem.SET_DEFAULT,
			selected.get_icon(GraphTypeTreeColumns.IS_DEFAULT) != null
		)
		$PopupMenu.set_item_disabled(
			GraphTypePopupMenuItem.UNSET_DEFAULT,
			selected.get_icon(GraphTypeTreeColumns.IS_DEFAULT) == null
		)
		# Adding a little offset seems to be required to prevent an item
		# from being immediately chosen.
		$PopupMenu.position = Vector2(
			self.get_parent().position
		) + position + Vector2(20, 10)
		$PopupMenu.popup()


func _on_tree_nothing_selected():
	_set_button_states(false)


func _on_tree_item_icon_double_clicked():
	# This never seemed to be called
	pass


func _on_popup_menu_id_pressed(id):
	if id == GraphTypePopupMenuItem.SET_DEFAULT:
		_set_selected_as_default()
	elif id == GraphTypePopupMenuItem.REMOVE:
		_remove_selected()
		_validate()
	elif id == GraphTypePopupMenuItem.UNSET_DEFAULT:
		# Unset default
		_unset_selected_as_default()


func _on_tree_item_activated():
	_set_selected_as_default()


func _on_add_button_pressed():
	var root = _type_tree.get_root()
	var existing = root.get_child_count()
	var item: TreeItem = _type_tree.create_item(root)
	_populate_item_for_type(
		item,
		{
			"default": existing == 0,
			"name": _get_default_type_name(),
			"split_dialogue": true,
		},
	)
	_type_tree.set_selected(
		item,
		GraphTypeTreeColumns.NAME
	)
	_type_tree.edit_selected()


func _on_remove_button_pressed():
	_remove_selected()
	_validate()


func _on_set_default_button_pressed():
	_set_selected_as_default()


func _on_tree_item_selected():
	_set_button_states(true)


func _on_help_gui_input(event):
	var button_event = event as InputEventMouseButton
	if button_event == null:
		return
	# TODO: Doesn't seem to be possible to manually display the tooltip.
	# Maybe show a messagebox instead?
	#Help.get_tooltip()


func _on_tree_item_edited():
	_validate()

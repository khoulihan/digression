@tool
extends MarginContainer
## Contents of dialogue type definition dialog.


signal closing()

enum GraphTypesTreeColumns {
	ALLOWED,
	IS_DEFAULT,
	NAME,
}

enum DialogueTypesTreeColumns {
	NAME,
	INVOLVES_CHARACTER,
	SPLIT_DIALOGUE,
}

enum DialogueTypesPopupMenuItem {
	REMOVE,
}

const Dialogs = preload("../../dialogs/Dialogs.gd")
const DigressionSettings = preload("../../settings/DigressionSettings.gd")
const Logging = preload("../../../utility/Logging.gd")
const DEFAULT_ICON = preload("../../../icons/icon_favourites.svg")
const WARNING_ICON = preload("../../../icons/icon_node_warning.svg")
const NEW_TYPE_NAME = "new_dialogue_type"

var _graph_types: Array
var _graph_types_per_dialogue_type = {}
var _logger = Logging.new(Logging.DGE_EDITOR_LOG_NAME, Logging.DGE_EDITOR_LOG_LEVEL)

@onready var _dialogue_types_tree: Tree = $VB/HSplitContainer/DialogueTypesPane/VB/DialogueTypesTree
@onready var _graph_types_tree: Tree = $VB/HSplitContainer/GraphTypesPane/VB/GraphTypesTree
@onready var _remove_button: Button = $VB/HSplitContainer/DialogueTypesPane/VB/HeaderButtonsContainer/RemoveButton
@onready var _graph_types_pane_header: HBoxContainer = $VB/HSplitContainer/GraphTypesPane/VB/GraphTypesPaneHeader
@onready var _graph_types_pane_header_label: Label = $VB/HSplitContainer/GraphTypesPane/VB/GraphTypesPaneHeader/GraphTypesPaneHeaderLabel


func _ready() -> void:
	_graph_types = DigressionSettings.get_graph_types()
	
	var graph_types_root = _graph_types_tree.create_item()
	_graph_types_tree.set_column_title(
		GraphTypesTreeColumns.ALLOWED,
		"Allowed"
	)
	_graph_types_tree.set_column_expand(
		GraphTypesTreeColumns.ALLOWED,
		false
	)
	_graph_types_tree.set_column_title(
		GraphTypesTreeColumns.IS_DEFAULT,
		"Default"
	)
	_graph_types_tree.set_column_expand(
		GraphTypesTreeColumns.IS_DEFAULT,
		false
	)
	_graph_types_tree.set_column_title(
		GraphTypesTreeColumns.NAME,
		"Name"
	)
	_graph_types_tree.set_column_expand(
		GraphTypesTreeColumns.NAME,
		true
	)
	for t in _graph_types:
		var item: TreeItem = _graph_types_tree.create_item(graph_types_root)
		_populate_item_for_graph_type(item, t)
	
	var dialogue_types_root = _dialogue_types_tree.create_item()
	_dialogue_types_tree.set_column_title(
		DialogueTypesTreeColumns.NAME,
		"Name"
	)
	_dialogue_types_tree.set_column_expand(
		DialogueTypesTreeColumns.NAME,
		true
	)
	_dialogue_types_tree.set_column_title(
		DialogueTypesTreeColumns.INVOLVES_CHARACTER,
		"Involves Character?"
	)
	_dialogue_types_tree.set_column_expand(
		DialogueTypesTreeColumns.INVOLVES_CHARACTER,
		false
	)
	_dialogue_types_tree.set_column_title(
		DialogueTypesTreeColumns.SPLIT_DIALOGUE,
		"Split Dialogue?"
	)
	_dialogue_types_tree.set_column_expand(
		DialogueTypesTreeColumns.SPLIT_DIALOGUE,
		false
	)
	var types := DigressionSettings.get_dialogue_types()
	for t in types:
		var item: TreeItem = _dialogue_types_tree.create_item(dialogue_types_root)
		_populate_item_for_type(item, t)
	
	_hide_graph_types()


func _hide_graph_types():
	_graph_types_tree.hide()
	_graph_types_pane_header.hide()


func _show_graph_types():
	_graph_types_tree.show()
	_graph_types_pane_header.show()


func _populate_item_for_type(item, type):
	item.set_text(
		DialogueTypesTreeColumns.NAME,
		type["name"]
	)
	item.set_editable(
		DialogueTypesTreeColumns.NAME,
		true
	)
	item.set_cell_mode(
		DialogueTypesTreeColumns.INVOLVES_CHARACTER,
		TreeItem.CELL_MODE_CHECK
	)
	item.set_checked(
		DialogueTypesTreeColumns.INVOLVES_CHARACTER,
		type["involves_character"]
	)
	item.set_editable(
		DialogueTypesTreeColumns.INVOLVES_CHARACTER,
		true
	)
	item.set_cell_mode(
		DialogueTypesTreeColumns.SPLIT_DIALOGUE,
		TreeItem.CELL_MODE_CHECK
	)
	if type["split_dialogue"] == null:
		item.set_indeterminate(
			DialogueTypesTreeColumns.SPLIT_DIALOGUE,
			true
		)
	else:
		item.set_checked(
			DialogueTypesTreeColumns.SPLIT_DIALOGUE,
			type["split_dialogue"]
		)
	item.set_meta("split_dialogue", type["split_dialogue"])
	item.set_editable(
		DialogueTypesTreeColumns.SPLIT_DIALOGUE,
		true
	)
	
	# Add an entry relating this item to the graph types
	_add_graph_type_relations_for_item(item, type)


func _add_graph_type_relations_for_item(item, type=null):
	if type == null:
		type = {
			'allowed_in_graph_types': [],
			'default_in_graph_types': [],
		}
	var graph_type_relations = {}
	for gt in _graph_types:
		var gt_rel = {}
		gt_rel['allowed'] = gt['name'] in type['allowed_in_graph_types']
		gt_rel['default'] = gt['name'] in type['default_in_graph_types']
		graph_type_relations[gt['name']] = gt_rel
	_graph_types_per_dialogue_type[item] = graph_type_relations


func _populate_item_for_graph_type(item, type):
	item.set_cell_mode(
		GraphTypesTreeColumns.ALLOWED,
		TreeItem.CELL_MODE_CHECK
	)
	item.set_editable(
		GraphTypesTreeColumns.ALLOWED,
		true
	)
	item.set_cell_mode(
		GraphTypesTreeColumns.IS_DEFAULT,
		TreeItem.CELL_MODE_CHECK
	)
	item.set_editable(
		GraphTypesTreeColumns.IS_DEFAULT,
		true
	)
	item.set_text(
		GraphTypesTreeColumns.NAME,
		type["name"]
	)
	item.set_editable(
		GraphTypesTreeColumns.NAME,
		false
	)


func _perform_save():
	var root = _dialogue_types_tree.get_root()
	var dialogue_types := []
	for dt in root.get_children():
		var t = {}
		t["name"] = dt.get_text(DialogueTypesTreeColumns.NAME)
		if dt.is_indeterminate(DialogueTypesTreeColumns.SPLIT_DIALOGUE):
			t["split_dialogue"] = null
		else:
			t["split_dialogue"] = dt.is_checked(
				DialogueTypesTreeColumns.SPLIT_DIALOGUE
			)
		t["involves_character"] = dt.is_checked(
			DialogueTypesTreeColumns.INVOLVES_CHARACTER
		)
		
		t["allowed_in_graph_types"] = []
		t["default_in_graph_types"] = []
		var gt_rels = _graph_types_per_dialogue_type[dt]
		for gt in gt_rels:
			if gt_rels[gt]["allowed"]:
				t["allowed_in_graph_types"].append(gt)
				if gt_rels[gt]["default"]:
					t["default_in_graph_types"].append(gt)
		
		dialogue_types.append(t)
	DigressionSettings.save_dialogue_types(dialogue_types)


func _remove_selected():
	var selected = _dialogue_types_tree.get_selected()
	if selected == null:
		return
	_graph_types_per_dialogue_type.erase(selected)
	selected.free()
	_hide_graph_types()
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
	var root = _dialogue_types_tree.get_root()
	for gt in root.get_children():
		var name = gt.get_text(DialogueTypesTreeColumns.NAME)
		if name.begins_with(NEW_TYPE_NAME):
			count += 1
	return count


func _set_graph_panel_header(item):
	_graph_types_pane_header_label.text = "Graph Types for \"%s\"" % item.get_text(
		DialogueTypesTreeColumns.NAME
	)


func _configure_graph_tree_for_item(item):
	var gt_rels = _graph_types_per_dialogue_type[item]
	var graph_type_root = _graph_types_tree.get_root()
	for gt in graph_type_root.get_children():
		var gt_name = gt.get_text(GraphTypesTreeColumns.NAME)
		gt.set_checked(GraphTypesTreeColumns.ALLOWED, gt_rels[gt_name]['allowed'])
		if not gt_rels[gt_name]['allowed']:
			gt.set_indeterminate(GraphTypesTreeColumns.IS_DEFAULT, true)
		else:
			gt.set_indeterminate(GraphTypesTreeColumns.IS_DEFAULT, false)
			gt.set_checked(GraphTypesTreeColumns.IS_DEFAULT, gt_rels[gt_name]['default'])
		gt.set_editable(GraphTypesTreeColumns.IS_DEFAULT, gt_rels[gt_name]['allowed'])


func _set_button_states(item_selected):
	_remove_button.disabled = not item_selected


func _validate():
	var issues = false
	var all_names = {}
	var root = _dialogue_types_tree.get_root()
	for dt in root.get_children():
		dt.set_icon(
			DialogueTypesTreeColumns.NAME,
			null
		)
		dt.set_tooltip_text(
			DialogueTypesTreeColumns.NAME,
			""
		)
		var name = dt.get_text(DialogueTypesTreeColumns.NAME)
		if name == "":
			issues = true
			dt.set_icon(
				DialogueTypesTreeColumns.NAME,
				WARNING_ICON
			)
			dt.set_tooltip_text(
				DialogueTypesTreeColumns.NAME,
				"Empty name"
			)
			continue
		if name in all_names.keys():
			all_names[name] += 1
		else:
			all_names[name] = 1
	for name in all_names.keys():
		if all_names[name] > 1:
			issues = true
			for dt in root.get_children():
				if dt.get_text(DialogueTypesTreeColumns.NAME) == name:
					dt.set_icon(
						DialogueTypesTreeColumns.NAME,
						WARNING_ICON
					)
					dt.set_tooltip_text(
						DialogueTypesTreeColumns.NAME,
						"Duplicate name"
					)
	return issues


func _manage_split_dialogue_state():
	var selected = _dialogue_types_tree.get_selected()
	var selected_column = _dialogue_types_tree.get_selected_column()
	if selected_column == DialogueTypesTreeColumns.SPLIT_DIALOGUE:
		_set_split_dialogue_state(selected, selected_column)


func _set_split_dialogue_state(item, column):
	var state = null
	if item.has_meta("split_dialogue"):
		state = item.get_meta("split_dialogue")
	if state == null:
		item.set_checked(column, true)
		state = true
	elif state:
		item.set_checked(column, false)
		state = false
	else:
		item.set_indeterminate(column, true)
		state = null
	item.set_meta("split_dialogue", state)


func _update_graph_tree_relations_for_item(item):
	var gt_rels = _graph_types_per_dialogue_type[item]
	var graph_type_root = _graph_types_tree.get_root()
	for gt in graph_type_root.get_children():
		var gt_name = gt.get_text(GraphTypesTreeColumns.NAME)
		gt_rels[gt_name]['allowed'] = gt.is_checked(GraphTypesTreeColumns.ALLOWED)
		if not gt_rels[gt_name]['allowed']:
			gt.set_indeterminate(GraphTypesTreeColumns.IS_DEFAULT, true)
			gt.set_editable(GraphTypesTreeColumns.IS_DEFAULT, false)
		else:
			gt.set_indeterminate(GraphTypesTreeColumns.IS_DEFAULT, false)
			gt.set_editable(GraphTypesTreeColumns.IS_DEFAULT, true)
		gt_rels[gt_name]['default'] = gt.is_checked(GraphTypesTreeColumns.IS_DEFAULT)
		if gt_rels[gt_name]['default']:
			for other_item in _graph_types_per_dialogue_type:
				if other_item == item:
					continue
				_graph_types_per_dialogue_type[other_item][gt_name]['default'] = false


func _on_cancel_button_pressed():
	closing.emit()


func _on_save_button_pressed():
	if not _validate():
		_perform_save()
		closing.emit()
	else:
		Dialogs.show_error(
			"""There are dialogue types with invalid names.
			Please correct the values and try again.""",
			self,
			Dialogs.VALIDATION_FAILED_DIALOG_TITLE
		)


func _on_dialogue_tree_item_mouse_selected(position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		# Adding a little offset seems to be required to prevent an item
		# from being immediately chosen.
		$PopupMenu.position = Vector2(
			self.get_parent().position
		) + position + Vector2(20, 10)
		$PopupMenu.popup()


func _on_dialogue_tree_nothing_selected():
	_set_button_states(false)
	_hide_graph_types()


func _on_popup_menu_id_pressed(id):
	if id == DialogueTypesPopupMenuItem.REMOVE:
		_remove_selected()
		_validate()


func _on_add_button_pressed():
	var root = _dialogue_types_tree.get_root()
	var item: TreeItem = _dialogue_types_tree.create_item(root)
	_populate_item_for_type(
		item,
		{
			"name": _get_default_type_name(),
			"involves_character": true,
			"split_dialogue": null,
			"allowed_in_graph_types": [],
			"default_in_graph_types": [],
		},
	)
	_dialogue_types_tree.set_selected(
		item,
		DialogueTypesTreeColumns.NAME
	)
	_dialogue_types_tree.edit_selected()


func _on_remove_button_pressed():
	_remove_selected()
	_validate()


func _on_dialogue_tree_item_selected():
	_set_button_states(true)
	_show_graph_types()
	var item = _dialogue_types_tree.get_selected()
	_configure_graph_tree_for_item(
		item
	)
	_set_graph_panel_header(
		item
	)


func _on_help_gui_input(event):
	var button_event = event as InputEventMouseButton
	if button_event == null:
		return
	# TODO: Doesn't seem to be possible to manually display the tooltip.
	# Maybe show a messagebox instead?
	#Help.get_tooltip()


func _on_dialogue_tree_item_edited():
	_logger.debug("Item edited")
	_manage_split_dialogue_state()
	var selected = _dialogue_types_tree.get_selected()
	_set_graph_panel_header(selected)
	_validate()


func _on_graph_types_tree_item_edited():
	_update_graph_tree_relations_for_item(
		_dialogue_types_tree.get_selected()
	)

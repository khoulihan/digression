@tool
extends MarginContainer
## Choice type definition dialog contents.


signal closing()

enum GraphTypesTreeColumns {
	ALLOWED,
	IS_DEFAULT,
	NAME,
}

enum ChoiceTypesTreeColumns {
	NAME,
	INCLUDE_DIALOGUE,
	SKIP_FOR_REPEAT,
}

enum ChoiceTypesPopupMenuItem {
	REMOVE,
}

const Logging = preload("../../../utility/Logging.gd")
const DEFAULT_ICON = preload("../../../icons/icon_favourites.svg")
const WARNING_ICON = preload("../../../icons/icon_node_warning.svg")
const NEW_TYPE_NAME = "new_choice_type"

var _logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)
var _graph_types
var _graph_types_per_choice_type = {}

@onready var _choice_types_tree: Tree = $VB/HSplitContainer/ChoiceTypesPane/VB/ChoiceTypesTree
@onready var _graph_types_tree: Tree = $VB/HSplitContainer/GraphTypesPane/VB/GraphTypesTree
@onready var _remove_button: Button = $VB/HSplitContainer/ChoiceTypesPane/VB/HeaderButtonsContainer/RemoveButton
@onready var _graph_panel_header: HBoxContainer = $VB/HSplitContainer/GraphTypesPane/VB/GraphPanelHeader
@onready var _graph_panel_header_label: Label = $VB/HSplitContainer/GraphTypesPane/VB/GraphPanelHeader/GraphPanelHeaderLabel


func _ready() -> void:
	_graph_types = ProjectSettings.get_setting(
		"cutscene_graph_editor/graph_types",
		[]
	)
	
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
	
	var choice_types_root = _choice_types_tree.create_item()
	_choice_types_tree.set_column_title(
		ChoiceTypesTreeColumns.NAME,
		"Name"
	)
	_choice_types_tree.set_column_expand(
		ChoiceTypesTreeColumns.NAME,
		true
	)
	_choice_types_tree.set_column_title(
		ChoiceTypesTreeColumns.INCLUDE_DIALOGUE,
		"Include Dialogue?"
	)
	_choice_types_tree.set_column_expand(
		ChoiceTypesTreeColumns.INCLUDE_DIALOGUE,
		false
	)
	_choice_types_tree.set_column_title(
		ChoiceTypesTreeColumns.SKIP_FOR_REPEAT,
		"Skip for Repeat?"
	)
	_choice_types_tree.set_column_expand(
		ChoiceTypesTreeColumns.SKIP_FOR_REPEAT,
		false
	)
	var types = ProjectSettings.get_setting(
		"cutscene_graph_editor/choice_types",
		[]
	)
	for t in types:
		var item: TreeItem = _choice_types_tree.create_item(choice_types_root)
		_populate_item_for_type(item, t)
	
	_hide_graph_types()


func _hide_graph_types():
	_graph_types_tree.hide()
	_graph_panel_header.hide()


func _show_graph_types():
	_graph_types_tree.show()
	_graph_panel_header.show()


func _populate_item_for_type(item, type):
	item.set_text(
		ChoiceTypesTreeColumns.NAME,
		type["name"]
	)
	item.set_editable(
		ChoiceTypesTreeColumns.NAME,
		true
	)
	item.set_cell_mode(
		ChoiceTypesTreeColumns.INCLUDE_DIALOGUE,
		TreeItem.CELL_MODE_CHECK
	)
	item.set_checked(
		ChoiceTypesTreeColumns.INCLUDE_DIALOGUE,
		type["include_dialogue"]
	)
	item.set_editable(
		ChoiceTypesTreeColumns.INCLUDE_DIALOGUE,
		true
	)
	item.set_cell_mode(
		ChoiceTypesTreeColumns.SKIP_FOR_REPEAT,
		TreeItem.CELL_MODE_CHECK
	)
	item.set_checked(
		ChoiceTypesTreeColumns.SKIP_FOR_REPEAT,
		type["skip_for_repeat"]
	)
	item.set_editable(
		ChoiceTypesTreeColumns.SKIP_FOR_REPEAT,
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
	_graph_types_per_choice_type[item] = graph_type_relations


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
	var root = _choice_types_tree.get_root()
	var choice_types = []
	for dt in root.get_children():
		var t = {}
		t["name"] = dt.get_text(ChoiceTypesTreeColumns.NAME)
		t["skip_for_repeat"] = dt.is_checked(
			ChoiceTypesTreeColumns.SKIP_FOR_REPEAT
		)
		t["include_dialogue"] = dt.is_checked(
			ChoiceTypesTreeColumns.INCLUDE_DIALOGUE
		)
		
		t["allowed_in_graph_types"] = []
		t["default_in_graph_types"] = []
		var gt_rels = _graph_types_per_choice_type[dt]
		for gt in gt_rels:
			if gt_rels[gt]["allowed"]:
				t["allowed_in_graph_types"].append(gt)
				if gt_rels[gt]["default"]:
					t["default_in_graph_types"].append(gt)
		
		choice_types.append(t)
	ProjectSettings.set_setting(
		"cutscene_graph_editor/choice_types",
		choice_types,
	)
	ProjectSettings.save()


func _remove_selected():
	var selected = _choice_types_tree.get_selected()
	if selected == null:
		return
	_graph_types_per_choice_type.erase(selected)
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
	var root = _choice_types_tree.get_root()
	for gt in root.get_children():
		var name = gt.get_text(ChoiceTypesTreeColumns.NAME)
		if name.begins_with(NEW_TYPE_NAME):
			count += 1
	return count


func _set_graph_panel_header(item):
	_graph_panel_header_label.text = "Graph Types for \"%s\"" % item.get_text(
		ChoiceTypesTreeColumns.NAME
	)


func _configure_graph_tree_for_item(item):
	var gt_rels = _graph_types_per_choice_type[item]
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
	var root = _choice_types_tree.get_root()
	for dt in root.get_children():
		dt.set_icon(
			ChoiceTypesTreeColumns.NAME,
			null
		)
		dt.set_tooltip_text(
			ChoiceTypesTreeColumns.NAME,
			""
		)
		var name = dt.get_text(ChoiceTypesTreeColumns.NAME)
		if name == "":
			issues = true
			dt.set_icon(
				ChoiceTypesTreeColumns.NAME,
				WARNING_ICON
			)
			dt.set_tooltip_text(
				ChoiceTypesTreeColumns.NAME,
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
				if dt.get_text(ChoiceTypesTreeColumns.NAME) == name:
					dt.set_icon(
						ChoiceTypesTreeColumns.NAME,
						WARNING_ICON
					)
					dt.set_tooltip_text(
						ChoiceTypesTreeColumns.NAME,
						"Duplicate name"
					)
	return issues


func _update_graph_tree_relations_for_item(item):
	var gt_rels = _graph_types_per_choice_type[item]
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
			for other_item in _graph_types_per_choice_type:
				if other_item == item:
					continue
				_graph_types_per_choice_type[other_item][gt_name]['default'] = false


func _on_cancel_button_pressed():
	closing.emit()


func _on_save_button_pressed():
	if not _validate():
		_perform_save()
		closing.emit()
	else:
		var dialog = AcceptDialog.new()
		dialog.title = "Validation Failed"
		dialog.dialog_text = """There are choice types with invalid names.\n
			Please correct the values and try again."""
		self.add_child(dialog)
		dialog.popup_on_parent(
			Rect2i(
				self.position + Vector2(60, 60),
				Vector2i(200, 150)
			)
		)
		dialog.confirmed.connect(
			_validation_failed_dialog_closed.bind(dialog)
		)
		dialog.close_requested.connect(
			_validation_failed_dialog_closed.bind(dialog)
		)


func _validation_failed_dialog_closed(dialog):
	_logger.debug("Validation failed dialog closed.")
	dialog.confirmed.disconnect(_validation_failed_dialog_closed)
	dialog.close_requested.disconnect(_validation_failed_dialog_closed)
	dialog.queue_free()


func _on_popup_menu_id_pressed(id):
	if id == ChoiceTypesPopupMenuItem.REMOVE:
		_remove_selected()
		_validate()


func _on_add_button_pressed():
	var root = _choice_types_tree.get_root()
	var item: TreeItem = _choice_types_tree.create_item(root)
	_populate_item_for_type(
		item,
		{
			"name": _get_default_type_name(),
			"include_dialogue": true,
			"skip_for_repeat": false,
			"allowed_in_graph_types": [],
			"default_in_graph_types": [],
		},
	)
	_choice_types_tree.set_selected(
		item,
		ChoiceTypesTreeColumns.NAME
	)
	_choice_types_tree.edit_selected()


func _on_remove_button_pressed():
	_remove_selected()
	_validate()


func _on_choice_tree_item_selected():
	_set_button_states(true)
	_show_graph_types()
	var item = _choice_types_tree.get_selected()
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


func _on_choice_tree_item_edited():
	_logger.debug("Item edited")
	var selected = _choice_types_tree.get_selected()
	_set_graph_panel_header(selected)
	_validate()


func _on_graph_types_tree_item_edited():
	_update_graph_tree_relations_for_item(
		_choice_types_tree.get_selected()
	)


func _on_choice_tree_item_mouse_selected(position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		# Adding a little offset seems to be required to prevent an item
		# from being immediately chosen.
		$PopupMenu.position = Vector2(
			self.get_parent().position
		) + position + Vector2(20, 10)
		$PopupMenu.popup()


func _on_choice_tree_nothing_selected():
	_set_button_states(false)
	_hide_graph_types()

@tool
extends MarginContainer
## Variable select dialog contents.


signal selected(variable)
signal cancelled()

enum MatchesTreeColumns {
	SCOPE,
	TYPE,
	NAME,
	TAGS,
}

const DigressionSettings = preload("../../settings/DigressionSettings.gd")
const VariablesHelper = preload("../../helpers/VariablesHelper.gd")
const Logging = preload("../../../utility/Logging.gd")
const BOOL_ICON = preload("../../../icons/icon_type_bool.svg")
const INT_ICON = preload("../../../icons/icon_type_int.svg")
const FLOAT_ICON = preload("../../../icons/icon_type_float.svg")
const STRING_ICON = preload("../../../icons/icon_type_string.svg")
const TRANSIENT_ICON = preload("../../../icons/icon_scope_transient_light.svg")
const DIALOGUE_GRAPH_SCOPE_ICON = preload("../../../icons/icon_scope_dialogue_graph_light.svg")
const LOCAL_ICON = preload("../../../icons/icon_scope_local_light.svg")
const GLOBAL_ICON = preload("../../../icons/icon_scope_global_light.svg")
const VariableScope = preload("../../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType

var _logger = Logging.new(Logging.DGE_EDITOR_LOG_NAME, Logging.DGE_EDITOR_LOG_LEVEL)
var _type_restriction : Variant
var _all_variables = []
var _variables_for_scope = []
var _variables_for_search = []

@onready var _favourites_tree: Tree = $VB/BodyContainer/FavouritesPane/HB/FavouritesTree
@onready var _recent_tree: Tree = $VB/BodyContainer/FavouritesPane/HB/RecentTree
@onready var _scope_options_button: OptionButton = $VB/BodyContainer/SearchPane/VB/SearchContainer/ScopeOptionButton
@onready var _search_edit: LineEdit = $VB/BodyContainer/SearchPane/VB/SearchContainer/SearchEdit
@onready var _matches_tree: Tree = $VB/BodyContainer/SearchPane/VB/MatchesTree
@onready var _description_label: RichTextLabel = $VB/BodyContainer/SearchPane/VB/DescriptionLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	_type_restriction = get_parent().type_restriction
	_all_variables = _filter_by_type_restriction(
		_get_all_variables()
	)
	_perform_search()
	_matches_tree.set_column_expand(MatchesTreeColumns.SCOPE, false)
	_matches_tree.set_column_expand(MatchesTreeColumns.TYPE, false)
	_matches_tree.set_column_expand(MatchesTreeColumns.NAME, true)
	_matches_tree.set_column_expand(MatchesTreeColumns.TAGS, false)
	
	_favourites_tree.set_column_expand(MatchesTreeColumns.SCOPE, false)
	_favourites_tree.set_column_expand(MatchesTreeColumns.TYPE, false)
	_favourites_tree.set_column_expand(MatchesTreeColumns.NAME, true)
	
	_recent_tree.set_column_expand(MatchesTreeColumns.SCOPE, false)
	_recent_tree.set_column_expand(MatchesTreeColumns.TYPE, false)
	_recent_tree.set_column_expand(MatchesTreeColumns.NAME, true)
	
	_populate_matches()
	_load_favourites_and_recent()


func _get_all_variables() -> Array[Dictionary]:
	var variables := DigressionSettings.get_variables().duplicate()
	for bi in VariablesHelper.BUILT_IN_VARIABLES:
		variables.append(bi.duplicate(true))
	return variables


func _filter_by_type_restriction(vars):
	if _type_restriction == null:
		return vars
	var filtered = []
	for v in vars:
		if v['type'] == _type_restriction:
			filtered.append(v)
	return filtered


func _filter_by_scope(vars, scope):
	var filtered = []
	for v in vars:
		if v['scope'] == scope:
			filtered.append(v)
	return filtered


func _filter_by_search(vars, search):
	var filtered = []
	var lc_search = search.to_lower()
	for v in vars:
		if v['name'].to_lower().contains(lc_search):
			filtered.append(v)
			continue
		if _any_tag_matches(v, lc_search):
			filtered.append(v)
	return filtered


func _any_tag_matches(v, search):
	for tag in v['tags']:
		if tag.to_lower().contains(search):
			return true
	return false


func _perform_search():
	if _scope_options_button.selected != -1:
		_variables_for_scope = _filter_by_scope(
			_all_variables, _scope_options_button.selected
		)
	else:
		_variables_for_scope = _all_variables
	if _search_edit.text != "":
		_variables_for_search = _filter_by_search(
			_variables_for_scope,
			_search_edit.text
		)
	else:
		_variables_for_search = _variables_for_scope
	
	_variables_for_search.sort_custom(func(a, b):
		return a['name'].naturalnocasecmp_to(b['name']) < 0
	)


func _populate_matches():
	_matches_tree.clear()
	var root = _matches_tree.create_item()
	for v in _variables_for_search:
		var item = root.create_child()
		item.set_meta('scope', v['scope'])
		item.set_cell_mode(MatchesTreeColumns.SCOPE, TreeItem.CELL_MODE_ICON)
		item.set_icon(MatchesTreeColumns.SCOPE, _icon_for_scope(v['scope']))
		item.set_tooltip_text(
			MatchesTreeColumns.SCOPE,
			_tooltip_for_scope(v['scope'])
		)
		item.set_meta('type', v['type'])
		item.set_cell_mode(MatchesTreeColumns.TYPE, TreeItem.CELL_MODE_ICON)
		item.set_icon(MatchesTreeColumns.TYPE, _icon_for_type(v['type']))
		item.set_tooltip_text(
			MatchesTreeColumns.TYPE,
			_tooltip_for_type(v['type'])
		)
		item.set_meta('name', v['name'])
		item.set_text(MatchesTreeColumns.NAME, VariablesHelper.create_display_name(v['name']))
		item.set_tooltip_text(
			MatchesTreeColumns.NAME,
			"Variable Name"
		)
		item.set_text_alignment(MatchesTreeColumns.TAGS, HORIZONTAL_ALIGNMENT_RIGHT)
		item.set_text(MatchesTreeColumns.TAGS, ", ".join(v['tags']))
		item.set_custom_color(
			MatchesTreeColumns.TAGS,
			Color.SLATE_GRAY
		)
		item.set_custom_font_size(
			MatchesTreeColumns.TAGS,
			14
		)
		item.set_tooltip_text(
			MatchesTreeColumns.TAGS,
			"Tags"
		)


func _load_favourites_and_recent():
	var state = _load_state()
	_favourites_tree.clear()
	_favourites_tree.create_item()
	_recent_tree.clear()
	_recent_tree.create_item()
	if state != null:
		_populate_sidebar(_favourites_tree, state.favourites)
		_populate_sidebar(_recent_tree, state.recent)


func _populate_sidebar(sidebar, items):
	for item in items:
		var v = _get_match_by_name_and_type(item['name'], item['type'])
		if v == null:
			continue
		_add_to_sidebar(sidebar, v)


func _add_to_sidebar(sidebar, v, index=-1):
	var root = sidebar.get_root()
	var item = root.create_child(index)
	item.set_cell_mode(MatchesTreeColumns.SCOPE, TreeItem.CELL_MODE_ICON)
	item.set_meta('scope', v['scope'])
	item.set_icon(MatchesTreeColumns.SCOPE, _icon_for_scope(v['scope']))
	item.set_tooltip_text(
		MatchesTreeColumns.SCOPE,
		_tooltip_for_scope(v['scope'])
	)
	item.set_cell_mode(MatchesTreeColumns.TYPE, TreeItem.CELL_MODE_ICON)
	item.set_meta('type', v['type'])
	item.set_icon(MatchesTreeColumns.TYPE, _icon_for_type(v['type']))
	item.set_tooltip_text(
		MatchesTreeColumns.TYPE,
		_tooltip_for_type(v['type'])
	)
	item.set_text(
		MatchesTreeColumns.NAME,
		VariablesHelper.create_display_name(v['name'])
	)
	item.set_meta('name', v['name'])
	item.set_tooltip_text(
		MatchesTreeColumns.NAME,
		"Variable Name"
	)


func _perform_search_and_refresh():
	_perform_search()
	_populate_matches()


func _tooltip_for_scope(scope):
	match scope:
		VariableScope.SCOPE_TRANSIENT:
			return "Transient"
		VariableScope.SCOPE_DIALOGUE_GRAPH:
			return "Dialogue Graph"
		VariableScope.SCOPE_LOCAL:
			return "Local"
		VariableScope.SCOPE_GLOBAL:
			return "Global"
	return null


func _icon_for_scope(scope):
	match scope:
		VariableScope.SCOPE_TRANSIENT:
			return TRANSIENT_ICON
		VariableScope.SCOPE_DIALOGUE_GRAPH:
			return DIALOGUE_GRAPH_SCOPE_ICON
		VariableScope.SCOPE_LOCAL:
			return LOCAL_ICON
		VariableScope.SCOPE_GLOBAL:
			return GLOBAL_ICON
	return null


func _tooltip_for_type(t):
	match t:
		VariableType.TYPE_BOOL:
			return "Boolean"
		VariableType.TYPE_FLOAT:
			return "Float"
		VariableType.TYPE_INT:
			return "Integer"
		VariableType.TYPE_STRING:
			return "String"
	return null


func _icon_for_type(t):
	match t:
		VariableType.TYPE_BOOL:
			return BOOL_ICON
		VariableType.TYPE_FLOAT:
			return FLOAT_ICON
		VariableType.TYPE_INT:
			return INT_ICON
		VariableType.TYPE_STRING:
			return STRING_ICON
	return null


func _get_match_by_name_and_type(name, type):
	# Is this appropriate? Are we not going to allow the same name
	# for different scopes, for example?
	for v in _variables_for_search:
		if v['name'] == name and v['type'] == type:
			return v
	return null


func _set_description_for_selection():
	var selected = _matches_tree.get_selected()
	if selected == null:
		_description_label.text = ""
		return
	var selected_variable = _get_match_by_name_and_type(
		selected.get_meta('name'),
		selected.get_meta('type')
	)
	if selected_variable == null:
		_description_label.text = ""
	else:
		_description_label.text = selected_variable.get('description')


func _highlight_sidebar_selection(sidebar: Tree):
	var selection = sidebar.get_selected()
	if selection == null:
		return
	var selected_name = selection.get_meta('name')
	var selected_type = selection.get_meta('type')
	_search_edit.text = VariablesHelper.create_display_name(selected_name)
	_scope_options_button.select(-1)
	_perform_search_and_refresh()
	var matches_root = _matches_tree.get_root()
	for row in matches_root.get_children():
		if row.get_meta('name') == selected_name and \
			row.get_meta('type') == selected_type:
			_matches_tree.set_selected(row, MatchesTreeColumns.NAME)
			break


func _contains_variable(a, name, type):
	for v in a:
		if v['name'] == name and v['type'] == type:
			return true
	return false


func _index_of(a, name, type):
	for i in range(0, len(a)):
		if a[i]['name'] == name and a[i]['type'] == type:
			return i
	return -1


func _save_to_recent(variable_name, variable_type):
	var existing_state = _load_state()
	if existing_state == null:
		existing_state = VariableSelectDialogState.new()
	if _contains_variable(existing_state.recent, variable_name, variable_type):
		existing_state.recent.remove_at(
			_index_of(existing_state.recent, variable_name, variable_type)
		)
	existing_state.recent.insert(
		0,
		{
			'name': variable_name,
			'type': variable_type
		}
	)
	_save_state(
		existing_state.favourites,
		existing_state.recent
	)


func _load_state() -> VariableSelectDialogState:
	var config = ConfigFile.new()
	var err = config.load(
		"res://.godot/hyh.digression/variable_select_dialog.cfg"
	)
	if err != OK:
		return null
	
	var state = VariableSelectDialogState.new()
	state.favourites = config.get_value('state', 'favourites', [])
	state.recent = config.get_value('state', 'recent', [])
	return state


func _save_state(favourites: Array[Dictionary], recent: Array[Dictionary]):
	var config = ConfigFile.new()
	config.set_value('state', 'favourites', favourites)
	config.set_value('state', 'recent', recent)
	_logger.debug("About to save variable select dialog state")
	var dir = DirAccess.open("res://.godot")
	var dir_status = dir.make_dir("hyh.digression")
	_logger.debug("Directory create status: %s" % dir_status)
	var status = config.save("res://.godot/hyh.digression/variable_select_dialog.cfg")
	_logger.debug("File save status: %s" % status)


func _on_scope_option_button_item_selected(index):
	_perform_search_and_refresh()
	_set_description_for_selection()


func _on_search_edit_text_changed(new_text):
	_perform_search_and_refresh()
	_set_description_for_selection()


func _on_clear_scope_button_pressed():
	_scope_options_button.select(-1)
	_perform_search_and_refresh()
	_set_description_for_selection()


func _on_matches_tree_item_selected():
	_set_description_for_selection()


func _on_matches_tree_nothing_selected():
	_set_description_for_selection()


func _on_matches_tree_item_activated():
	_on_select_button_pressed()


func _on_cancel_button_pressed():
	cancelled.emit()


func _on_select_button_pressed():
	var selection = _matches_tree.get_selected()
	
	if selection == null:
		var alert = AcceptDialog.new()
		alert.get_label().text = "No variable is selected."
		get_tree().root.add_child(alert)
		alert.popup_centered()
		await alert.confirmed
		get_tree().root.remove_child(alert)
		alert.queue_free()
		return
	
	var variable_name = selection.get_meta('name')
	var variable_type = selection.get_meta('type')
	var variable = _get_match_by_name_and_type(
		variable_name,
		variable_type
	)
	_save_to_recent(variable_name, variable_type)
	selected.emit(variable)


func _on_favourite_button_pressed():
	var selection = _matches_tree.get_selected()
	if selection == null:
		return
	var selection_name = selection.get_meta('name')
	var selection_type = selection.get_meta('type')
	var existing_state = _load_state()
	if existing_state == null:
		existing_state = VariableSelectDialogState.new()
	if _contains_variable(existing_state.favourites, selection_name, selection_type):
		return
	existing_state.favourites.insert(
		0,
		{
			'name': selection_name,
			'type': selection_type
		}
	)
	_save_state(
		existing_state.favourites,
		existing_state.recent
	)
	# Add to favourites sidebar
	var v = _get_match_by_name_and_type(selection_name, selection_type)
	_add_to_sidebar(_favourites_tree, v, 0)


func _on_favourites_tree_item_selected():
	_highlight_sidebar_selection(_favourites_tree)


func _on_recent_tree_item_selected():
	_highlight_sidebar_selection(_recent_tree)


class VariableSelectDialogState:
	var favourites: Array[Dictionary]
	var recent: Array[Dictionary]

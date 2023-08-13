@tool
extends MarginContainer


const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

signal selected(variable)
signal cancelled()


const BoolIcon = preload("../../icons/icon_type_bool.svg")
const IntIcon = preload("../../icons/icon_type_int.svg")
const FloatIcon = preload("../../icons/icon_type_float.svg")
const StringIcon = preload("../../icons/icon_type_string.svg")

const TransientIcon = preload("../../icons/icon_scope_transient_light.svg")
const LocalIcon = preload("../../icons/icon_scope_local_light.svg")
const GlobalIcon = preload("../../icons/icon_scope_global_light.svg")

const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType


@onready var FavouritesTree: Tree = get_node("VBoxContainer/BodyContainer/FavouritesPane/HBoxContainer/FavouritesTree")
@onready var RecentTree: Tree = get_node("VBoxContainer/BodyContainer/FavouritesPane/HBoxContainer/RecentTree")
@onready var ScopeOptionsButton: OptionButton = get_node("VBoxContainer/BodyContainer/SearchPane/VBoxContainer/SearchContainer/ScopeOptionButton")
@onready var SearchEdit: LineEdit = get_node("VBoxContainer/BodyContainer/SearchPane/VBoxContainer/SearchContainer/SearchEdit")
@onready var FavouriteButton: Button = get_node("VBoxContainer/BodyContainer/SearchPane/VBoxContainer/MatchesTitleContainer/FavouriteButton")
@onready var MatchesTree: Tree = get_node("VBoxContainer/BodyContainer/SearchPane/VBoxContainer/MatchesTree")
@onready var DescriptionLabel: RichTextLabel = get_node("VBoxContainer/BodyContainer/SearchPane/VBoxContainer/DescriptionLabel")


enum MatchesTreeColumns {
	SCOPE,
	TYPE,
	NAME,
	TAGS,
}


var _all_variables = []
var _variables_for_scope = []
var _variables_for_search = []


# Called when the node enters the scene tree for the first time.
func _ready():
	_all_variables = ProjectSettings.get_setting(
		"cutscene_graph_editor/variables",
		[]
	)
	_perform_search()
	MatchesTree.set_column_expand(MatchesTreeColumns.SCOPE, false)
	MatchesTree.set_column_expand(MatchesTreeColumns.TYPE, false)
	MatchesTree.set_column_expand(MatchesTreeColumns.NAME, true)
	MatchesTree.set_column_expand(MatchesTreeColumns.TAGS, false)
	
	FavouritesTree.set_column_expand(MatchesTreeColumns.SCOPE, false)
	FavouritesTree.set_column_expand(MatchesTreeColumns.TYPE, false)
	FavouritesTree.set_column_expand(MatchesTreeColumns.NAME, true)
	
	RecentTree.set_column_expand(MatchesTreeColumns.SCOPE, false)
	RecentTree.set_column_expand(MatchesTreeColumns.TYPE, false)
	RecentTree.set_column_expand(MatchesTreeColumns.NAME, true)
	_populate_matches()
	_load_favourites_and_recent()


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
	if ScopeOptionsButton.selected != -1:
		_variables_for_scope = _filter_by_scope(
			_all_variables, ScopeOptionsButton.selected
		)
	else:
		_variables_for_scope = _all_variables
	if SearchEdit.text != "":
		_variables_for_search = _filter_by_search(
			_variables_for_scope,
			SearchEdit.text
		)
	else:
		_variables_for_search = _variables_for_scope
	
	_variables_for_search.sort_custom(func(a, b):
		return a['name'].naturalnocasecmp_to(b['name']) < 0
	)


func _populate_matches():
	MatchesTree.clear()
	var root = MatchesTree.create_item()
	for v in _variables_for_search:
		var item = root.create_child()
		item.set_cell_mode(MatchesTreeColumns.SCOPE, TreeItem.CELL_MODE_ICON)
		item.set_icon(MatchesTreeColumns.SCOPE, _icon_for_scope(v['scope']))
		item.set_tooltip_text(
			MatchesTreeColumns.SCOPE,
			_tooltip_for_scope(v['scope'])
		)
		item.set_cell_mode(MatchesTreeColumns.TYPE, TreeItem.CELL_MODE_ICON)
		item.set_icon(MatchesTreeColumns.TYPE, _icon_for_type(v['type']))
		item.set_tooltip_text(
			MatchesTreeColumns.TYPE,
			_tooltip_for_type(v['type'])
		)
		item.set_text(MatchesTreeColumns.NAME, v['name'])
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
	FavouritesTree.clear()
	FavouritesTree.create_item()
	RecentTree.clear()
	RecentTree.create_item()
	if state != null:
		_populate_sidebar(FavouritesTree, state.favourites)
		_populate_sidebar(RecentTree, state.recent)


func _populate_sidebar(sidebar, items):
	for item in items:
		var v = _get_match_by_name(item)
		if v == null:
			continue
		_add_to_sidebar(sidebar, v)


func _add_to_sidebar(sidebar, v, index=-1):
	var root = sidebar.get_root()
	var item = root.create_child(index)
	item.set_cell_mode(MatchesTreeColumns.SCOPE, TreeItem.CELL_MODE_ICON)
	item.set_icon(MatchesTreeColumns.SCOPE, _icon_for_scope(v['scope']))
	item.set_tooltip_text(
		MatchesTreeColumns.SCOPE,
		_tooltip_for_scope(v['scope'])
	)
	item.set_cell_mode(MatchesTreeColumns.TYPE, TreeItem.CELL_MODE_ICON)
	item.set_icon(MatchesTreeColumns.TYPE, _icon_for_type(v['type']))
	item.set_tooltip_text(
		MatchesTreeColumns.TYPE,
		_tooltip_for_type(v['type'])
	)
	item.set_text(MatchesTreeColumns.NAME, v['name'])
	item.set_tooltip_text(
		MatchesTreeColumns.NAME,
		"Variable Name"
	)


func _perform_search_and_refresh():
	_perform_search()
	_populate_matches()


func _tooltip_for_scope(scope):
	match scope:
		VariableScope.SCOPE_DIALOGUE:
			return "Transient"
		VariableScope.SCOPE_SCENE:
			return "Local"
		VariableScope.SCOPE_GLOBAL:
			return "Global"
	return null


func _icon_for_scope(scope):
	match scope:
		VariableScope.SCOPE_DIALOGUE:
			return TransientIcon
		VariableScope.SCOPE_SCENE:
			return LocalIcon
		VariableScope.SCOPE_GLOBAL:
			return GlobalIcon
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
			return BoolIcon
		VariableType.TYPE_FLOAT:
			return FloatIcon
		VariableType.TYPE_INT:
			return IntIcon
		VariableType.TYPE_STRING:
			return StringIcon
	return null


func _on_scope_option_button_item_selected(index):
	_perform_search_and_refresh()
	_set_description_for_selection()


func _on_search_edit_text_changed(new_text):
	_perform_search_and_refresh()
	_set_description_for_selection()


func _on_clear_scope_button_pressed():
	ScopeOptionsButton.select(-1)
	_perform_search_and_refresh()
	_set_description_for_selection()


func _get_match_by_name(name):
	# Is this appropriate? Are we not going to allow the same name
	# for different scopes, for example?
	for v in _variables_for_search:
		if v['name'] == name:
			return v
	return null


func _on_matches_tree_item_selected():
	_set_description_for_selection()


func _set_description_for_selection():
	var selected = MatchesTree.get_selected()
	if selected == null:
		DescriptionLabel.text = ""
		return
	var selected_variable = _get_match_by_name(
		selected.get_text(MatchesTreeColumns.NAME)
	)
	if selected_variable == null:
		DescriptionLabel.text = ""
	else:
		DescriptionLabel.text = selected_variable.get('description')


func _on_matches_tree_nothing_selected():
	_set_description_for_selection()


func _on_matches_tree_item_activated():
	_on_select_button_pressed()


func _on_cancel_button_pressed():
	cancelled.emit()


func _on_select_button_pressed():
	var selection = MatchesTree.get_selected()
	
	if selection == null:
		var alert = AcceptDialog.new()
		alert.get_label().text = "No variable is selected."
		get_tree().root.add_child(alert)
		alert.popup_centered()
		await alert.confirmed
		get_tree().root.remove_child(alert)
		alert.queue_free()
		return
	
	var variable_name = selection.get_text(MatchesTreeColumns.NAME)
	var variable = _get_match_by_name(
		variable_name
	)
	_save_to_recent(variable_name)
	selected.emit(variable)


func _on_favourite_button_pressed():
	var selection = MatchesTree.get_selected()
	if selection == null:
		return
	var selection_name = selection.get_text(MatchesTreeColumns.NAME)
	var existing_state = _load_state()
	if existing_state == null:
		existing_state = VariableSelectDialogState.new()
	if selection_name in existing_state.favourites:
		return
	existing_state.favourites.insert(0, selection_name)
	_save_state(
		existing_state.favourites,
		existing_state.recent
	)
	# Add to favourites sidebar
	var v = _get_match_by_name(selection_name)
	_add_to_sidebar(FavouritesTree, v, 0)


class VariableSelectDialogState:
	var favourites: Array[String]
	var recent: Array[String]


func _save_to_recent(variable_name):
	var existing_state = _load_state()
	if existing_state == null:
		existing_state = VariableSelectDialogState.new()
	if variable_name in existing_state.recent:
		existing_state.recent.remove_at(
			existing_state.recent.find(variable_name)
		)
	existing_state.recent.insert(0, variable_name)
	_save_state(
		existing_state.favourites,
		existing_state.recent
	)


func _load_state() -> VariableSelectDialogState:
	var config = ConfigFile.new()
	var err = config.load(
		"res://.godot/hyh.cutscene_graph/variable_select_dialog.cfg"
	)
	if err != OK:
		return null
	
	var state = VariableSelectDialogState.new()
	state.favourites = config.get_value('state', 'favourites', [])
	state.recent = config.get_value('state', 'recent', [])
	return state


func _save_state(favourites: Array[String], recent: Array[String]):
	var config = ConfigFile.new()
	config.set_value('state', 'favourites', favourites)
	config.set_value('state', 'recent', recent)
	Logger.debug("About to save variable select dialog state")
	var dir = DirAccess.open("res://.godot")
	var dir_status = dir.make_dir("hyh.cutscene_graph")
	Logger.debug("Directory create status: %s" % dir_status)
	var status = config.save("res://.godot/hyh.cutscene_graph/variable_select_dialog.cfg")
	Logger.debug("File save status: %s" % status)


func _on_favourites_tree_item_selected():
	_highlight_sidebar_selection(FavouritesTree)


func _on_recent_tree_item_selected():
	_highlight_sidebar_selection(RecentTree)


func _highlight_sidebar_selection(sidebar: Tree):
	var selection = sidebar.get_selected()
	if selection == null:
		return
	var selected_name = selection.get_text(MatchesTreeColumns.NAME)
	SearchEdit.text = selected_name
	ScopeOptionsButton.select(-1)
	_perform_search_and_refresh()
	var matches_root = MatchesTree.get_root()
	for row in matches_root.get_children():
		if row.get_text(MatchesTreeColumns.NAME) == selected_name:
			MatchesTree.set_selected(row, MatchesTreeColumns.NAME)
			break

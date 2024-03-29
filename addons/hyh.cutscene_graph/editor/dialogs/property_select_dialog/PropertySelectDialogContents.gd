@tool
extends MarginContainer
## Property select dialog contents.


signal selected(property)
signal cancelled()

enum MatchesTreeColumns {
	TYPE,
	NAME,
	DESCRIPTION,
}

const Logging = preload("../../../utility/Logging.gd")
const BOOL_ICON = preload("../../../icons/icon_type_bool.svg")
const INT_ICON = preload("../../../icons/icon_type_int.svg")
const FLOAT_ICON = preload("../../../icons/icon_type_float.svg")
const STRING_ICON = preload("../../../icons/icon_type_string.svg")
const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const PropertyUse = preload("./PropertySelectDialog.gd").PropertyUse

var _logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)
var _use_restriction: PropertyUse
var _all_properties := []
var _properties_for_search := []

@onready var _favourites_tree: Tree = $VB/BodyContainer/FavouritesPane/HB/FavouritesTree
@onready var _recent_tree: Tree = $VB/BodyContainer/FavouritesPane/HB/RecentTree
@onready var _search_edit: LineEdit = $VB/BodyContainer/SearchPane/VB/SearchContainer/SearchEdit
@onready var _matches_tree: Tree = $VB/BodyContainer/SearchPane/VB/MatchesTree
@onready var _description_label: RichTextLabel = $VB/BodyContainer/SearchPane/VB/DescriptionLabel


func _ready() -> void:
	_use_restriction = get_parent().use_restriction
	_all_properties = _filter_by_use_restriction(
		ProjectSettings.get_setting(
			"cutscene_graph_editor/property_definitions",
			[]
		)
	)
	_perform_search()
	_matches_tree.set_column_expand(MatchesTreeColumns.TYPE, false)
	_matches_tree.set_column_expand(MatchesTreeColumns.NAME, true)
	_matches_tree.set_column_expand(MatchesTreeColumns.DESCRIPTION, true)
	
	_favourites_tree.set_column_expand(MatchesTreeColumns.TYPE, false)
	_favourites_tree.set_column_expand(MatchesTreeColumns.NAME, true)
	
	_recent_tree.set_column_expand(MatchesTreeColumns.TYPE, false)
	_recent_tree.set_column_expand(MatchesTreeColumns.NAME, true)
	_populate_matches()
	_load_favourites_and_recent()


func _filter_by_use_restriction(props):
	if _use_restriction == null:
		return props
	var filtered = []
	for p in props:
		if _get_use_restriction_string() in p['uses']:
			filtered.append(p)
	return filtered


func _get_use_restriction_string() -> String:
	match _use_restriction:
		PropertyUse.CHARACTERS:
			return 'characters'
		PropertyUse.SCENES:
			return 'scenes'
		PropertyUse.CHOICES:
			return 'choices'
		PropertyUse.DIALOGUE:
			return 'dialogue'
		PropertyUse.VARIANTS:
			return 'variants'
	return ''


func _perform_search():
	if _search_edit.text != "":
		_properties_for_search = _filter_by_search(
			_all_properties,
			_search_edit.text
		)
	else:
		_properties_for_search = _all_properties
	
	_properties_for_search.sort_custom(func(a, b):
		return a['name'].naturalnocasecmp_to(b['name']) < 0
	)


func _filter_by_search(props, search):
	var filtered = []
	var lc_search = search.to_lower()
	for p in props:
		if p['name'].to_lower().contains(lc_search):
			filtered.append(p)
			continue
		if p['description'].to_lower().contains(lc_search):
			filtered.append(p)
			continue
	return filtered


func _populate_matches():
	_matches_tree.clear()
	var root = _matches_tree.create_item()
	for p in _properties_for_search:
		var item = root.create_child()
		item.set_cell_mode(MatchesTreeColumns.TYPE, TreeItem.CELL_MODE_ICON)
		item.set_icon(MatchesTreeColumns.TYPE, _icon_for_type(p['type']))
		item.set_tooltip_text(
			MatchesTreeColumns.TYPE,
			_tooltip_for_type(p['type'])
		)
		item.set_text(MatchesTreeColumns.NAME, p['name'])
		item.set_tooltip_text(
			MatchesTreeColumns.NAME,
			"Property Name"
		)
		item.set_text(MatchesTreeColumns.DESCRIPTION, p['description'])
		item.set_tooltip_text(
			MatchesTreeColumns.DESCRIPTION,
			"Property Description"
		)


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
		var p = _get_match_by_name(item)
		if p == null:
			continue
		if not _use_restriction in p['uses']:
			continue
		_add_to_sidebar(sidebar, p)


func _get_match_by_name(name):
	# Is this appropriate? Are we not going to allow the same name
	# for different scopes, for example?
	for p in _properties_for_search:
		if p['name'] == name:
			return p
	return null


func _add_to_sidebar(sidebar, p, index=-1):
	var root = sidebar.get_root()
	var item = root.create_child(index)
	item.set_cell_mode(MatchesTreeColumns.TYPE, TreeItem.CELL_MODE_ICON)
	item.set_icon(MatchesTreeColumns.TYPE, _icon_for_type(p['type']))
	item.set_tooltip_text(
		MatchesTreeColumns.TYPE,
		_tooltip_for_type(p['type'])
	)
	item.set_text(MatchesTreeColumns.NAME, p['name'])
	item.set_tooltip_text(
		MatchesTreeColumns.NAME,
		"Property Name"
	)


func _set_description_for_selection():
	var selected = _matches_tree.get_selected()
	if selected == null:
		_description_label.text = ""
		return
	var selected_property = _get_match_by_name(
		selected.get_text(MatchesTreeColumns.NAME)
	)
	if selected_property == null:
		_description_label.text = ""
	else:
		_description_label.text = selected_property.get('description')


func _save_to_recent(property_name):
	var existing_state = _load_state()
	if existing_state == null:
		existing_state = PropertySelectDialogState.new()
	if property_name in existing_state.recent:
		existing_state.recent.remove_at(
			existing_state.recent.find(property_name)
		)
	existing_state.recent.insert(0, property_name)
	_save_state(
		existing_state.favourites,
		existing_state.recent
	)


func _load_state() -> PropertySelectDialogState:
	var config = ConfigFile.new()
	var err = config.load(
		"res://.godot/hyh.cutscene_graph/property_select_dialog.cfg"
	)
	if err != OK:
		return null
	
	var state = PropertySelectDialogState.new()
	state.favourites = config.get_value('state', 'favourites', [])
	state.recent = config.get_value('state', 'recent', [])
	return state


func _save_state(favourites: Array[String], recent: Array[String]):
	var config = ConfigFile.new()
	config.set_value('state', 'favourites', favourites)
	config.set_value('state', 'recent', recent)
	_logger.debug("About to save property select dialog state")
	var dir = DirAccess.open("res://.godot")
	var dir_status = dir.make_dir("hyh.cutscene_graph")
	_logger.debug("Directory create status: %s" % dir_status)
	var status = config.save("res://.godot/hyh.cutscene_graph/property_select_dialog.cfg")
	_logger.debug("File save status: %s" % status)


func _highlight_sidebar_selection(sidebar: Tree):
	var selection = sidebar.get_selected()
	if selection == null:
		return
	var selected_name = selection.get_text(MatchesTreeColumns.NAME)
	_search_edit.text = selected_name
	_perform_search_and_refresh()
	var matches_root = _matches_tree.get_root()
	for row in matches_root.get_children():
		if row.get_text(MatchesTreeColumns.NAME) == selected_name:
			_matches_tree.set_selected(row, MatchesTreeColumns.NAME)
			break


func _perform_search_and_refresh():
	_perform_search()
	_populate_matches()


func _on_favourites_tree_item_selected():
	_highlight_sidebar_selection(_favourites_tree)


func _on_recent_tree_item_selected():
	_highlight_sidebar_selection(_recent_tree)


func _on_search_edit_text_changed(new_text):
	_perform_search_and_refresh()
	_set_description_for_selection()


func _on_favourite_button_pressed():
	var selection = _matches_tree.get_selected()
	if selection == null:
		return
	var selection_name = selection.get_text(MatchesTreeColumns.NAME)
	var existing_state = _load_state()
	if existing_state == null:
		existing_state = PropertySelectDialogState.new()
	if selection_name in existing_state.favourites:
		return
	existing_state.favourites.insert(0, selection_name)
	_save_state(
		existing_state.favourites,
		existing_state.recent
	)
	# Add to favourites sidebar
	var p = _get_match_by_name(selection_name)
	_add_to_sidebar(_favourites_tree, p, 0)


func _on_matches_tree_item_activated():
	_on_select_button_pressed()


func _on_matches_tree_item_selected():
	_set_description_for_selection()


func _on_matches_tree_nothing_selected():
	_set_description_for_selection()


func _on_cancel_button_pressed():
	cancelled.emit()


func _on_select_button_pressed():
	var selection = _matches_tree.get_selected()
	
	if selection == null:
		var alert = AcceptDialog.new()
		alert.get_label().text = "No property is selected."
		get_tree().root.add_child(alert)
		alert.popup_centered()
		await alert.confirmed
		get_tree().root.remove_child(alert)
		alert.queue_free()
		return
	
	var property_name = selection.get_text(MatchesTreeColumns.NAME)
	var property = _get_match_by_name(
		property_name
	)
	_save_to_recent(property_name)
	selected.emit(property)


class PropertySelectDialogState:
	var favourites: Array[String]
	var recent: Array[String]

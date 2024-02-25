@tool
extends MarginContainer


const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


const WARNING_ICON = preload("../../icons/icon_node_warning.svg")
const NEW_PROPERTY_NAME = "new_property"


const VariableType = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableType


@onready var PropertyDefinitionsTree := $VB/HS/PropertyDefinitionsPane/VB/PropertyDefinitionsTree
@onready var DetailPaneContainer := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer
@onready var NameEdit := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer/VB/GC/NameEdit
@onready var TypeOption := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer/VB/GC/TypeOption
@onready var DescriptionTextEdit := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer/VB/GC/DescriptionTextEdit
@onready var ScenesCheckBox := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer/VB/GC/UsesContainer/ScenesCheckBox
@onready var CharactersCheckBox := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer/VB/GC/UsesContainer/CharactersCheckBox
@onready var VariantsCheckBox := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer/VB/GC/UsesContainer/VariantsCheckBox
@onready var ChoicesCheckBox := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer/VB/GC/UsesContainer/ChoicesCheckBox
@onready var DialogueCheckBox := $VB/HS/DetailPane/DetailPaneContents/DetailPaneContainer/VB/GC/UsesContainer/DialogueCheckBox
@onready var RemoveButton := $VB/HS/PropertyDefinitionsPane/VB/HeaderButtonsContainer/RemoveButton


enum PropertyDefinitionTreeColumns {
	NAME,
	TYPE,
	DESCRIPTION,
}


enum PropertyDefinitionEditPopupMenuItem {
	REMOVE,
}


signal closing()


var _definitions
var _edited_item
var _edited_definition
var _populating := false
var _default_name_regex: RegEx


func _ready() -> void:
	_definitions = ProjectSettings.get_setting(
		"cutscene_graph_editor/property_definitions",
		[]
	).duplicate(true)
	
	var property_definitions_root = PropertyDefinitionsTree.create_item()
	PropertyDefinitionsTree.set_column_title(
		PropertyDefinitionTreeColumns.NAME,
		"Name",
	)
	PropertyDefinitionsTree.set_column_expand(
		PropertyDefinitionTreeColumns.NAME,
		true,
	)
	PropertyDefinitionsTree.set_column_title(
		PropertyDefinitionTreeColumns.TYPE,
		"Type",
	)
	PropertyDefinitionsTree.set_column_expand(
		PropertyDefinitionTreeColumns.TYPE,
		true,
	)
	PropertyDefinitionsTree.set_column_title(
		PropertyDefinitionTreeColumns.DESCRIPTION,
		"Description",
	)
	PropertyDefinitionsTree.set_column_expand(
		PropertyDefinitionTreeColumns.DESCRIPTION,
		true
	)

	for d in _definitions:
		var item: TreeItem = PropertyDefinitionsTree.create_item(property_definitions_root)
		_populate_item_for_definition(item, d)
	
	_hide_detail_pane()
	
	_default_name_regex = RegEx.new()
	_default_name_regex.compile(r'%s_([\d]+)' % NEW_PROPERTY_NAME)


func _populate_item_for_definition(item: TreeItem, definition) -> void:
	item.set_text(
		PropertyDefinitionTreeColumns.NAME,
		definition['name'],
	)
	item.set_editable(
		PropertyDefinitionTreeColumns.NAME,
		false,
	)
	item.set_text(
		PropertyDefinitionTreeColumns.TYPE,
		_get_type_name(
			definition['type'],
		),
	)
	item.set_editable(
		PropertyDefinitionTreeColumns.TYPE,
		false,
	)
	item.set_icon(
		PropertyDefinitionTreeColumns.TYPE,
		_get_type_icon(
			definition['type'],
		),
	)
	item.set_text(
		PropertyDefinitionTreeColumns.DESCRIPTION,
		definition['description'],
	)
	item.set_editable(
		PropertyDefinitionTreeColumns.DESCRIPTION,
		false,
	)
	item.set_meta('definition', definition)


func _get_type_name(type: VariableType) -> String:
	match type:
		VariableType.TYPE_BOOL:
			return "Boolean"
		VariableType.TYPE_FLOAT:
			return "Float"
		VariableType.TYPE_INT:
			return "Integer"
		VariableType.TYPE_STRING:
			return "String"
	return "Unknown"


func _get_type_icon(type: VariableType) -> Texture:
	match type:
		VariableType.TYPE_BOOL:
			return preload("res://addons/hyh.cutscene_graph/icons/icon_type_bool.svg")
		VariableType.TYPE_FLOAT:
			return preload("res://addons/hyh.cutscene_graph/icons/icon_type_float.svg")
		VariableType.TYPE_INT:
			return preload("res://addons/hyh.cutscene_graph/icons/icon_type_int.svg")
		VariableType.TYPE_STRING:
			return preload("res://addons/hyh.cutscene_graph/icons/icon_type_string.svg")
	# TODO: Shouldn't ever be needed, but a more appropriate icon should
	# be used here.
	return preload("res://addons/hyh.cutscene_graph/icons/icon_file.svg")


func configure() -> void:
	pass


func _set_button_states(item_selected: bool) -> void:
	RemoveButton.disabled = not item_selected


func _show_detail_pane() -> void:
	DetailPaneContainer.visible = true


func _hide_detail_pane() -> void:
	DetailPaneContainer.visible = false


func _on_cancel_button_pressed():
	closing.emit()


func _on_save_button_pressed():
	if not _validate():
		_perform_save()
		closing.emit()
	else:
		var dialog = AcceptDialog.new()
		dialog.title = "Validation Failed"
		dialog.dialog_text = """There are invalid property definitions.\n
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
	Logger.debug("Validation failed dialog closed.")
	dialog.confirmed.disconnect(_validation_failed_dialog_closed)
	dialog.close_requested.disconnect(_validation_failed_dialog_closed)
	dialog.queue_free()


func _perform_save():
	var root = PropertyDefinitionsTree.get_root()
	ProjectSettings.set_setting(
		"cutscene_graph_editor/property_definitions",
		_definitions,
	)
	ProjectSettings.save()


func _clear_validation_warnings() -> void:
	var root = PropertyDefinitionsTree.get_root()
	
	for gt in root.get_children():
		gt.set_icon(
			PropertyDefinitionTreeColumns.NAME,
			null
		)
		gt.set_tooltip_text(
			PropertyDefinitionTreeColumns.NAME,
			""
		)


func _set_validation_warning(gt: TreeItem, warning: String) -> void:
	gt.set_icon(
		PropertyDefinitionTreeColumns.NAME,
		WARNING_ICON
	)
	gt.set_tooltip_text(
		PropertyDefinitionTreeColumns.NAME,
		warning
	)


func _validate() -> bool:
	var issues = false
	var all_names = {}
	var no_uses = []
	var root: TreeItem = PropertyDefinitionsTree.get_root()
	
	_clear_validation_warnings()
	
	for d in _definitions:
		var name = d['name']
		if name in all_names.keys():
			all_names[name] += 1
		else:
			all_names[name] = 1
		if len(d['uses']) == 0:
			no_uses.append(d)
	
	for name in all_names.keys():
		if all_names[name] > 1:
			issues = true
			for gt in root.get_children():
				if gt.get_text(PropertyDefinitionTreeColumns.NAME) == name:
					_set_validation_warning(gt, "Duplicate name")
	
	for d in no_uses:
		issues = true
		for gt in root.get_children():
			if gt.get_meta('definition') == d:
				if gt.get_icon(PropertyDefinitionTreeColumns.NAME) == null:
					_set_validation_warning(gt, "No uses set")
	
	return issues


func _on_popup_menu_id_pressed(id):
	if id == PropertyDefinitionEditPopupMenuItem.REMOVE:
		_remove_selected()
		_validate()


func _on_remove_button_pressed():
	_remove_selected()
	_validate()


func _remove_selected() -> void:
	var selected = PropertyDefinitionsTree.get_selected()
	if selected == null:
		return
	var definition = selected.get_meta('definition')
	selected.free()
	_definitions.remove_at(
		_definitions.find(definition)
	)
	_edited_definition = null
	_edited_item = null
	_set_button_states(false)
	_hide_detail_pane()


func _on_add_button_pressed():
	var property_definitions_root: TreeItem = PropertyDefinitionsTree.get_root()
	var item: TreeItem = PropertyDefinitionsTree.create_item(property_definitions_root)
	var definition := {
		'name': _get_default_property_name(),
		'type': VariableType.TYPE_BOOL,
		'description': "",
		'uses': [
			'scenes',
			'characters',
			'variants',
			'choices',
			'dialogue',
		],
	}
	_definitions.append(definition)
	_populate_item_for_definition(item, definition)
	PropertyDefinitionsTree.set_selected(
		item,
		PropertyDefinitionTreeColumns.NAME
	)
	PropertyDefinitionsTree.edit_selected()
	_validate()


func _get_default_property_name():
	var existing := _get_default_name_count()
	if existing == 0:
		return NEW_PROPERTY_NAME
	return "%s_%s" % [
		NEW_PROPERTY_NAME,
		existing
	]


func _get_default_name_count() -> int:
	var count := 0
	for d in _definitions:
		var name: String = d['name']
		if name.begins_with(NEW_PROPERTY_NAME):
			count += 1
			var matches := _default_name_regex.search(name)
			if matches != null:
				if matches.strings[1].is_valid_int():
					var ord: int = matches.strings[1].to_int()
					if ord >= count:
						count = ord + 1
	return count


func _on_property_definitions_tree_item_mouse_selected(position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		# Adding a little offset seems to be required to prevent an item
		# from being immediately chosen.
		$PopupMenu.position = Vector2(
			self.get_parent().position
		) + position + Vector2(20, 10)
		$PopupMenu.popup()


func _on_property_definitions_tree_item_selected():
	_set_button_states(true)
	_show_detail_pane()
	var item: TreeItem = PropertyDefinitionsTree.get_selected()
	_configure_detail_pane_for_item(
		item
	)


func _configure_detail_pane_for_item(item: TreeItem) -> void:
	_edited_item = item
	var name := item.get_text(PropertyDefinitionTreeColumns.NAME)
	_edited_definition = item.get_meta('definition') # _get_definition_by_name(name)
	_populate_detail_pane_for_definition(_edited_definition)


func _get_definition_by_name(name: String) -> Dictionary:
	var found := {}
	for d: Dictionary in _definitions:
		if d['name'] == name:
			found = d
			break
	return found


func _populate_detail_pane_for_definition(definition: Dictionary) -> void:
	_populating = true
	NameEdit.text = definition['name']
	DescriptionTextEdit.text = definition['description']
	TypeOption.select(TypeOption.get_item_index(definition['type']))
	ScenesCheckBox.button_pressed = 'scenes' in definition['uses']
	CharactersCheckBox.button_pressed = 'characters' in definition['uses']
	VariantsCheckBox.button_pressed = 'variants' in definition['uses']
	ChoicesCheckBox.button_pressed = 'choices' in definition['uses']
	DialogueCheckBox.button_pressed = 'dialogue' in definition['uses']
	_populating = false


func _update_edited() -> void:
	_edited_definition['name'] = NameEdit.text
	_edited_definition['description'] = DescriptionTextEdit.text
	_edited_definition['type'] = TypeOption.get_selected_id()
	var uses: Array = _edited_definition['uses']
	_update_uses_for_checkbox(uses, ScenesCheckBox, 'scenes')
	_update_uses_for_checkbox(uses, CharactersCheckBox, 'characters')
	_update_uses_for_checkbox(uses, VariantsCheckBox, 'variants')
	_update_uses_for_checkbox(uses, ChoicesCheckBox, 'choices')
	_update_uses_for_checkbox(uses, DialogueCheckBox, 'dialogue')
	_edited_item.set_text(
		PropertyDefinitionTreeColumns.NAME,
		_edited_definition['name'],
	)
	_edited_item.set_text(
		PropertyDefinitionTreeColumns.DESCRIPTION,
		_edited_definition['description'],
	)
	_edited_item.set_text(
		PropertyDefinitionTreeColumns.TYPE,
		_get_type_name(
			_edited_definition['type'],
		),
	)
	_edited_item.set_icon(
		PropertyDefinitionTreeColumns.TYPE,
		_get_type_icon(
			_edited_definition['type'],
		),
	)
	_validate()


func _update_uses_for_checkbox(uses: Array, cb: CheckBox, value: String) -> void:
	if cb.button_pressed:
		if not value in uses:
			uses.append(value)
	else: 
		if value in uses:
			uses.remove_at(uses.find(value))


func _on_property_definitions_tree_nothing_selected():
	_set_button_states(false)
	_hide_detail_pane()


func _on_name_edit_text_changed(new_text):
	if _populating:
		return
	_update_edited()


func _on_type_option_item_selected(index):
	if _populating:
		return
	_update_edited()


func _on_description_text_edit_text_changed():
	if _populating:
		return
	_update_edited()


func _on_uses_check_box_toggled(toggled_on):
	if _populating:
		return
	_update_edited()

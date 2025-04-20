@tool
extends VBoxContainer


signal modified()


const DialogueTextNode = preload("res://addons/hyh.digression/resources/graph/DialogueTextNode.gd")
const DialogueText = preload("res://addons/hyh.digression/resources/graph/DialogueText.gd")
const DialogueTextSection = preload("res://addons/hyh.digression/editor/text/DialogueTextSection.gd")
const DialogueTextSectionScene = preload("res://addons/hyh.digression/editor/text/DialogueTextSection.tscn")
const SettingsHelper = preload("res://addons/hyh.digression/editor/helpers/SettingsHelper.gd")


var node_resource: DialogueTextNode


@onready var _character_select := $CharacterOptionsContainer/CharacterSelect
@onready var _character_options_container: GridContainer = $CharacterOptionsContainer
@onready var _sections_container := $SectionsContainer
@onready var _character_options_separator := $DragTargetHSeparator


var _characters: Array
var _dialogue_types: Array
var _dialogue_types_by_id: Dictionary
var _dialogue_type_option: OptionButton
var _titlebar: HBoxContainer


func _init():
	_dialogue_type_option = OptionButton.new()
	_dialogue_type_option.item_selected.connect(_on_dialogue_type_option_item_selected)
	_dialogue_type_option.flat = true
	_dialogue_type_option.fit_to_longest_item = true
	_dialogue_type_option.theme_type_variation = "DialogueNodeTitlebarOption"
	_dialogue_types = SettingsHelper.get_dialogue_types()
	_dialogue_types_by_id = {}
	_dialogue_type_option.clear()
	_dialogue_type_option.add_item("Select Type...", 0)
	var next_id = 1
	for t in _dialogue_types:
		_dialogue_types_by_id[next_id] = t
		_dialogue_type_option.add_item(
			t["name"].capitalize(),
			next_id,
		)
		next_id += 1


func _ready() -> void:
	_clear_sections_container()


func configure_for_node(
	graph: DigressionDialogueGraph,
	resource_node: DialogueTextNode
) -> void:
	_characters = graph.characters
	node_resource = resource_node
	_populate_characters(_characters)
	_select_character(node_resource.character)
	_select_dialogue_type(node_resource.dialogue_type)
	_configure_text_sections_for_node(graph, node_resource)


func configure_titlebar(titlebar: HBoxContainer) -> void:
	_titlebar = titlebar
	var label: Label = titlebar.get_child(0) as Label
	label.text = ""
	titlebar.add_child(_dialogue_type_option)
	titlebar.move_child(_dialogue_type_option, 0)


func cleanup() -> void:
	_titlebar.remove_child(_dialogue_type_option)
	_dialogue_type_option.queue_free()
	_clear_sections_container()


func set_characters(characters: Array) -> void:
	_characters = characters


func _clear_sections_container() -> void:
	if _sections_container.get_child_count() > 0:
		for child in _sections_container.get_children():
			_sections_container.remove_child(child)
			child.queue_free()


## Select the dialogue type.
func _select_dialogue_type(name):
	var t = _get_dialogue_type_by_name(name)
	_configure_for_dialogue_type(t)
	if t == null:
		_dialogue_type_option.select(
			_dialogue_type_option.get_item_index(0)
		)
	else:
		_dialogue_type_option.select(
			_dialogue_type_option.get_item_index(
				_get_id_for_dialogue_type(t)
			)
		)


## Select the specified character.
func _select_character(character):
	# This will be used when displaying a graph initially.
	var character_select := _character_select
	if not character:
		character_select.select(-1)
		_populate_variants(null)
		return
	for index in range(0, _characters.size()):
		var c = _characters[index]
		if c == character:
			character_select.select(index)
			_populate_variants(_characters[index].character_variants)


func _populate_characters(characters):
	var character_select = _character_select
	_characters = characters
	var selected = character_select.selected
	character_select.clear()
	for character in characters:
		character_select.add_item(character.character_display_name)
	# TODO: What happens here if previously selected index is out of range?
	# Should determine name of selection beforehand and be sure to reselect that character, or null
	# selection if gone
	character_select.select(selected)
	if character_select.selected != -1:
		_populate_variants(_characters[character_select.selected].character_variants)


func _populate_variants(variants):
	for section in _sections_container.get_children():
		section.populate_variants(variants)


func _get_variants_for_selected_character():
	if not node_resource.character:
		return null
	return node_resource.character.character_variants


func _configure_text_sections_for_node(g, n):
	# Clear out any existing section controls
	for c in _sections_container.get_children():
		_sections_container.remove_child(c)
	# Repopulate
	for section in n.sections:
		var control := DialogueTextSectionScene.instantiate()
		_sections_container.add_child(control)
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
		control.configure_for_section(
			g,
			section,
			_dialogue_type_involves_character(),
			_get_variants_for_selected_character()
		)
		_connect_signals_for_section(control)
	
	_configure_text_sections_for_child_count()


func _configure_text_sections_for_child_count():
	for section in _sections_container.get_children():
		section.configure_for_sibling_count(
			_sections_container.get_child_count() - 1
		)


func _dialogue_type_involves_character():
	var t = _get_dialogue_type_by_name(node_resource.dialogue_type)
	if t:
		return t['involves_character']
	# I think this is the appropriate default?
	return true


func _get_dialogue_type_by_name(name):
	for t in _dialogue_types:
		if t['name'] == name:
			return t
	return null


func _get_id_for_dialogue_type(type):
	return _dialogue_types_by_id.find_key(type)


func _configure_for_dialogue_type(dialogue_type):
	if dialogue_type == null:
		return
	var involves_character = dialogue_type["involves_character"]
	if involves_character:
		if not _character_options_container.visible:
			_character_options_container.show()
			_character_options_separator.show()
	else:
		if _character_options_container.visible:
			var character_options_height = _character_options_container.size.y
			var separator_height = _character_options_separator.size.y
			_character_options_container.hide()
			_character_options_separator.hide()
	for section in _sections_container.get_children():
		section.configure_for_dialogue_type(involves_character, false)


## Persist changes from the editor node's controls into the graph node's properties
func _persist_changes_to_node():
	node_resource.dialogue_type = _get_dialogue_type()
	var selected_c = _get_selected_character()
	if selected_c != -1:
		node_resource.character = _characters[selected_c]
	else:
		node_resource.character = null
	for section in _sections_container.get_children():
		section.persist_changes_to_resource()


## Get the selected dialogue type.
func _get_dialogue_type():
	var t = _dialogue_types_by_id.get(
		_dialogue_type_option.get_selected_id()
	)
	if t != null:
		return t['name']
	return ""


## Get the selected character.
func _get_selected_character():
	return _character_select.selected


func _move_dropped_section_to_index(dropped_section, index):
	if dropped_section.get_parent() == _sections_container:
		if dropped_section.get_index() < index:
			index = index - 1
		if dropped_section.get_index() == index:
			return
		_move_section_to_position(
			dropped_section,
			index
		)
	else:
		# This indicates a drag from a different node.
		dropped_section.prepare_to_change_parent()
		_add_section_at_position(
			dropped_section,
			index
		)
		# TODO: We may also need to re-evaluate the variants of the section here.
	# TODO: Need to do something about changing the node sizing
	#_correct_size()
	_configure_text_sections_for_child_count()
	modified.emit()


func _add_section_at_position(section, index):
	var size_diff = section.size.y
	_sections_container.add_child(section)
	_sections_container.move_child(section, index)
	node_resource.sections.insert(
		index,
		section.section_resource
	)
	section.populate_variants(_get_variants_for_selected_character())
	_connect_signals_for_section(section)


func _move_section_to_position(section, index):
	var current_index = section.get_index()
	_sections_container.move_child(section, index)
	node_resource.sections.insert(
		index,
		node_resource.sections.pop_at(current_index)
	)


func _remove_section(section):
	node_resource.remove_section(section.section_resource)
	var size_diff = section.size.y
	_sections_container.remove_child(section)
	section.queue_free()
	_configure_text_sections_for_child_count()


func _connect_signals_for_section(section):
	section.modified.connect(_on_section_modified)
	section.removal_requested.connect(
		_on_section_removal_requested.bind(section)
	)
	section.dropped_after.connect(
		_on_section_dropped_after.bind(section)
	)
	section.preparing_to_change_parent.connect(
		_on_section_preparing_to_change_parent.bind(section)
	)


func _disconnect_signals_for_section(section):
	section.modified.disconnect(_on_section_modified)
	section.removal_requested.disconnect(
		_on_section_removal_requested
	)
	section.dropped_after.disconnect(
		_on_section_dropped_after
	)
	section.preparing_to_change_parent.disconnect(
		_on_section_preparing_to_change_parent
	)


func _show_section_removal_confirmation_dialog(section):
	var confirm = ConfirmationDialog.new()
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.title = "Please confirm"
	confirm.dialog_text = "Are you sure you want to remove this section? This action cannot be undone."
	confirm.canceled.connect(_on_action_cancelled.bind(confirm))
	confirm.confirmed.connect(_on_action_confirmed.bind(section, confirm))
	get_tree().root.add_child(confirm)
	confirm.show()


func _on_action_confirmed(section, dialog):
	get_tree().root.remove_child(dialog)
	_remove_section(section)
	_persist_changes_to_node()
	modified.emit()


func _on_action_cancelled(dialog):
	get_tree().root.remove_child(dialog)


func _on_dialogue_type_option_item_selected(index: int) -> void:
	var id = _dialogue_type_option.get_item_id(index)
	_configure_for_dialogue_type(
		_dialogue_types_by_id[id],
	)
	_persist_changes_to_node()
	modified.emit()


func _on_clear_character_button_pressed():
	_select_character(null)
	_persist_changes_to_node()
	modified.emit()


func _on_section_modified():
	_persist_changes_to_node()
	modified.emit()


func _on_section_removal_requested(section_control):
	# TODO: Maybe this could be actioned immediately if none of the fields have
	# been modified?
	_show_section_removal_confirmation_dialog(section_control)


func _on_section_dropped_after(dropped_section, target_section):
	_move_dropped_section_to_index(
		dropped_section,
		target_section.get_index() + 1
	)
	_persist_changes_to_node()
	modified.emit()


func _on_section_preparing_to_change_parent(section):
	_disconnect_signals_for_section(section)
	var size_diff = section.size.y
	_sections_container.remove_child(section)
	node_resource.sections.remove_at(
		node_resource.sections.find(
			section.section_resource
		)
	)
	_configure_text_sections_for_child_count()


func _on_translation_key_edit_text_changed(new_text):
	_persist_changes_to_node()
	modified.emit()


func _on_add_section_button_pressed() -> void:
	var editor_section := DialogueTextSectionScene.instantiate()
	var section = node_resource.add_section()
	_sections_container.add_child(editor_section)
	editor_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_section.configure_for_section(
		null,
		section,
		_dialogue_type_involves_character(),
		_get_variants_for_selected_character()
	)
	_connect_signals_for_section(editor_section)
	_configure_text_sections_for_child_count()


func _on_character_options_separator_dropped(arg: Variant, at_position: Variant) -> void:
	# This indicates that the dropped section should be moved to the top of the
	# list.
	_move_dropped_section_to_index(arg, 0)


func _on_character_select_item_selected(index: int) -> void:
	var character = _characters[index]
	_populate_variants(character.character_variants)
	modified.emit()

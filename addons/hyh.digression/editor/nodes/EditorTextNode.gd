@tool
extends "EditorGraphNodeBase.gd"
## Editor node for Dialogue resource node.


const DialogueTextSection = preload("res://addons/hyh.digression/editor/text/DialogueTextSection.tscn")
const SettingsHelper = preload("../helpers/SettingsHelper.gd")

var _characters
var _dialogue_types
var _dialogue_types_by_id
var _dialogue_type_option: OptionButton

# TODO: May not need this.
var _original_size: Vector2

@onready var _character_select := $RootContainer/VerticalLayout/CharacterOptionsContainer/CharacterSelect
@onready var _character_options_container: GridContainer = $RootContainer/VerticalLayout/CharacterOptionsContainer
@onready var _sections_container := $RootContainer/VerticalLayout/SectionsContainer
@onready var _character_options_separator := $RootContainer/VerticalLayout/DragTargetHSeparator


func _init():
	_dialogue_type_option = OptionButton.new()
	_dialogue_type_option.item_selected.connect(_on_dialogue_type_option_item_selected)
	_dialogue_type_option.flat = true
	_dialogue_type_option.fit_to_longest_item = true
	_dialogue_type_option.theme_type_variation = "DialogueNodeTitlebarOption"


func _ready():
	var titlebar = get_titlebar_hbox()
	titlebar.add_child(_dialogue_type_option)
	# By moving to index 0, the empty title label serves as a spacer.
	titlebar.move_child(_dialogue_type_option, 0)
	_dialogue_type_option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	self.size.x = SettingsHelper.get_dialogue_node_initial_width()
	super()


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	if n.size != Vector2.ZERO:
		size = n.size
	# Hmm, seems like this is not gonna work when the node is manually
	# resizable...
	_original_size = Vector2(size.x, 0.0)
	
	select_character(n.character)
	select_dialogue_type(n.dialogue_type, false)
	_configure_text_sections_for_node(g, n)


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.dialogue_type = get_dialogue_type()
	node_resource.size = self.size
	var selected_c = get_selected_character()
	if selected_c != -1:
		node_resource.character = _characters[selected_c]
	else:
		node_resource.character = null
	for section in _sections_container.get_children():
		section.persist_changes_to_resource()


## Get the selected dialogue type.
func get_dialogue_type():
	var t = _dialogue_types_by_id.get(
		_dialogue_type_option.get_selected_id()
	)
	if t != null:
		return t['name']
	return ""


## Select the dialogue type.
func select_dialogue_type(name, adjust_size=true):
	var t = _get_dialogue_type_by_name(name)
	_configure_for_dialogue_type(t, adjust_size)
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


## Set the possible dialogue types.
func set_dialogue_types(dialogue_types, defer=true):
	#if defer:
	#	call_deferred("set_dialogue_types", dialogue_types, false)
	#	return
	_logger.debug("Setting dialogue types")
	_dialogue_types = dialogue_types
	_dialogue_types_by_id = {}
	var dialogue_type_select = _dialogue_type_option
	dialogue_type_select.clear()
	dialogue_type_select.add_item("Select Type...", 0)
	var next_id = 1
	for t in _dialogue_types:
		_dialogue_types_by_id[next_id] = t
		dialogue_type_select.add_item(
			t["name"].capitalize(),
			next_id,
		)
		next_id += 1
	#set_dialogue_type(node_resource.dialogue_type)


## Get the selected character.
func get_selected_character():
	return _character_select.selected


## Populate the possible characters.
func populate_characters(characters):
	_logger.debug("Populating character select")
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


## Select the specified character.
func select_character(character):
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


func _reset_size(width: float) -> void:
	self.size = Vector2(width, 0.0)


func _configure_for_dialogue_type(dialogue_type, adjust_size):
	if dialogue_type == null:
		return
	var involves_character = dialogue_type["involves_character"]
	if involves_character:
		if not _character_options_container.visible:
			_character_options_container.show()
			_character_options_separator.show()
			if adjust_size:
				var character_options_height = _character_options_container.size.y
				var separator_height = _character_options_separator.size.y
				var adjustment = character_options_height + separator_height
				_reset_size(self.size.x)
	else:
		if _character_options_container.visible:
			var character_options_height = _character_options_container.size.y
			var separator_height = _character_options_separator.size.y
			_character_options_container.hide()
			_character_options_separator.hide()
			if adjust_size:
				var adjustment = character_options_height + separator_height
				_reset_size(self.size.x)
	for section in _sections_container.get_children():
		section.configure_for_dialogue_type(involves_character, adjust_size)


func _configure_text_sections_for_node(g, n):
	# Clear out any existing section controls
	for c in _sections_container.get_children():
		_sections_container.remove_child(c)
	# Repopulate
	for section in n.sections:
		var control := DialogueTextSection.instantiate()
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


func _get_variants_for_selected_character():
	if not node_resource.character:
		return null
	return node_resource.character.character_variants


func _populate_variants(variants):
	for section in _sections_container.get_children():
		section.populate_variants(variants)


func _remove_section(section):
	node_resource.remove_section(section.section_resource)
	var size_diff = section.size.y
	_sections_container.remove_child(section)
	section.queue_free()
	_configure_text_sections_for_child_count()
	_reset_size(self.size.x)


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
	section.resized.connect(_on_section_resized)


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
	section.resized.disconnect(_on_section_resized)


func _show_section_removal_confirmation_dialog(section):
	var confirm = ConfirmationDialog.new()
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.title = "Please confirm"
	confirm.dialog_text = "Are you sure you want to remove this section? This action cannot be undone."
	confirm.canceled.connect(_action_cancelled.bind(confirm))
	confirm.confirmed.connect(_action_confirmed.bind(section, confirm))
	get_tree().root.add_child(confirm)
	confirm.show()


func _move_section_to_position(section, index):
	var current_index = section.get_index()
	_sections_container.move_child(section, index)
	node_resource.sections.insert(
		index,
		node_resource.sections.pop_at(current_index)
	)


func _add_section_at_position(section, index):
	var size_diff = section.size.y
	_sections_container.add_child(section)
	_sections_container.move_child(section, index)
	_reset_size(self.size.x)
	node_resource.sections.insert(
		index,
		section.section_resource
	)
	section.populate_variants(_get_variants_for_selected_character())
	_connect_signals_for_section(section)


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


func _on_character_select_item_selected(ID):
	var character = _characters[ID]
	_populate_variants(character.character_variants)
	modified.emit()


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_section_modified():
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


func _on_resize_request(new_minsize):
	# Height is managed automatically, so we only accept the x component of the change.
	set_deferred("size", Vector2(new_minsize.x, 0.0))


func _on_translation_key_edit_text_changed(new_text):
	modified.emit()


func _on_dialogue_type_option_item_selected(index):
	var id = _dialogue_type_option.get_item_id(index)
	_configure_for_dialogue_type(
		_dialogue_types_by_id[id],
		true,
	)


func _on_clear_character_button_pressed():
	select_character(null)


func _on_add_section_button_pressed() -> void:
	var editor_section := DialogueTextSection.instantiate()
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
	_reset_size(self.size.x)


func _action_confirmed(section, dialog):
	get_tree().root.remove_child(dialog)
	_remove_section(section)


func _action_cancelled(dialog):
	get_tree().root.remove_child(dialog)


func _on_character_options_separator_dropped(arg: Variant, at_position: Variant) -> void:
	# This indicates that the dropped section should be moved to the top of the
	# list.
	_move_dropped_section_to_index(arg, 0)


func _on_section_preparing_to_change_parent(section):
	_disconnect_signals_for_section(section)
	var size_diff = section.size.y
	_sections_container.remove_child(section)
	node_resource.sections.remove_at(
		node_resource.sections.find(
			section.section_resource
		)
	)
	_reset_size(self.size.x)
	_configure_text_sections_for_child_count()


func _on_section_resized() -> void:
	_reset_size(self.size.x)

@tool
extends "EditorGraphNodeBase.gd"
## Editor node for managing Choice resources.


const DigressionSettings = preload("../settings/DigressionSettings.gd")
const TranslationKey = preload("../../utility/TranslationKey.gd")
const ChoiceBranch = preload("../../resources/graph/branches/ChoiceBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const DialogueMenuItems = preload("../text/EditorDialogueSection.gd").DialogueMenuItems

var _choice_type_option: OptionButton
var _choice_value_scene = preload("../branches/EditorChoiceValue.tscn")
var _characters
var _choice_types
var _choice_types_by_id
var _dialogue_types
var _dialogue_types_by_id

@onready var _dialogue := $DialogueMarginContainer/Dialogue
@onready var _character_options_container := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CharacterOptionsContainer
@onready var _dialogue_type_option := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/DialogueTypeOption
@onready var _dialogue_text_edit := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/DialogueWithTranslationBlock/DialogueTextEdit
@onready var _character_select := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CharacterOptionsContainer/CharacterSelect
@onready var _variant_select := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CharacterOptionsContainer/VariantSelect
@onready var _show_dialogue_for_default_button := $HeaderContainer/VB/HorizontalLayout/ShowDialogueForDefaultButton
@onready var _translation_key_edit := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/DialogueWithTranslationBlock/TranslationContainer/TranslationKeyEdit
@onready var _custom_properties_control := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CustomPropertiesControl
@onready var _dialogue_menu_button: MenuButton = $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/DialogueWithTranslationBlock/TranslationContainer/DialogueMenuButton


func _init():
	_choice_type_option = OptionButton.new()
	_choice_type_option.item_selected.connect(
		_on_choice_type_option_item_selected
	)
	_choice_type_option.flat = true
	_choice_type_option.fit_to_longest_item = true
	_choice_type_option.theme_type_variation = "ChoiceNodeTitlebarOption"


func _ready():
	# Choice type in the titlebar
	var titlebar = get_titlebar_hbox()
	titlebar.add_child(_choice_type_option)
	# By moving to index 0, the empty title label serves as a spacer.
	titlebar.move_child(_choice_type_option, 0)
	_choice_type_option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	# Hook up the dialogue type option.
	var popup := _dialogue_menu_button.get_popup()
	popup.id_pressed.connect(_on_dialogue_menu_id_pressed)
	
	# Guidelines for the dialogue text.
	var guidelines := DigressionSettings.get_dialogue_line_length_guidelines()
	_dialogue_text_edit.line_length_guidelines.clear()
	_dialogue_text_edit.line_length_guidelines.append_array(guidelines)
	
	self.size.x = DigressionSettings.get_choice_node_initial_width()
	super()


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	set_choices(
		n.choices
	)
	var dialogue_resource = _get_dialogue_resource(n)
	var dialogue_text_resource = _get_dialogue_text_resource(n)
	set_show_dialogue_for_default(n.show_dialogue_for_default)
	set_dialogue_text(dialogue_text_resource.text)
	set_dialogue_translation_key(dialogue_text_resource.text_translation_key)
	select_character(dialogue_resource.character)
	select_variant(dialogue_text_resource.character_variant)
	select_dialogue_type(dialogue_resource.dialogue_type, false)
	select_choice_type(n.choice_type, false)
	_populate_properties(dialogue_text_resource.custom_properties)
	if n.size != null and n.size != Vector2.ZERO:
		size = n.size


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.choices = get_choices()
	node_resource.choice_type = get_choice_type()
	node_resource.show_dialogue_for_default = get_show_dialogue_for_default()
	node_resource.size = self.size
	# Persist dialogue, choice type.
	var dialogue_resource = _get_dialogue_resource(node_resource)
	var dialogue_text_resource = _get_dialogue_text_resource(node_resource)
	dialogue_resource.dialogue_type = get_dialogue_type()
	dialogue_text_resource.text = get_dialogue_text()
	dialogue_text_resource.text_translation_key = get_dialogue_translation_key()
	var selected_c = get_selected_character()
	if selected_c != -1:
		dialogue_resource.character = _characters[selected_c]
		var selected_v = get_selected_variant()
		if selected_v != -1:
			dialogue_text_resource.character_variant = dialogue_resource.character.character_variants[selected_v]
	else:
		dialogue_resource.character = null
	dialogue_text_resource.custom_properties = _get_properties()


## Clear all branches.
func clear_choices():
	for index in range(get_child_count() - 2, 1, -1):
		remove_choice(index)


## Remove a branch by index.
func remove_choice(index):
	# This is one less than the index because the first output port is one the
	# second slot in this case, where it is usually on the first.
	removing_slot.emit(index - 1)
	var node = get_child(index)
	var height = node.size.y
	remove_child(node)
	node_resource.remove_choice(node.choice_resource)
	# This is the button slot
	set_slot(
		get_child_count() - 1,
		false,
		0,
		CONNECTOR_COLOUR,
		false,
		0,
		CONNECTOR_COLOUR
	)
	_disconnect_signals_for_choice(node)
	_reconnect_removal_signals()
	# This should restore the control to the minimum required for the remaining
	# choices, but a bit more than strictly necessary horizontally.
	size = Vector2(size.x, size.y - height)


## Assign a set of branches to the node.
func set_choices(
	choices
):
	clear_choices()
	for index in range(0, choices.size()):
		_add_branch(
			choices[index]
		)


## Get all the nodes branches.
func get_choices():
	var t: Array[ChoiceBranch] = []
	for index in range(2, get_child_count() - 1):
		t.append(get_child(index).get_choice())
	return t


func _connect_signals_for_choice(choice, index):
	choice.remove_requested.connect(
		_on_branch_remove_requested.bind(
			index
		)
	)
	choice.modified.connect(
		_on_branch_modified.bind(
			index
		)
	)
	choice.size_changed.connect(
		_on_branch_size_changed.bind(
			index
		)
	)
	choice.dropped_after.connect(
		_on_choice_dropped_after.bind(
			choice
		)
	)
	choice.preparing_to_change_parent.connect(
		_on_choice_preparing_to_change_parent.bind(
			choice
		)
	)


func _disconnect_signals_for_choice(choice):
	choice.remove_requested.disconnect(_on_branch_remove_requested)
	choice.modified.disconnect(_on_branch_modified)
	choice.size_changed.disconnect(_on_branch_size_changed)
	choice.dropped_after.disconnect(
		_on_choice_dropped_after
	)
	choice.preparing_to_change_parent.disconnect(
		_on_choice_preparing_to_change_parent
	)


# Get the embedded dialogue resource for the choice resource.
func _get_dialogue_resource(choice_resource):
	return choice_resource.dialogue


# Get the first dialogue text section of the embedded dialogue resource.
func _get_dialogue_text_resource(choice_resource):
	return choice_resource.dialogue.sections[0]


## Add a branch.
func _add_branch(
	choice,
	adjust_size=false
):
	var line = _create_branch(adjust_size)
	line.set_choice(
		choice
	)


## Get the text for the embedded dialogue node.
func get_dialogue_text():
	return _dialogue_text_edit.text


## Set the text for the embedded dialogue node.
func set_dialogue_text(speech):
	_dialogue_text_edit.text = speech


## Get the character selected for the embedded dialogue node.
func get_selected_character():
	return _character_select.selected


## Get the variant selected for the embedded dialogue node.
func get_selected_variant():
	return _variant_select.selected


## Select the specified character for the embedded dialogue node.
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


## Select the specified variant for the embedded dialogue node.
func select_variant(mood):
	var character_select := _character_select
	var variant_select := _variant_select
	if not mood:
		variant_select.select(-1)
		return
	if character_select.selected != -1:
		# This will be used when displaying a graph initially.
		var variants = _characters[character_select.selected].character_variants
		if variants:
			for index in range(0, variants.size()):
				var v = variants[index]
				if v == mood:
					variant_select.select(index)


## Set the translation key for the embedded dialogue node.
func set_dialogue_translation_key(k):
	_translation_key_edit.text = k


## Get the translation key for the embedded dialogue node.
func get_dialogue_translation_key():
	return _translation_key_edit.text


## Set the show dialogue for default flag.
func set_show_dialogue_for_default(show_dialogue_for_default):
	_show_dialogue_for_default_button.button_pressed = show_dialogue_for_default


## Get the show dialogue for default flag.
func get_show_dialogue_for_default():
	return _show_dialogue_for_default_button.button_pressed


## Populate the character and variant option buttons.
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


## Get the dialogue type for the embedded dialogue node.
func get_dialogue_type():
	var t = _dialogue_types_by_id.get(
		_dialogue_type_option.get_selected_id()
	)
	if t != null:
		return t['name']
	return ""


## Set the possible dialogue types for the embedded dialogue node.
func set_dialogue_types(dialogue_types):
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


## Select the specified dialogue type for the embedded dialogue node.
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


## Set the possible choice types.
func set_choice_types(choice_types):
	_logger.debug("Setting choice types")
	_choice_types = choice_types
	_choice_types_by_id = {}
	var choice_type_select = _choice_type_option
	choice_type_select.clear()
	choice_type_select.add_item("Select Type...", 0)
	var next_id = 1
	for t in _choice_types:
		_choice_types_by_id[next_id] = t
		choice_type_select.add_item(
			t["name"].capitalize(),
			next_id,
		)
		next_id += 1


## Get the selected choice type.
func get_choice_type():
	var t = _choice_types_by_id.get(
		_choice_type_option.get_selected_id()
	)
	if t != null:
		return t['name']
	return ""


## Set the selected choice type.
func select_choice_type(name, adjust_size=true):
	var t = _get_choice_type_by_name(name)
	_configure_for_choice_type(t, adjust_size)
	if t == null:
		_choice_type_option.select(
			_choice_type_option.get_item_index(0)
		)
	else:
		_choice_type_option.select(
			_choice_type_option.get_item_index(
				_get_id_for_choice_type(t)
			)
		)


## Clear all node relationships.
func clear_node_relationships():
	super.clear_node_relationships()
	for choice in node_resource.choices:
		choice.next = -1


func _reset_size(width: float) -> void:
	self.size = Vector2(width, 0.0)


func _reconnect_removal_signals():
	if get_child_count() > 2:
		for index in range(2, get_child_count() - 1):
			get_child(index).remove_requested.disconnect(
				_on_branch_remove_requested
			)
			get_child(index).remove_requested.connect(
				_on_branch_remove_requested.bind(index)
			)


func _create_branch(adjust_size):
	var new_value_line = _choice_value_scene.instantiate()
	var choice_resource = ChoiceBranch.new()
	choice_resource.display_translation_key = TranslationKey.generate(
		graph.name,
		"choice"
	)
	new_value_line.choice_resource = choice_resource
	add_child(new_value_line)
	move_child(new_value_line, get_child_count() - 2)
	if adjust_size:
		# TODO: Unknown why, but the branch scene has a height of 136 
		# when first created, but the actual size increase required is
		# 130
		size = Vector2(size.x, size.y + 130)
	_connect_signals_for_choice(new_value_line, get_child_count() - 2)
	# New choice
	set_slot(
		get_child_count() - 2,
		false,
		0,
		CONNECTOR_COLOUR,
		true,
		0,
		CONNECTOR_COLOUR,
	)
	# Add choice button
	set_slot(
		get_child_count() - 1,
		false,
		0,
		CONNECTOR_COLOUR,
		false,
		0,
		CONNECTOR_COLOUR,
	)
	return new_value_line


func _populate_properties(properties: Dictionary) -> void:
	_custom_properties_control.configure(properties)


func _get_properties() -> Dictionary:
	return _custom_properties_control.serialise()


func _get_theme(control):
	var theme = null
	while control != null && "theme" in control:
		theme = control.theme
		if theme != null: break
		control = control.get_parent()
	return theme


func _populate_variants(variants):
	var variant_select = _variant_select
	var selected = variant_select.selected
	variant_select.clear()
	if variants:
		for v in variants:
			variant_select.add_item(v.variant_display_name)
		variant_select.select(selected)


func _configure_for_dialogue_type(dialogue_type, adjust_size):
	if dialogue_type == null:
		return
	if dialogue_type["involves_character"]:
		if not _character_options_container.visible:
			_character_options_container.show()
			if adjust_size:
				var character_options_height = _character_options_container.size.y
				size = Vector2(size.x, size.y + character_options_height)
	else:
		if _character_options_container.visible:
			var character_options_height = _character_options_container.size.y
			_character_options_container.hide()
			if adjust_size:
				size = Vector2(size.x, size.y - character_options_height)


func _get_dialogue_type_by_name(name):
	for t in _dialogue_types:
		if t['name'] == name:
			return t
	return null


func _get_id_for_dialogue_type(type):
	return _dialogue_types_by_id.find_key(type)


func _configure_for_choice_type(choice_type, adjust_size):
	if choice_type == null:
		return
	if choice_type["include_dialogue"]:
		if not _dialogue.visible:
			_dialogue.show()
			_show_dialogue_for_default_button.show()
			if adjust_size:
				var dialogue_height = _dialogue.size.y
				size = Vector2(size.x, size.y + dialogue_height)
	else:
		if _dialogue.visible:
			var dialogue_height = _dialogue.size.y
			_dialogue.hide()
			_show_dialogue_for_default_button.hide()
			if adjust_size:
				size = Vector2(size.x, size.y - dialogue_height)


func _get_choice_type_by_name(name):
	for t in _choice_types:
		if t['name'] == name:
			return t
	return null


func _get_id_for_choice_type(type):
	return _choice_types_by_id.find_key(type)


func _move_dropped_choice_to_index(dropped, index):
	if dropped.get_parent() == self:
		if dropped.get_index() < index:
			index = index - 1
		if dropped.get_index() == index:
			return
		_move_choice_to_position(
			dropped,
			index
		)
	else:
		# This indicates a drag from a different node.
		dropped.prepare_to_change_parent()
		_add_choice_at_position(
			dropped,
			index
		)
	modified.emit()


func _move_choice_to_position(choice, index):
	var current_index = choice.get_index()
	self.move_child(choice, index)
	
	# The resources will be at indices two less than in the GUI
	# because of the initial header sections of the GUI
	node_resource.choices.insert(
		index - 2,
		node_resource.choices.pop_at(current_index - 2)
	)


func _add_choice_at_position(choice, index):
	self.add_child(choice)
	self.move_child(choice, index)
	# The resources will be at indices two less than in the GUI
	# because of the initial header sections of the GUI
	node_resource.choices.insert(index - 2, choice.get_choice())
	_connect_signals_for_choice(choice, index)
	# This is the slot that will have been opened up by the insertion of the
	# dropped branch.
	set_slot(
		get_child_count() - 2,
		false,
		0,
		CONNECTOR_COLOUR,
		true,
		0,
		CONNECTOR_COLOUR
	)
	_reconnect_removal_signals()


func _on_add_choice_button_pressed() -> void:
	_create_branch(true)
	modified.emit()


func _on_branch_remove_requested(index):
	remove_choice(index)
	modified.emit()


func _on_branch_modified(index):
	modified.emit()


func _on_branch_size_changed(change, index):
	_logger.debug("Choice line %s size changed by %s" % [index, change])
	_reset_size(self.size.x)


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_resize_request(new_minsize):
	# Height is managed automatically, so we only accept the x component of the change.
	set_deferred("size", Vector2(new_minsize.x, 0.0))


func _on_character_select_item_selected(index):
	var character = _characters[index]
	_populate_variants(character.character_variants)
	modified.emit()


func _on_variant_select_item_selected(index):
	modified.emit()


func _on_text_edit_text_changed():
	modified.emit()


func _on_translation_key_edit_text_changed(new_text):
	modified.emit()


func _on_dialogue_type_option_item_selected(index):
	var id = _dialogue_type_option.get_item_id(index)
	_configure_for_dialogue_type(
		_dialogue_types_by_id[id],
		true,
	)


func _on_choice_type_option_item_selected(index):
	var id = _choice_type_option.get_item_id(index)
	_configure_for_choice_type(
		_choice_types_by_id[id],
		true,
	)


func _on_custom_properties_control_add_property_requested(property_definition):
	var name = property_definition['name']
	if name in _get_dialogue_text_resource(node_resource).custom_properties:
		return
	var property = _get_dialogue_text_resource(node_resource).add_custom_property(
		property_definition['name'],
		property_definition['type'],
	)
	_custom_properties_control.add_property(property)


func _on_custom_properties_control_modified():
	modified.emit()


func _on_custom_properties_control_remove_property_requested(property_name):
	if not property_name in node_resource.dialogue.sections[0].custom_properties:
		return
	node_resource.dialogue.sections[0].remove_custom_property(property_name)
	_custom_properties_control.remove_property(property_name)


func _on_custom_properties_control_size_changed(size_change):
	_reset_size(self.size.x)


func _on_clear_character_button_pressed():
	select_character(null)


func _on_clear_variant_button_pressed():
	select_variant(null)


func _on_choice_dropped_after(dropped, after) -> void:
	_move_dropped_choice_to_index(
		dropped,
		after.get_index() + 1
	)


func _on_choice_preparing_to_change_parent(choice):
	# Remove the GUI choice and the resource choice from their parents.
	self.remove_choice(choice.get_index())
	node_resource.remove_choice(choice.get_choice())


func _on_drag_target_dropped(arg, at_position) -> void:
	# Drop at the topmost separator - move the target to the top.
	_move_dropped_choice_to_index(
		arg,
		2
	)


func _on_dialogue_menu_id_pressed(id: int) -> void:
	if id == DialogueMenuItems.ADD_CUSTOM_PROPERTY:
		_custom_properties_control.request_property_and_add()
	elif id == DialogueMenuItems.REGENERATE_TRANSLATION_KEY_FROM_TEXT:
		node_resource.dialogue.sections[0].text_translation_key = TranslationKey.generate_from_text(
			_dialogue_text_edit.text,
		)
		_translation_key_edit.text = node_resource.dialogue.sections[0].text_translation_key


func _on_dialogue_text_edit_resized() -> void:
	_reset_size(self.size.x)
	resized.emit()

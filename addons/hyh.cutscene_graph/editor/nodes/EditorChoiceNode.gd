@tool
extends "EditorGraphNodeBase.gd"
## Editor node for managing Choice resources.


const TITLE_FONT = preload("res://addons/hyh.cutscene_graph/editor/nodes/styles/TitleOptionFont.tres")
const TranslationKey = preload("../../utility/TranslationKey.gd")
const ChoiceBranch = preload("../../resources/graph/branches/ChoiceBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

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
@onready var _dialogue_text_edit := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/DialogueTextEdit
@onready var _character_select := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CharacterOptionsContainer/CharacterSelect
@onready var _variant_select := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CharacterOptionsContainer/VariantSelect
@onready var _show_dialogue_for_default_button := $HeaderContainer/VB/HorizontalLayout/ShowDialogueForDefaultButton
@onready var _translation_key_edit := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/TranslationContainer/TranslationKeyEdit
@onready var _custom_properties_control := $DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CustomPropertiesControl


func _init():
	_choice_type_option = OptionButton.new()
	_choice_type_option.item_selected.connect(
		_on_choice_type_option_item_selected
	)
	_choice_type_option.flat = true
	_choice_type_option.fit_to_longest_item = true
	_choice_type_option.add_theme_font_override("font", TITLE_FONT)


func _ready():
	var titlebar = get_titlebar_hbox()
	titlebar.add_child(_choice_type_option)
	# By moving to index 0, the empty title label serves as a spacer.
	titlebar.move_child(_choice_type_option, 0)
	_choice_type_option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	super()


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	set_choices(
		n.choices
	)
	set_show_dialogue_for_default(n.show_dialogue_for_default)
	set_dialogue_text(n.dialogue.text)
	set_dialogue_translation_key(n.dialogue.text_translation_key)
	select_character(n.dialogue.character)
	select_variant(n.dialogue.character_variant)
	select_dialogue_type(n.dialogue.dialogue_type, false)
	select_choice_type(n.choice_type, false)
	_populate_properties(n.dialogue.custom_properties)
	if n.size != null and n.size != Vector2.ZERO:
		size = n.size


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.choices = get_choices()
	node_resource.choice_type = get_choice_type()
	node_resource.show_dialogue_for_default = get_show_dialogue_for_default()
	node_resource.size = self.size
	# TODO: Persist dialogue, choice type.
	node_resource.dialogue.dialogue_type = get_dialogue_type()
	node_resource.dialogue.text = get_dialogue_text()
	node_resource.dialogue.text_translation_key = get_dialogue_translation_key()
	var selected_c = get_selected_character()
	if selected_c != -1:
		node_resource.dialogue.character = _characters[selected_c]
		var selected_v = get_selected_variant()
		if selected_v != -1:
			node_resource.dialogue.character_variant = node_resource.dialogue.character.character_variants[selected_v]
	else:
		node_resource.dialogue.character = null
	node_resource.dialogue.custom_properties = _get_properties()


## Clear all branches.
func clear_choices():
	for index in range(get_child_count() - 1, 1, -1):
		remove_choice(index)


## Remove a branch by index.
func remove_choice(index):
	removing_slot.emit(index)
	var node = get_child(index)
	var height = node.size.y
	remove_child(node)
	node.remove_requested.disconnect(_on_branch_remove_requested)
	node.modified.disconnect(_on_branch_modified)
	node.size_changed.disconnect(_on_branch_size_changed)
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
	for index in range(2, get_child_count()):
		t.append(get_child(index).get_choice())
	return t


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
	var character_select = _character_select
	for index in range(0, _characters.size()):
		var c = _characters[index]
		if c == character:
			character_select.select(index)
			_populate_variants(_characters[index].character_variants)


## Select the specified variant for the embedded dialogue node.
func select_variant(mood):
	var character_select = _character_select
	var variant_select = _variant_select
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
	#set_dialogue_type(node_resource.dialogue_type)


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
	#set_choice_type(node_resource.dialogue_type)


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


## Get an array of the port numbers for output connections.
func get_output_port_numbers() -> Array[int]:
	# TODO: I think the first port should be 1 for this node type, but
	# currently 0 is active in the UI so that is reflected here.
	var ports: Array[int] = [0]
	# The port numbers are active ports - slot 1 is inactive, so slot 2 has the
	# index 1 instead - and the last port index is child count - 1
	for i in range(1, get_child_count() - 1):
		ports.append(i)
	return ports


func _reconnect_removal_signals():
	if get_child_count() > 2:
		for index in range(2, get_child_count()):
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
	if adjust_size:
		# TODO: Unknown why, but the branch scene has a height of 136 
		# when first created, but the actual size increase required is
		# 130
		size = Vector2(size.x, size.y + 130)
	new_value_line.remove_requested.connect(
		_on_branch_remove_requested.bind(
			get_child_count() - 1,
		)
	)
	new_value_line.modified.connect(
		_on_branch_modified.bind(
			get_child_count() - 1,
		)
	)
	new_value_line.size_changed.connect(
		_on_branch_size_changed.bind(
			get_child_count() - 1,
		)
	)
	set_slot(
		get_child_count() - 1,
		false,
		0,
		CONNECTOR_COLOUR,
		true,
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


func _on_add_branch_button_pressed():
	_create_branch(true)
	modified.emit()


func _on_branch_remove_requested(index):
	remove_choice(index)
	modified.emit()


func _on_branch_modified(index):
	modified.emit()


func _on_branch_size_changed(change, index):
	_logger.debug("Choice line %s size changed by %s" % [index, change])
	self.size = Vector2(self.size.x, self.size.y + change)


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_resize_request(new_minsize):
	var showing_dialogue = _dialogue.visible
	if showing_dialogue:
		self.set_size(new_minsize)
		return
	self.set_size(Vector2(new_minsize.x, 0))


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
	if name in node_resource.dialogue.custom_properties:
		return
	var property = node_resource.dialogue.add_custom_property(
		property_definition['name'],
		property_definition['type'],
	)
	_custom_properties_control.add_property(property)


func _on_custom_properties_control_modified():
	modified.emit()


func _on_custom_properties_control_remove_property_requested(property_name):
	if not property_name in node_resource.dialogue.custom_properties:
		return
	node_resource.dialogue.remove_custom_property(property_name)
	_custom_properties_control.remove_property(property_name)


func _on_custom_properties_control_size_changed(size_change):
	self.size = Vector2(self.size.x, self.size.y + size_change)

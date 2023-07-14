@tool
extends "EditorGraphNodeBase.gd"

const TranslationKey = preload("../../utility/TranslationKey.gd")

const ChoiceBranch = preload("../../resources/graph/branches/ChoiceBranch.gd")
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

# Main dialogue related containers
@onready var Dialogue = get_node("DialogueMarginContainer/Dialogue")
@onready var CharacterOptionsContainer = get_node("DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CharacterOptionsContainer")

@onready var ChoiceTypeOption: OptionButton = get_node("ChoiceTypeParent/ChoiceTypeOption")
@onready var DialogueTypeOption: OptionButton = get_node("DialogueMarginContainer/Dialogue/DialogueTypeParent/DialogueTypeOption")
@onready var ShowDialogueForDefaultButton: CheckButton = get_node("HeaderContainer/VBoxContainer/HorizontalLayout/ShowDialogueForDefaultButton")

var _choice_value_scene = preload("../branches/EditorChoiceValue.tscn")

var _characters
var _choice_types
var _choice_types_by_id
var _dialogue_types
var _dialogue_types_by_id

# TODO: Probably no longer required
var _original_size: Vector2


func _get_dialogue_text_edit():
	return get_node("DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/DialogueTextEdit")


func _get_character_select():
	return get_node("DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CharacterOptionsContainer/CharacterSelect")


func _get_variant_select():
	return get_node("DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/CharacterOptionsContainer/VariantSelect")


func _get_translation_key_edit():
	return get_node("DialogueMarginContainer/Dialogue/DialogueContainer/VerticalLayout/TranslationContainer/TranslationKeyEdit")


func _get_dialogue_type_select():
	return get_node("DialogueMarginContainer/Dialogue/DialogueTypeParent/DialogueTypeOption")


func _get_choice_type_select():
	return get_node("ChoiceTypeParent/ChoiceTypeOption")


func clear_choices():
	for index in range(get_child_count() - 1, 2, -1):
		remove_choice(index)


func remove_choice(index):
	emit_signal("removing_slot", index)
	var node = get_child(index)
	var height = node.size.y
	remove_child(node)
	node.disconnect("remove_requested", Callable(self, "_value_remove_requested"))
	reconnect_removal_signals()
	# This should restore the control to the minimum required for the remaining
	# choices, but a bit more than strictly necessary horizontally.
	# TODO: This is insufficient to reclaim the space used by condition nodes.
	#size = _original_size
	size = Vector2(size.x, size.y - height)


func set_choices(
	choices
):
	clear_choices()
	for index in range(0, choices.size()):
		_add_choice(
			choices[index]
		)


func get_choices():
	var t: Array[ChoiceBranch] = []
	for index in range(3, get_child_count()):
		t.append(get_child(index).get_choice())
	return t


func _add_choice(
	choice,
	adjust_size=false
):
	var line = _create_line(adjust_size)
	line.set_choice(
		choice
	)


func _create_line(adjust_size):
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
	new_value_line.connect("remove_requested", Callable(self, "_value_remove_requested").bind(get_child_count() - 1))
	new_value_line.connect("modified", Callable(self, "_line_modified").bind(get_child_count() - 1))
	set_slot(get_child_count() - 1, false, 0, CONNECTOR_COLOUR, true, 0, CONNECTOR_COLOUR)
	return new_value_line


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	# We want to retain the original width, but the original height
	# includes sample choices which are not yet removed.
	# TODO: This is no good anymore because the user is allowed to resize
	# the node themselves
	_original_size = Vector2(size.x, 0.0)
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
	if n.size != null and n.size != Vector2.ZERO:
		size = n.size


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


func get_dialogue_text():
	return _get_dialogue_text_edit().text


func set_dialogue_text(speech):
	_get_dialogue_text_edit().text = speech


func get_selected_character():
	return _get_character_select().selected


func get_selected_variant():
	return _get_variant_select().selected


func set_dialogue_translation_key(k):
	_get_translation_key_edit().text = k


func get_dialogue_translation_key():
	return _get_translation_key_edit().text


func set_show_dialogue_for_default(show_dialogue_for_default):
	ShowDialogueForDefaultButton.button_pressed = show_dialogue_for_default


func get_show_dialogue_for_default():
	return ShowDialogueForDefaultButton.button_pressed


func clear_node_relationships():
	super.clear_node_relationships()
	for choice in node_resource.choices:
		choice.next = -1


func _on_AddValueButton_pressed():
	_create_line(true)
	emit_signal("modified")


func _value_remove_requested(index):
	remove_choice(index)
	emit_signal("modified")


func _line_modified(index):
	emit_signal("modified")


func _get_theme(control):
	var theme = null
	while control != null && "theme" in control:
		theme = control.theme
		if theme != null: break
		control = control.get_parent()
	return theme


func reconnect_removal_signals():
	if get_child_count() > 2:
		for index in range(3, get_child_count()):
			get_child(index).disconnect("remove_requested", Callable(self, "_value_remove_requested"))
			get_child(index).connect("remove_requested", Callable(self, "_value_remove_requested").bind(index))


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_resize_request(new_minsize):
	var showing_dialogue = Dialogue.visible
	if showing_dialogue:
		self.set_size(new_minsize)
		return
	self.set_size(Vector2(new_minsize.x, 0))


func populate_characters(characters):
	Logger.debug("Populating character select")
	var character_select = _get_character_select()
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


func select_character(character):
	# This will be used when displaying a graph initially.
	var character_select = _get_character_select()
	for index in range(0, _characters.size()):
		var c = _characters[index]
		if c == character:
			character_select.select(index)
			_populate_variants(_characters[index].character_variants)


func _populate_variants(variants):
	var variant_select = _get_variant_select()
	var selected = variant_select.selected
	variant_select.clear()
	if variants:
		for v in variants:
			variant_select.add_item(v.variant_display_name)
		variant_select.select(selected)


func select_variant(mood):
	var character_select = _get_character_select()
	var variant_select = _get_variant_select()
	if character_select.selected != -1:
		# This will be used when displaying a graph initially.
		var variants = _characters[character_select.selected].character_variants
		if variants:
			for index in range(0, variants.size()):
				var v = variants[index]
				if v == mood:
					variant_select.select(index)


func get_dialogue_type():
	var t = _dialogue_types_by_id.get(
		DialogueTypeOption.get_selected_id()
	)
	if t != null:
		return t['name']
	return ""


func select_dialogue_type(name, adjust_size=true):
	var t = _get_dialogue_type_by_name(name)
	_configure_for_dialogue_type(t, adjust_size)
	if t == null:
		DialogueTypeOption.select(
			DialogueTypeOption.get_item_index(0)
		)
	else:
		DialogueTypeOption.select(
			DialogueTypeOption.get_item_index(
				_get_id_for_dialogue_type(t)
			)
		)


func _configure_for_dialogue_type(dialogue_type, adjust_size):
	if dialogue_type == null:
		return
	if dialogue_type["involves_character"]:
		if not CharacterOptionsContainer.visible:
			CharacterOptionsContainer.show()
			if adjust_size:
				var character_options_height = CharacterOptionsContainer.size.y
				size = Vector2(size.x, size.y + character_options_height)
	else:
		if CharacterOptionsContainer.visible:
			var character_options_height = CharacterOptionsContainer.size.y
			CharacterOptionsContainer.hide()
			if adjust_size:
				size = Vector2(size.x, size.y - character_options_height)


func set_dialogue_types(dialogue_types):
	Logger.debug("Setting dialogue types")
	_dialogue_types = dialogue_types
	_dialogue_types_by_id = {}
	var dialogue_type_select = _get_dialogue_type_select()
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


func _get_dialogue_type_by_name(name):
	for t in _dialogue_types:
		if t['name'] == name:
			return t
	return null


func _get_id_for_dialogue_type(type):
	return _dialogue_types_by_id.find_key(type)


func get_choice_type():
	var t = _choice_types_by_id.get(
		ChoiceTypeOption.get_selected_id()
	)
	if t != null:
		return t['name']
	return ""


func select_choice_type(name, adjust_size=true):
	var t = _get_choice_type_by_name(name)
	_configure_for_choice_type(t, adjust_size)
	if t == null:
		ChoiceTypeOption.select(
			ChoiceTypeOption.get_item_index(0)
		)
	else:
		ChoiceTypeOption.select(
			ChoiceTypeOption.get_item_index(
				_get_id_for_choice_type(t)
			)
		)


func _configure_for_choice_type(choice_type, adjust_size):
	if choice_type == null:
		return
	if choice_type["include_dialogue"]:
		if not Dialogue.visible:
			Dialogue.show()
			ShowDialogueForDefaultButton.show()
			if adjust_size:
				var dialogue_height = Dialogue.size.y
				size = Vector2(size.x, size.y + dialogue_height)
	else:
		if Dialogue.visible:
			var dialogue_height = Dialogue.size.y
			Dialogue.hide()
			ShowDialogueForDefaultButton.hide()
			if adjust_size:
				size = Vector2(size.x, size.y - dialogue_height)


func set_choice_types(choice_types):
	Logger.debug("Setting choice types")
	_choice_types = choice_types
	_choice_types_by_id = {}
	var choice_type_select = _get_choice_type_select()
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


func _get_choice_type_by_name(name):
	for t in _choice_types:
		if t['name'] == name:
			return t
	return null


func _get_id_for_choice_type(type):
	return _choice_types_by_id.find_key(type)


func _on_character_select_item_selected(index):
	var character = _characters[index]
	_populate_variants(character.character_variants)
	emit_signal("modified")


func _on_variant_select_item_selected(index):
	emit_signal("modified")


func _on_text_edit_text_changed():
	emit_signal("modified")


func _on_translation_key_edit_text_changed(new_text):
	emit_signal("modified")


func _on_dialogue_type_option_item_selected(index):
	var id = DialogueTypeOption.get_item_id(index)
	_configure_for_dialogue_type(
		_dialogue_types_by_id[id],
		true,
	)


func _on_choice_type_option_item_selected(index):
	var id = ChoiceTypeOption.get_item_id(index)
	_configure_for_choice_type(
		_choice_types_by_id[id],
		true,
	)

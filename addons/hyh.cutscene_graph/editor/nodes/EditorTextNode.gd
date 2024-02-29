@tool
extends "EditorGraphNodeBase.gd"

const TITLE_FONT = preload("res://addons/hyh.cutscene_graph/editor/nodes/styles/TitleOptionFont.tres")

@onready var CharacterOptionsContainer: GridContainer = get_node("RootContainer/VerticalLayout/CharacterOptionsContainer")
var DialogueTypeOption: OptionButton
@onready var CustomPropertiesControl = get_node("RootContainer/VerticalLayout/CustomPropertiesControl")

var _characters
var _dialogue_types
var _dialogue_types_by_id

# TODO: May not need this.
var _original_size: Vector2


func _init():
	DialogueTypeOption = OptionButton.new()
	DialogueTypeOption.item_selected.connect(_on_dialogue_type_option_item_selected)
	DialogueTypeOption.flat = true
	DialogueTypeOption.fit_to_longest_item = true
	DialogueTypeOption.add_theme_font_override("font", TITLE_FONT)


func _ready():
	var titlebar = get_titlebar_hbox()
	titlebar.add_child(DialogueTypeOption)
	# By moving to index 0, the empty title label serves as a spacer.
	titlebar.move_child(DialogueTypeOption, 0)
	DialogueTypeOption.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	super()


func _get_text_edit():
	return get_node("RootContainer/VerticalLayout/TextEdit")


func _get_character_select():
	return get_node("RootContainer/VerticalLayout/CharacterOptionsContainer/CharacterSelect")


func _get_variant_select():
	return get_node("RootContainer/VerticalLayout/CharacterOptionsContainer/VariantSelect")


func _get_translation_key_edit():
	return get_node("RootContainer/VerticalLayout/TranslationContainer/TranslationKeyEdit")


func _get_dialogue_type_select():
	return DialogueTypeOption


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	if n.size != Vector2.ZERO:
		size = n.size
	# Hmm, seems like this is not gonna work when the node is manually
	# resizable...
	_original_size = Vector2(size.x, 0.0)
	set_text(n.text)
	set_translation_key(n.text_translation_key)
	select_character(n.character)
	select_variant(n.character_variant)
	select_dialogue_type(n.dialogue_type, false)
	_populate_properties(n.custom_properties)


func _populate_properties(properties: Dictionary) -> void:
	CustomPropertiesControl.configure(properties)


func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.dialogue_type = get_dialogue_type()
	node_resource.size = self.size
	node_resource.text = get_text()
	node_resource.text_translation_key = get_translation_key()
	var selected_c = get_selected_character()
	if selected_c != -1:
		node_resource.character = _characters[selected_c]
		var selected_v = get_selected_variant()
		if selected_v != -1:
			node_resource.character_variant = node_resource.character.character_variants[selected_v]
	else:
		node_resource.character = null
	node_resource.custom_properties = _get_properties()


func _get_properties() -> Dictionary:
	return CustomPropertiesControl.serialise()


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


func set_dialogue_types(dialogue_types, defer=true):
	#if defer:
	#	call_deferred("set_dialogue_types", dialogue_types, false)
	#	return
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


func get_text():
	return _get_text_edit().text


func set_text(speech):
	_get_text_edit().text = speech


# Don't think I want to store the text as an array anymore
func get_text_array():
	var t = _get_text_edit().text
	return t.split("\n")


func set_text_from_array(speech):
	# This requires that speech be a PoolStringArray. If that is not the case, should convert here
	_get_text_edit().text = "\n".join(speech)


func get_selected_character():
	return _get_character_select().selected


func get_selected_variant():
	return _get_variant_select().selected


func set_translation_key(k):
	_get_translation_key_edit().text = k


func get_translation_key():
	return _get_translation_key_edit().text


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


func _on_CharacterSelect_item_selected(ID):
	var character = _characters[ID]
	_populate_variants(character.character_variants)
	emit_signal("modified")


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_VariantSelect_item_selected(ID):
	emit_signal("modified")


func _on_TextEdit_text_changed():
	emit_signal("modified")


func _on_resize_request(new_minsize):
	self.set_size(new_minsize)


func _on_translation_key_edit_text_changed(new_text):
	emit_signal("modified")


func _on_dialogue_type_option_item_selected(index):
	var id = DialogueTypeOption.get_item_id(index)
	_configure_for_dialogue_type(
		_dialogue_types_by_id[id],
		true,
	)


func _on_custom_properties_control_add_property_requested(property_definition):
	var name = property_definition['name']
	if name in node_resource.custom_properties:
		return
	var property = node_resource.add_custom_property(
		property_definition['name'],
		property_definition['type'],
	)
	CustomPropertiesControl.add_property(property)


func _on_custom_properties_control_remove_property_requested(property_name):
	if not property_name in node_resource.custom_properties:
		return
	node_resource.remove_custom_property(property_name)
	CustomPropertiesControl.remove_property(property_name)


func _on_custom_properties_control_size_changed(size_change):
	self.size = Vector2(self.size.x, self.size.y + size_change)


func _on_custom_properties_control_modified():
	modified.emit()

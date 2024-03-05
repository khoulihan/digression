@tool
extends "EditorGraphNodeBase.gd"
## Editor node for Dialogue resource node.


const TITLE_FONT = preload("res://addons/hyh.cutscene_graph/editor/nodes/styles/TitleOptionFont.tres")

var _characters
var _dialogue_types
var _dialogue_types_by_id
var _dialogue_type_option: OptionButton

# TODO: May not need this.
var _original_size: Vector2

@onready var _text_edit := $RootContainer/VerticalLayout/TextEdit
@onready var _character_select := $RootContainer/VerticalLayout/CharacterOptionsContainer/CharacterSelect
@onready var _variant_select := $RootContainer/VerticalLayout/CharacterOptionsContainer/VariantSelect
@onready var _translation_key_edit := $RootContainer/VerticalLayout/TranslationContainer/TranslationKeyEdit
@onready var _character_options_container: GridContainer = $RootContainer/VerticalLayout/CharacterOptionsContainer
@onready var _custom_properties_control = $RootContainer/VerticalLayout/CustomPropertiesControl


func _init():
	_dialogue_type_option = OptionButton.new()
	_dialogue_type_option.item_selected.connect(_on_dialogue_type_option_item_selected)
	_dialogue_type_option.flat = true
	_dialogue_type_option.fit_to_longest_item = true
	_dialogue_type_option.add_theme_font_override("font", TITLE_FONT)


func _ready():
	var titlebar = get_titlebar_hbox()
	titlebar.add_child(_dialogue_type_option)
	# By moving to index 0, the empty title label serves as a spacer.
	titlebar.move_child(_dialogue_type_option, 0)
	_dialogue_type_option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	super()


## Configure the editor node for a given graph node.
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


## Persist changes from the editor node's controls into the graph node's properties
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


## Get the dialogue text.
func get_text():
	return _text_edit.text


## Set the dialogue text.
func set_text(speech):
	_text_edit.text = speech


# TODO: Is there actually any need for this?
## Set the dialogue text from an array of individual lines.
func set_text_from_array(speech: Array[String]):
	# This requires that speech be a PoolStringArray. If that is not the case, should convert here
	_text_edit.text = "\n".join(speech)


## Get the selected character.
func get_selected_character():
	return _character_select.selected


## Get the selected variant.
func get_selected_variant():
	return _variant_select.selected


## Set the translation key.
func set_translation_key(k):
	_translation_key_edit.text = k


## Get the translation key.
func get_translation_key():
	return _translation_key_edit.text


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
	var character_select = _character_select
	for index in range(0, _characters.size()):
		var c = _characters[index]
		if c == character:
			character_select.select(index)
			_populate_variants(_characters[index].character_variants)


## Select the specified variant.
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


func _get_properties() -> Dictionary:
	return _custom_properties_control.serialise()


func _populate_properties(properties: Dictionary) -> void:
	_custom_properties_control.configure(properties)


func _populate_variants(variants):
	var variant_select = _variant_select
	var selected = variant_select.selected
	variant_select.clear()
	if variants:
		for v in variants:
			variant_select.add_item(v.variant_display_name)
		variant_select.select(selected)


func _on_character_select_item_selected(ID):
	var character = _characters[ID]
	_populate_variants(character.character_variants)
	modified.emit()


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_variant_select_item_selected(ID):
	modified.emit()


func _on_text_edit_text_changed():
	modified.emit()


func _on_resize_request(new_minsize):
	self.set_size(new_minsize)


func _on_translation_key_edit_text_changed(new_text):
	modified.emit()


func _on_dialogue_type_option_item_selected(index):
	var id = _dialogue_type_option.get_item_id(index)
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
	_custom_properties_control.add_property(property)


func _on_custom_properties_control_remove_property_requested(property_name):
	if not property_name in node_resource.custom_properties:
		return
	node_resource.remove_custom_property(property_name)
	_custom_properties_control.remove_property(property_name)


func _on_custom_properties_control_size_changed(size_change):
	self.size = Vector2(self.size.x, self.size.y + size_change)


func _on_custom_properties_control_modified():
	modified.emit()

@tool
extends MarginContainer


signal modified()
signal removal_requested()
signal preparing_to_change_parent()
signal dropped_after(section)


enum DialogueMenuItems {
	ADD_CUSTOM_PROPERTY,
	REGENERATE_TRANSLATION_KEY_FROM_TEXT,
}


const DigressionSettings = preload("../../settings/DigressionSettings.gd")
const TranslationKey = preload("../../utility/TranslationKey.gd")
const DialogueSection = preload("res://addons/hyh.digression/resources/graph/DialogueSection.gd")
const HANDLE_ICON = preload("../../icons/icon_drag_light.svg")
const PREVIEW_LENGTH = 25
const TEXT_EDIT_MINIMUM_WIDTH = 200.0

@export var section_resource: DialogueSection

var _variants

@onready var _text_edit: CodeEdit = $VB/CodeBlock/CodeEdit
@onready var _variant_select := $VB/VariantSelectContainer/VariantSelect
@onready var _variant_select_container := $VB/VariantSelectContainer
@onready var _translation_key_edit := $VB/CodeBlock/TranslationContainer/TranslationKeyEdit
@onready var _custom_properties_control = $VB/CustomPropertiesControl
@onready var _header := $VB/Header
@onready var _menu_button: MenuButton = $VB/CodeBlock/TranslationContainer/MenuButton


func _ready() -> void:
	# Hook up the signal handler for the menu.
	var popup := _menu_button.get_popup()
	popup.id_pressed.connect(_on_menu_id_pressed)
	
	# Guidelines for the dialogue text.
	var guidelines := DigressionSettings.get_dialogue_line_length_guidelines()
	_text_edit.line_length_guidelines.clear()
	_text_edit.line_length_guidelines.append_array(guidelines)


# TODO: This might need additional arguments - dialogue type (or if it includes
# a character at least), variants... These will already have been selected at
# the node level, but any filtering down to this level will not necessarily be
# valid.
# TODO: g not really required here it looks like.
## Configure the editor section control for a given graph node section.
func configure_for_section(g, s, involves_character, variants):
	self.section_resource = s
	populate_variants(variants)
	configure_for_dialogue_type(involves_character, false)
	set_text(s.text)
	set_translation_key(s.text_translation_key)
	select_variant(s.character_variant)
	_populate_properties(s.custom_properties)


## Configure the section appropriately for the number of siblings it has.
func configure_for_sibling_count(count):
	_header.visible = (count >= 1)


func configure_for_dialogue_type(involves_character, adjust_size):
	_variant_select_container.visible = involves_character


## Persist changes from the editor controls into the graph section's properties
func persist_changes_to_resource():
	section_resource.text = get_text()
	section_resource.text_translation_key = get_translation_key()
	
	var selected_v = get_selected_variant()
	if selected_v != -1 and _variants != null:
		section_resource.character_variant = _variants[selected_v]
	else:
		section_resource.character_variant = null
	
	section_resource.custom_properties = _get_properties()


## Get the dialogue text.
func get_text():
	return _text_edit.text


## Set the dialogue text.
func set_text(speech):
	_text_edit.text = speech


## Get the selected variant.
func get_selected_variant():
	return _variant_select.selected


## Select the specified variant.
func select_variant(mood):
	var variant_select := _variant_select
	if not mood:
		variant_select.select(-1)
		return

	# This will be used when displaying a graph initially.
	var variants = _variants
	if variants:
		for index in range(0, variants.size()):
			var v = variants[index]
			if v.variant_name == mood.variant_name:
				variant_select.select(index)


## Set the translation key.
func set_translation_key(k):
	_translation_key_edit.text = k


## Get the translation key.
func get_translation_key():
	return _translation_key_edit.text


## Populate the variants for the selected character.
func populate_variants(variants):
	_variants = variants
	var variant_select = _variant_select
	var selected = variant_select.selected
	variant_select.clear()
	if variants:
		for v in variants:
			variant_select.add_item(v.variant_display_name)
		variant_select.select(selected)


func prepare_to_change_parent():
	preparing_to_change_parent.emit()


func get_drag_preview():
	var preview = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.texture = HANDLE_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	var ptext = Label.new()
	ptext.text = _get_drag_preview_text()
	preview.add_child(icon)
	preview.add_child(ptext)
	preview.modulate = Color.from_string("#777777FF", Color.DIM_GRAY)
	return preview


func _get_drag_preview_text():
	var preview_text = "Dialogue Section"
	var text = self.get_text().strip_edges()
	if text.is_empty():
		return preview_text
	var first_line = text.split("\n", false, 1)[0].strip_edges().strip_escapes()
	if len(first_line) > PREVIEW_LENGTH:
		first_line = "{0}...".format([first_line.substr(0, PREVIEW_LENGTH)])
	preview_text = "{0} (\"{1}\")".format([preview_text, first_line])
	return preview_text


func _get_properties() -> Dictionary:
	return _custom_properties_control.serialise()


func _populate_properties(properties: Dictionary) -> void:
	_custom_properties_control.configure(properties)


func _on_custom_properties_control_add_property_requested(property_definition):
	var name = property_definition['name']
	if name in section_resource.custom_properties:
		return
	var property = section_resource.add_custom_property(
		property_definition['name'],
		property_definition['type'],
	)
	_custom_properties_control.add_property(property)


func _on_custom_properties_control_remove_property_requested(property_name):
	if not property_name in section_resource.custom_properties:
		return
	section_resource.remove_custom_property(property_name)
	_custom_properties_control.remove_property(property_name)


func _on_custom_properties_control_size_changed(size_change):
	self.size = Vector2(self.size.x, self.size.y + size_change)


func _on_custom_properties_control_modified():
	modified.emit()


func _on_clear_variant_button_pressed():
	select_variant(null)
	modified.emit()


func _on_variant_select_item_selected(ID):
	modified.emit()


func _on_translation_key_edit_text_changed(new_text):
	modified.emit()


func _on_remove_button_pressed() -> void:
	removal_requested.emit()


func _on_drag_target_dropped(arg: Variant, at_position: Variant) -> void:
	dropped_after.emit(arg)


func _on_code_edit_text_changed() -> void:
	modified.emit()


func _on_code_edit_resized() -> void:
	resized.emit()


func _on_menu_id_pressed(id: int) -> void:
	if id == DialogueMenuItems.ADD_CUSTOM_PROPERTY:
		_custom_properties_control.request_property_and_add()
	elif id == DialogueMenuItems.REGENERATE_TRANSLATION_KEY_FROM_TEXT:
		section_resource.text_translation_key = TranslationKey.generate_from_text(
			section_resource.text,
		)
		_translation_key_edit.text = section_resource.text_translation_key

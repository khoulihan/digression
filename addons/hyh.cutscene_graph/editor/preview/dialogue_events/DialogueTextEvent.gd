@tool
extends MarginContainer


signal character_displayed()
signal ready_to_continue()


@onready var _character_name_label = $VB/VB/CharacterContainer/CharacterNameLabel
@onready var _type_label = $VB/VB/HB/HB/TypeLabel
@onready var _variant_label = $VB/VB/CharacterContainer/VariantLabel
@onready var _dialogue_label = $VB/VB/HB/HB/DialogueContainer/DialogueLabel
@onready var _dialogue_container = $VB/VB/HB/HB/DialogueContainer
@onready var _dialogue_indicator = $VB/VB/HB/DialogueIndicator
@onready var _properties_container = $VB/VB/MC/PropertiesContainer


func populate(
	type,
	character,
	variant,
	dialogue,
	panel_resource,
	indicator_resource,
	display_characterwise,
	properties,
):
	if type == null:
		_type_label.hide()
	else:
		_type_label.text = type
		
	if character == null:
		_character_name_label.hide()
	else:
		_character_name_label.text = character.get_full_name()
	
	if variant == null:
		_variant_label.hide()
	else:
		_variant_label.text = variant.get_full_name()
	
	if character == null and variant == null:
		_dialogue_indicator.hide()
	
	_dialogue_label.text = dialogue
	
	if display_characterwise:
		_dialogue_label.visible_characters = 0
	
	if panel_resource != null:
		_dialogue_container.add_theme_stylebox_override("panel", panel_resource)
	if indicator_resource != null:
		_dialogue_indicator.add_theme_stylebox_override("panel", indicator_resource)
	
	for property_name in properties:
		var property_label: Label = Label.new()
		# TODO: Maybe format like in the editor here?
		property_label.text = "%s: %s" % [
			property_name,
			properties[property_name],
		]
		property_label.add_theme_color_override(
			"font_color",
			Color.from_string("#f0f0f0dc", Color.WHITE)
		)
		property_label.add_theme_font_size_override("font_size", 10)
		_properties_container.add_child(property_label)
	
	if display_characterwise:
		$Timer.start()


func _on_timer_timeout():
	_dialogue_label.visible_characters += 1
	character_displayed.emit()
	if _dialogue_label.visible_characters == len(_dialogue_label.text):
		$Timer.stop()
		ready_to_continue.emit()

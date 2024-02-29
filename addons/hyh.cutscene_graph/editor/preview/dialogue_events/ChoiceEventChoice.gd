@tool
extends VBoxContainer

signal choice_selected()


@onready var VisitedLabel: Label = $VB/Label
@onready var ChoiceButton: Button = $VB/Button
@onready var PropertiesContainer: VBoxContainer = $MC/PropertiesContainer


func populate(text, visit_count, index, properties):
	ChoiceButton.text = text
	if visit_count == 0:
		VisitedLabel.text = "Never visited"
	elif visit_count == 1:
		VisitedLabel.text = "Visited once"
	else:
		VisitedLabel.text = "Visited %s times" % visit_count
	
	var shortcut_index = index + 1
	if shortcut_index > 20:
		return
	
	ChoiceButton.shortcut = Shortcut.new()
	ChoiceButton.shortcut.resource_name = "Select choice"
	var key = InputEventKey.new()
	key.pressed = true
	ChoiceButton.shortcut.events.append(key)
	if shortcut_index < 10:
		key.keycode = KEY_0 + shortcut_index
	elif shortcut_index == 10:
		key.keycode = KEY_0
	elif shortcut_index < 20:
		key.keycode = KEY_0 + (shortcut_index - 10)
		key.ctrl_pressed = true
	elif shortcut_index == 20:
		key.keycode = KEY_0
		key.ctrl_pressed = true
	
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
		PropertiesContainer.add_child(property_label)


func _on_button_pressed():
	choice_selected.emit()

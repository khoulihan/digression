@tool
extends VBoxContainer
## Button for an individual choice.

signal choice_selected()

@onready var _visited_label: Label = $VB/Label
@onready var _choice_button: Button = $VB/Button
@onready var _properties_container: VBoxContainer = $MC/PropertiesContainer


## Populate the details of the choice.
func populate(text, visit_count, index, properties):
	_choice_button.text = text
	if visit_count == 0:
		_visited_label.text = "Never visited"
	elif visit_count == 1:
		_visited_label.text = "Visited once"
	else:
		_visited_label.text = "Visited %s times" % visit_count
	
	var shortcut_index = index + 1
	if shortcut_index > 20:
		return
	
	_choice_button.shortcut = Shortcut.new()
	_choice_button.shortcut.resource_name = "Select choice"
	var key = InputEventKey.new()
	key.pressed = true
	_choice_button.shortcut.events.append(key)
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
		_properties_container.add_child(property_label)


func _on_button_pressed():
	choice_selected.emit()

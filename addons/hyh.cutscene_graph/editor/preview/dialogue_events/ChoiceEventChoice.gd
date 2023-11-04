@tool
extends HBoxContainer

signal choice_selected()


func populate(text, visit_count, index):
	$Button.text = text
	if visit_count == 0:
		$Label.text = "Never visited"
	elif visit_count == 1:
		$Label.text = "Visited once"
	else:
		$Label.text = "Visited %s times" % visit_count
	
	var shortcut_index = index + 1
	if shortcut_index > 20:
		return
	
	$Button.shortcut = Shortcut.new()
	$Button.shortcut.resource_name = "Select choice"
	var key = InputEventKey.new()
	key.pressed = true
	$Button.shortcut.events.append(key)
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


func _on_button_pressed():
	choice_selected.emit()

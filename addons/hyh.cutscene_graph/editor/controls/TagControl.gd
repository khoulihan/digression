@tool
extends PanelContainer
## Control for an individual tag.


signal remove_requested()

## The name of the tag
var tag: String:
	get:
		return tag
	set(value):
		tag = value
		_tag_label.text = tag

@onready var _tag_label = $MC/HB/Label





func _on_button_pressed():
	remove_requested.emit()

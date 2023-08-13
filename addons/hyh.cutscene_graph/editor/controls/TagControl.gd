@tool
extends PanelContainer

signal remove_requested()

@onready var TagLabel = get_node("MarginContainer/HBoxContainer/Label")


var tag: String:
	get:
		return tag
	set(value):
		tag = value
		get_node("MarginContainer/HBoxContainer/Label").text = tag


func _on_button_pressed():
	remove_requested.emit()

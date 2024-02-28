@tool
extends EditorProperty


signal remove_requested()


# Called when the node enters the scene tree for the first time.
func _init() -> void:
	var remove_button := Button.new()
	remove_button.text = ""
	remove_button.icon = preload("res://addons/hyh.cutscene_graph/icons/icon_close.svg")
	remove_button.pressed.connect(_remove_button_pressed)
	add_child(remove_button)


func _remove_button_pressed() -> void:
	remove_requested.emit()


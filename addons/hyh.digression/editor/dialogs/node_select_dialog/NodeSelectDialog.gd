@tool
extends Window


signal canceled()
signal selected(node)


@onready var BackgroundPanel = get_node("BackgroundPanel")


func _ready() -> void:
	BackgroundPanel.color = get_theme_color("base_color", "Editor")


func _on_node_select_dialog_contents_canceled():
	canceled.emit()


func _on_node_select_dialog_contents_selected(node):
	selected.emit(node)


func _on_close_requested():
	canceled.emit()

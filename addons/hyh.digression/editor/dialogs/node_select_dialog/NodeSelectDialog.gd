@tool
extends Window


signal cancelled()
signal selected(node)


@onready var BackgroundPanel = get_node("BackgroundPanel")


func _ready() -> void:
	BackgroundPanel.color = get_theme_color("base_color", "Editor")


func _on_node_select_dialog_contents_cancelled():
	cancelled.emit()


func _on_node_select_dialog_contents_selected(node):
	selected.emit(node)


func _on_close_requested():
	cancelled.emit()

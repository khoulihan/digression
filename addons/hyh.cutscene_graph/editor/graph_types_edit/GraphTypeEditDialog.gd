@tool
extends Window


signal closing()


@onready var BackgroundPanel = get_node("BackgroundPanel")


func _ready() -> void:
	BackgroundPanel.color = get_theme_color("base_color", "Editor")


func configure():
	$GraphTypeEditDialogContents.configure()


func _on_graph_type_edit_dialog_contents_closing():
	closing.emit()


func _on_close_requested():
	closing.emit()

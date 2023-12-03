@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/Expression.gd"


signal remove_requested()


@onready var _panel : PanelContainer = get_node("PanelContainer")
@onready var _expression_container : VBoxContainer = get_node("PanelContainer/MC/ExpressionContainer")
@onready var _header : HBoxContainer = get_node("PanelContainer/MC/ExpressionContainer/Header")
@onready var _drag_handle : Button = get_node("PanelContainer/MC/ExpressionContainer/Header/DragHandle")
@onready var _title : Label = get_node("PanelContainer/MC/ExpressionContainer/Header/Title")
@onready var _remove_button = get_node("PanelContainer/MC/ExpressionContainer/Header/RemoveButton")


func set_title(text):
	_title.text = text


func _on_remove_button_pressed():
	var confirm = ConfirmationDialog.new()
	confirm.title = "Please confirm"
	confirm.dialog_text = "Are you sure you want to remove this expression? This action cannot be undone."
	confirm.canceled.connect(_remove_cancelled.bind(confirm))
	confirm.confirmed.connect(_remove_confirmed.bind(confirm))
	get_tree().root.add_child(confirm)
	confirm.show()


func _remove_confirmed(confirm):
	get_tree().root.remove_child(confirm)
	remove_requested.emit()


func _remove_cancelled(confirm):
	get_tree().root.remove_child(confirm)

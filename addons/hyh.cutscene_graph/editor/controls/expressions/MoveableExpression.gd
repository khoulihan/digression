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
	remove_requested.emit()

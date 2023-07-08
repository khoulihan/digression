@tool
extends "EditorGraphNodeBase.gd"


@onready var ChevronContainer = get_node("MarginContainer/HBoxContainer")

var _selected = 0


func _ready():
	for child in ChevronContainer.get_children():
		child.modulate = Color.SLATE_GRAY


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_timer_timeout():
	var previous = _selected
	_selected += 1
	
	if _selected > ChevronContainer.get_child_count() - 1:
		_selected = 0
	
	ChevronContainer.get_child(previous).modulate = Color.SLATE_GRAY
	ChevronContainer.get_child(_selected).modulate = Color.LIGHT_GREEN

@tool
extends "EditorGraphNodeBase.gd"
## Editor routing node.


const OFF_COLOUR = Color.SLATE_GRAY
const ON_COLOUR = Color.LIGHT_GREEN

var _selected = 0

@onready var _indicator_container = $MC/IndicatorContainer


func _ready():
	super()
	for child in _indicator_container.get_children():
		child.modulate = OFF_COLOUR


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_timer_timeout():
	var previous = _selected
	_selected += 1
	
	if _selected > _indicator_container.get_child_count() - 1:
		_selected = 0
	
	_indicator_container.get_child(previous).modulate = OFF_COLOUR
	_indicator_container.get_child(_selected).modulate = ON_COLOUR

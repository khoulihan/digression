@tool
extends MarginContainer


signal choice_selected(index)


const ChoiceEventChoice = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/ChoiceEventChoice.tscn")


@onready var _selected_choice = $VB/SelectedChoice
@onready var _selected_choice_label = $VB/SelectedChoice/PanelContainer/HBoxContainer/SelectedChoiceLabel
@onready var _choices_container = $VB/ChoicesContainer


var _choices


func populate(choices):
	_choices = choices
	for child in _choices_container.get_children():
		_choices_container.remove_child(child)
		child.free()
	for i in choices:
		var c = ChoiceEventChoice.instantiate()
		_choices_container.add_child(c)
		c.populate(choices[i].text, choices[i].visit_count, i)
		c.choice_selected.connect(
			_choice_selected.bind(i)
		)


func cancel():
	_choices_container.hide()


func _choice_selected(choice):
	_choices_container.hide()
	_selected_choice.show()
	_selected_choice_label.text = _choices[choice].text
	choice_selected.emit(choice)


func _ready():
	_selected_choice.visible = false

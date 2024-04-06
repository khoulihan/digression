@tool
extends MarginContainer
## A control for displaying choices to the user in the graph previewer.


signal choice_selected(index)

const ChoiceEventChoice = preload("ChoiceEventChoice.tscn")

var _choices

@onready var _selected_choice = $VB/SelectedChoice
@onready var _selected_choice_label = $VB/SelectedChoice/PC/HB/SelectedChoiceLabel
@onready var _choices_container = $VB/ChoicesContainer


func _ready():
	_selected_choice.visible = false


## Populate the control for a set of choices.
func populate(choices):
	_choices = choices
	for child in _choices_container.get_children():
		_choices_container.remove_child(child)
		child.free()
	for i in choices:
		var c = ChoiceEventChoice.instantiate()
		_choices_container.add_child(c)
		c.populate(choices[i].text, choices[i].visit_count, i, choices[i].properties)
		c.choice_selected.connect(
			_on_choice_selected.bind(i)
		)


## Cancel the ongoing operation.
func cancel():
	_choices_container.hide()


func _on_choice_selected(choice):
	_choices_container.hide()
	_selected_choice.show()
	_selected_choice_label.text = _choices[choice].text
	choice_selected.emit(choice)

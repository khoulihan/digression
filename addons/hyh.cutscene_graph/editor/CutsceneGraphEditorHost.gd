@tool
extends MarginContainer

signal expand_button_toggled(button_pressed)

@onready var editor = $VB/ModeContainer/Editor
@onready var preview = $VB/ModeContainer/Preview
@onready var edit_button = $VB/HB/ModeSwitch/EditButton
@onready var preview_button = $VB/HB/ModeSwitch/PreviewButton

# Called when the node enters the scene tree for the first time.
func _ready():
	# The controls are not actually ready here.
	pass


func show_hide(show, hide):
	show.visible = true
	hide.visible = false


func _on_expand_button_toggled(button_pressed):
	expand_button_toggled.emit(button_pressed)


func _on_preview_starting_preview():
	edit_button.disabled = true


func _on_preview_stopping_preview():
	edit_button.disabled = false


func _on_preview_button_toggled(button_pressed):
	edit_button.set_pressed_no_signal(false)
	preview_button.set_pressed_no_signal(true)
	show_hide(preview, editor)
	# TODO: Will it be expected to restart when switching modes?
	if button_pressed:
		preview.prepare_to_preview_graph(editor.get_edited_graph())


func _on_edit_button_toggled(button_pressed):
	preview_button.set_pressed_no_signal(false)
	edit_button.set_pressed_no_signal(true)
	preview.clear_variable_stores()
	show_hide(editor, preview)


func _on_editor_previewable():
	preview_button.disabled = false


func _on_editor_not_previewable():
	preview_button.disabled = true

@tool
extends MarginContainer

@onready var editor = $VB/ModeContainer/Editor
@onready var _preview = $VB/ModeContainer/Preview
@onready var _edit_button = $VB/HB/ModeSwitch/EditButton
@onready var _preview_button = $VB/HB/ModeSwitch/PreviewButton


func _show_hide(show, hide):
	show.visible = true
	hide.visible = false


func _on_preview_starting_preview():
	_edit_button.disabled = true


func _on_preview_stopping_preview():
	_edit_button.disabled = false


func _on_preview_button_toggled(button_pressed):
	_edit_button.set_pressed_no_signal(false)
	_preview_button.set_pressed_no_signal(true)
	_show_hide(_preview, editor)
	# TODO: Will it be expected to restart when switching modes?
	if button_pressed:
		_preview.prepare_to_preview_graph(editor.get_edited_graph())


func _on_edit_button_toggled(button_pressed):
	_preview_button.set_pressed_no_signal(false)
	_edit_button.set_pressed_no_signal(true)
	_preview.clear_variable_stores()
	_show_hide(editor, _preview)


func _on_editor_previewable():
	if is_instance_valid(_preview_button):
		_preview_button.disabled = false


func _on_editor_not_previewable():
	if is_instance_valid(_preview_button):
		_preview_button.disabled = true

@tool
extends EditorProperty


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType


signal remove_requested()


var ControlContainer := HBoxContainer.new()
var RemoveButton := Button.new()

var _updating := false


func _init(type: VariableType) -> void:
	var control
	match type:
		VariableType.TYPE_BOOL:
			control = CheckBox.new()
			control.text = "On"
			control.toggled.connect(_control_toggled)
		VariableType.TYPE_STRING:
			control = LineEdit.new()
			control.text_changed.connect(_control_text_changed)
		VariableType.TYPE_INT:
			control = EditorSpinSlider.new()
			control.step = 1.0
			control.allow_greater = true
			control.allow_lesser = true
			#control.min_value = -9223372036854775807
			#control.max_value = 9223372036854775807
			control.min_value = -1000
			control.max_value = 1000
			control.value_changed.connect(_control_int_value_changed)
		VariableType.TYPE_FLOAT:
			control = EditorSpinSlider.new()
			control.step = 0.0001
			control.allow_greater = true
			control.allow_lesser = true
			#control.min_value = -9223372036854775807
			#control.max_value = 9223372036854775807
			control.min_value = -1000
			control.max_value = 1000
			control.value_changed.connect(_control_float_value_changed)
	control.size_flags_horizontal = SIZE_EXPAND_FILL
	ControlContainer.add_child(control)
	RemoveButton.text = ""
	RemoveButton.icon = preload("res://addons/hyh.cutscene_graph/icons/icon_close.svg")
	RemoveButton.pressed.connect(_remove_button_pressed)
	ControlContainer.add_child(RemoveButton)
	add_child(ControlContainer)


func _control_toggled(toggled_on: bool) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), toggled_on, "", true)


func _control_text_changed(new_text: String) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), new_text, "", true)


func _control_int_value_changed(new_value: float) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), int(new_value), "", true)


func _control_float_value_changed(new_value: float) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), new_value, "", true)


func _update_property() -> void:
	var obj = get_edited_object()
	var current_value = obj.get(get_edited_property())
	
	_updating = true
	var control = ControlContainer.get_child(0)
	match typeof(current_value):
		TYPE_BOOL:
			control.button_pressed = current_value
		TYPE_INT, TYPE_FLOAT:
			control.value = current_value
		TYPE_STRING, TYPE_STRING_NAME:
			control.text = current_value
	_updating = false


func _remove_button_pressed() -> void:
	remove_requested.emit()

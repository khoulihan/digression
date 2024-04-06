@tool
extends EditorProperty
## Custom editor property for custom properties that can be attached to
## several types of resources that are edited in the inspector.
## The difference from the built-in editor is that this one adds a
## remove button.


signal remove_requested()

const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType

var _control_container := HBoxContainer.new()
var _remove_button := Button.new()
var _updating := false


func _init(type: VariableType) -> void:
	var control
	match type:
		VariableType.TYPE_BOOL:
			control = CheckBox.new()
			control.text = "On"
			control.toggled.connect(_on_control_toggled)
		VariableType.TYPE_STRING:
			control = LineEdit.new()
			control.text_changed.connect(_on_control_text_changed)
		VariableType.TYPE_INT:
			control = EditorSpinSlider.new()
			control.step = 1.0
			control.allow_greater = true
			control.allow_lesser = true
			control.min_value = -1000
			control.max_value = 1000
			control.value_changed.connect(_on_control_int_value_changed)
		VariableType.TYPE_FLOAT:
			control = EditorSpinSlider.new()
			control.step = 0.0001
			control.allow_greater = true
			control.allow_lesser = true
			control.min_value = -1000
			control.max_value = 1000
			control.value_changed.connect(_on_control_float_value_changed)
	control.size_flags_horizontal = SIZE_EXPAND_FILL
	_control_container.add_child(control)
	_remove_button.text = ""
	_remove_button.icon = preload("../../../icons/icon_close.svg")
	_remove_button.pressed.connect(_on_remove_button_pressed)
	_control_container.add_child(_remove_button)
	add_child(_control_container)


func _update_property() -> void:
	var obj = get_edited_object()
	var current_value = obj.get(get_edited_property())
	
	_updating = true
	var control = _control_container.get_child(0)
	match typeof(current_value):
		TYPE_BOOL:
			control.button_pressed = current_value
		TYPE_INT, TYPE_FLOAT:
			control.value = current_value
		TYPE_STRING, TYPE_STRING_NAME:
			control.text = current_value
	_updating = false


func _on_control_toggled(toggled_on: bool) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), toggled_on, "", true)


func _on_control_text_changed(new_text: String) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), new_text, "", true)


func _on_control_int_value_changed(new_value: float) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), int(new_value), "", true)


func _on_control_float_value_changed(new_value: float) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), new_value, "", true)


func _on_remove_button_pressed() -> void:
	remove_requested.emit()

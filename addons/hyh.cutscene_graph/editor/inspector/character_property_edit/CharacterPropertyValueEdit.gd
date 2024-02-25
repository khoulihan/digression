@tool
extends EditorProperty


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType


var ControlContainer := MarginContainer.new()
var LineEditControl := LineEdit.new()
var SpinBoxControl := SpinBox.new()
var CheckBoxControl := CheckBox.new()
var LabelControl := Label.new()


var _current_type = null
var _current_value = null
var _updating := false


func _init() -> void:
	ControlContainer.add_child(LineEditControl)
	ControlContainer.add_child(SpinBoxControl)
	ControlContainer.add_child(CheckBoxControl)
	ControlContainer.add_child(LabelControl)
	add_child(ControlContainer)
	add_focusable(ControlContainer)
	add_focusable(LineEditControl)
	add_focusable(SpinBoxControl)
	add_focusable(CheckBoxControl)
	LineEditControl.visible = false
	SpinBoxControl.visible = false
	CheckBoxControl.visible = false
	LabelControl.text = "Select a property"
	LineEditControl.text_changed.connect(_line_edit_text_changed)
	SpinBoxControl.value_changed.connect(_spin_box_value_changed)
	CheckBoxControl.toggled.connect(_check_box_toggled)


func _line_edit_text_changed(new_text):
	if _updating:
		return
	emit_changed("value", new_text, "", true)


func _spin_box_value_changed(new_value):
	if _updating:
		return
	if _current_type == VariableType.TYPE_INT:
		emit_changed("value", int(new_value), "", true)
		return
	emit_changed("value", new_value, "", true)


func _check_box_toggled(toggled_on):
	if _updating:
		return
	emit_changed("value", toggled_on, "", true)


func _update_property() -> void:
	var obj = get_edited_object()
	var type_changed: bool = not _current_type == obj['type']
	var modified: bool = type_changed
	if not modified:
		modified = typeof(_current_value) != typeof(obj['value'])
		if not modified:
			modified = _current_value != obj['value']
	if modified:
		_updating = true
		_current_type = obj['type']
		_current_value = obj['value']
		_configure(type_changed)
		_updating = false


func _configure(type_changed: bool) -> void:
	if _current_type == null:
		LabelControl.visible = true
	else:
		if type_changed:
			LineEditControl.visible = _current_type == VariableType.TYPE_STRING
			SpinBoxControl.visible = _current_type == VariableType.TYPE_INT or _current_type == VariableType.TYPE_FLOAT
			CheckBoxControl.visible = _current_type == VariableType.TYPE_BOOL
			LabelControl.visible = false
		match _current_type:
			VariableType.TYPE_BOOL:
				if CheckBoxControl.button_pressed != _coerce(_current_value, VariableType.TYPE_BOOL):
					CheckBoxControl.button_pressed = _coerce(_current_value, VariableType.TYPE_BOOL)
			VariableType.TYPE_STRING:
				if LineEditControl.text != _coerce(_current_value, VariableType.TYPE_STRING):
					LineEditControl.text = _coerce(_current_value, VariableType.TYPE_STRING)
			VariableType.TYPE_INT:
				if type_changed:
					SpinBoxControl.rounded = true
					SpinBoxControl.step = 1
				if SpinBoxControl.value != _coerce(_current_value, VariableType.TYPE_INT):
					SpinBoxControl.value = _coerce(_current_value, VariableType.TYPE_INT)
			VariableType.TYPE_FLOAT:
				if type_changed:
					SpinBoxControl.rounded = false
					SpinBoxControl.step = 0.0001
				if SpinBoxControl.value != _coerce(_current_value, VariableType.TYPE_FLOAT):
					SpinBoxControl.value = _coerce(_current_value, VariableType.TYPE_FLOAT)


func _coerce(value: Variant, type: VariableType) -> Variant:
	match type:
		VariableType.TYPE_BOOL:
			if typeof(value) == TYPE_BOOL:
				return value
			# This may no longer be required - for a while I thought there
			# was a problem with saving booleans.
			if typeof(value) == TYPE_INT:
				return value == 1
			return false
		VariableType.TYPE_INT:
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				return int(value)
			return 0
		VariableType.TYPE_FLOAT:
			if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_FLOAT:
				return float(value)
			return 0.0
		VariableType.TYPE_STRING:
			return str(value)
	return null

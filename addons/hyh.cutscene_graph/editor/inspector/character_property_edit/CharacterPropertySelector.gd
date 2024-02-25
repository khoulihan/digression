@tool
extends EditorProperty


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType


var ControlContainer := MarginContainer.new()
var LabelControl := Label.new()
var SelectButton := Button.new()


var _current_values = []
var _updating := false


func _init() -> void:
	ControlContainer.add_child(LabelControl)
	ControlContainer.add_child(SelectButton)
	add_child(ControlContainer)
	add_focusable(ControlContainer)
	add_focusable(SelectButton)
	LabelControl.visible = false
	SelectButton.text = "Select"
	SelectButton.pressed.connect(_select_button_pressed)


func _select_button_pressed() -> void:
	if _updating:
		return
	
	LabelControl.text = "test_property"
	LabelControl.visible = true
	SelectButton.visible = false
	_current_values = ["test_property", VariableType.TYPE_STRING]
	var obj = get_edited_object()
	obj["resource_name"] = "test_property"
	match _current_values[1]:
		VariableType.TYPE_STRING:
			obj['value'] = ""
		VariableType.TYPE_BOOL:
			obj['value'] = false
		VariableType.TYPE_INT:
			obj['value'] = 0
		VariableType.TYPE_FLOAT:
			obj['value'] = 0.0
	# Third argument here is not documented, meaning unknown
	multiple_properties_changed.emit(
		["property", "type", "value", "resource_name"],
		["test_property", VariableType.TYPE_STRING, obj['value'], "test_property"],
		true,
	)
	emit_changed(get_edited_property(), "test_property")


func _update_property() -> void:
	print ("Property updated")
	var obj = get_edited_object()
	var modified := len(_current_values) == 0
	if not modified:
		modified = not _current_values[0] == obj['property']
	if modified:
		_updating = true
		_current_values = [obj['property'], obj['type']]
		if _current_values[0].is_empty():
			LabelControl.visible = false
			SelectButton.visible = true
		else:
			LabelControl.text = _current_values[0]
			LabelControl.visible = true
			SelectButton.visible = false
		_updating = false
	

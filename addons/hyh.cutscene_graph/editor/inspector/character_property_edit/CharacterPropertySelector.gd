@tool
extends EditorProperty


const PropertySelectDialog = preload("../../property_select_dialog/PropertySelectDialog.tscn")
const PropertySelectDialogClass = preload("../../property_select_dialog/PropertySelectDialog.gd")

const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const PropertyUse = PropertySelectDialogClass.PropertyUse


var ControlContainer := MarginContainer.new()
var LabelControl := Label.new()
var SelectButton := Button.new()


var use_restriction: PropertyUse = PropertyUse.CHARACTERS
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
	
	var dialog := PropertySelectDialog.instantiate()
	dialog.use_restriction = use_restriction
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.cancelled.connect(_property_select_dialog_cancelled.bind(dialog))
	dialog.selected.connect(_property_select_dialog_selected.bind(dialog))
	get_tree().root.add_child(dialog)
	dialog.popup()


func _property_select_dialog_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _property_select_dialog_selected(property, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	
	LabelControl.text = property['name']
	LabelControl.visible = true
	SelectButton.visible = false
	_current_values = [property['name'], VariableType.TYPE_STRING]
	var obj = get_edited_object()
	obj["resource_name"] = property['name']
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
		[property['name'], property['type'], obj['value'], property['name']],
		true,
	)
	emit_changed(get_edited_property(), property['name'])


func _update_property() -> void:
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
	

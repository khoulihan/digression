@tool
extends MarginContainer
## Control for a branch in a Match Branch node.


signal remove_requested()
signal modified()
signal preparing_to_change_parent()
signal dropped_after(section)


const Logging = preload("../../utility/Logging.gd")
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const MatchBranch = preload("../../resources/graph/branches/MatchBranch.gd")
const DragVariableTypeRestriction = preload("../controls/drag/DragHandle.gd").DragVariableTypeRestriction

var _logger := Logging.new(
	Logging.DGE_EDITOR_LOG_NAME,
	Logging.DGE_EDITOR_LOG_LEVEL
)
var _type: VariableType
var _branch_resource: MatchBranch

@onready var _value_edit = $VB/HorizontalLayout/GridContainer/ValueEdit
@onready var _drag_target = $VB/DragTargetHSeparator
@onready var _drag_handle = $VB/HorizontalLayout/DragHandle


func _ready() -> void:
	if _type != null:
		_value_edit.set_variable_type(_type)


## Set the type of the variable involved with the parent node.
func set_type(t: VariableType) -> void:
	_type = t
	if _value_edit != null:
		_value_edit.set_variable_type(t)
	if _drag_target != null:
		_drag_target.update_accepted_type_restriction(
			_map_type_restriction(t)
		)
	if _drag_handle != null:
		_drag_handle.type_restriction = _map_type_restriction(t)


## Set the current value to match.
func set_value(val: Variant) -> void:
	if val != null:
		if typeof(val) == TYPE_DICTIONARY:
			_value_edit.set_variable(val, true)
		else:
			_value_edit.set_value(val)


## Get the current value from the UI.
func get_value() -> Variant:
	if _value_edit.is_selecting_variable():
		return _value_edit.get_selected_variable()
	return _value_edit.get_value()


## Get the branch resource updated with the current values.
func get_branch() -> MatchBranch:
	_branch_resource.value = get_value()
	return _branch_resource


## Assign a branch resource to the UI.
func set_branch(branch: MatchBranch) -> void:
	_branch_resource = branch
	set_value(_branch_resource.value)


func prepare_to_change_parent():
	preparing_to_change_parent.emit()


func _map_type_restriction(vartype: VariableType) -> DragVariableTypeRestriction:
	match (vartype):
		VariableType.TYPE_BOOL:
			return DragVariableTypeRestriction.BOOL
		VariableType.TYPE_INT:
			return DragVariableTypeRestriction.INT
		VariableType.TYPE_FLOAT:
			return DragVariableTypeRestriction.FLOAT
		VariableType.TYPE_STRING:
			return DragVariableTypeRestriction.STRING
		_:
			return DragVariableTypeRestriction.NONE


func _on_remove_button_pressed() -> void:
	remove_requested.emit()


func _on_value_edit_value_changed() -> void:
	modified.emit()


func _on_drag_target_dropped(arg: Variant, at_position: Variant) -> void:
	dropped_after.emit(arg)

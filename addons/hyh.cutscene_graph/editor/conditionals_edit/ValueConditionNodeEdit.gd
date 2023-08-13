@tool
extends VBoxContainer


const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const ComparisonType = preload("../../resources/graph/branches/conditions/comparisons/ComparisonBase.gd").ComparisonType
const SetConditionEdit = preload("SetConditionEdit.tscn")


# Header controls
@onready var VariableSelectionControl = get_node("ValueNodeHeader/VariableNameContainer/VariableSelectionControl")
@onready var VariableValidationWarning = get_node("ValueNodeHeader/VariableNameContainer/VariableValidationWarning")
@onready var ComparisonTypeOption = get_node("ValueNodeHeader/ComparisonTypeOption")

# Value controls
# TODO: I made these into their own scenes apparently, but they are not instantiated as such
@onready var SingleValueEditContainer = get_node("MarginContainer/SingleValueEdit")
@onready var SingleVariableValueEdit = get_node("MarginContainer/SingleValueEdit/VariableValueEdit")
@onready var RangeEditContainer = get_node("MarginContainer/RangeEdit")
@onready var RangeMinValueEdit = get_node("MarginContainer/RangeEdit/MinValueEdit")
@onready var RangeMaxValueEdit = get_node("MarginContainer/RangeEdit/MaxValueEdit")
@onready var SetEditContainer = get_node("MarginContainer/SetEdit")
@onready var SetConditionContainer = get_node("MarginContainer/SetEdit/ScrollContainer/PanelContainer/SetConditionContainer")


signal value_modified(
	variable_name,
	variable_type,
	scope,
	comparison_type,
	value,
	min_value,
	max_value,
	value_set,
	is_valid,
	validation_text
)


var is_valid
var validation_text

var _current_variable


func edit_value(
	variable_name,
	variable_type,
	scope,
	comparison_type,
	value,
	min_value,
	max_value,
	value_set
):
	VariableSelectionControl.clear()
	# We need to track the current variable because the selection control
	# doesn't do it. Since we don't receive a dictionary here we need to
	# create a "fake" one. We don't need the tags or description.
	_current_variable = null
	if variable_name != null and not variable_name.is_empty():
		_current_variable = {
			'name': variable_name,
			'scope': scope,
			'type': variable_type,
		}
		VariableSelectionControl.configure_for_variable(
			variable_name,
			scope,
			variable_type
		)
	ComparisonTypeOption.selected = ComparisonTypeOption.get_item_index(comparison_type)
	if variable_name != null and not variable_name.is_empty():
		_configure_value_containers(
			comparison_type,
			variable_type,
			value,
			min_value,
			max_value,
			value_set
		)
	else:
		_clear_values()
		_hide_value_containers()
	_validate()
	_notify_value_modified()


func _set_value_container_visibility(comparison_type):
	if _current_variable == null:
		_hide_value_containers()
		return
	RangeEditContainer.visible = (comparison_type == ComparisonType.RANGE)
	SetEditContainer.visible = (comparison_type == ComparisonType.SET)
	SingleValueEditContainer.visible = (
		comparison_type != ComparisonType.RANGE and
		comparison_type != ComparisonType.SET
	)


func _hide_value_containers():
	RangeEditContainer.visible = false
	SetEditContainer.visible = false
	SingleValueEditContainer.visible = false


func _clear_values():
	RangeMinValueEdit.clear_values()
	RangeMaxValueEdit.clear_values()
	SingleVariableValueEdit.clear_values()


func _configure_value_containers(
	comparison_type,
	variable_type,
	value,
	min_value,
	max_value,
	value_set
):
	_set_value_container_visibility(comparison_type)
	_configure_value_edit_types(variable_type)
	_set_value_edit_values(
		value,
		min_value,
		max_value,
		value_set
	)
	# TODO: Deal with sets


func _configure_value_edit_types(variable_type):
	SingleVariableValueEdit.variable_type = variable_type
	RangeMinValueEdit.variable_type = variable_type
	RangeMaxValueEdit.variable_type = variable_type
	# TODO: Deal with sets


func _set_value_edit_values(
	value,
	min_value,
	max_value,
	value_set
):
	SingleVariableValueEdit.set_value(value)
	RangeMinValueEdit.set_value(min_value)
	RangeMaxValueEdit.set_value(max_value)
	# TODO: Deal with sets


func _validate():
	is_valid = true
	validation_text = ""
	
	if _current_variable == null:
		is_valid = false
		VariableValidationWarning.tooltip_text = "Variable is required."
		VariableValidationWarning.visible = true
	else:
		VariableValidationWarning.visible = false
	
	if not is_valid:
		validation_text = "The state of this comparison is not valid."


func _notify_value_modified():
	var variable_name
	var scope
	var variable_type
	if _current_variable != null:
		variable_name = _current_variable['name']
		scope = _current_variable['scope']
		variable_type = _current_variable['type']
	value_modified.emit(
		variable_name,
		variable_type,
		scope,
		ComparisonTypeOption.get_selected_id(),
		SingleVariableValueEdit.get_value(),
		RangeMinValueEdit.get_value(),
		RangeMaxValueEdit.get_value(),
		[], # TODO: Deal with sets
		is_valid,
		validation_text
	)


func _on_variable_scope_option_item_selected(index):
	_notify_value_modified()


func _on_variable_name_edit_text_changed(value):
	Logger.debug("Variable name changed")
	_validate()
	_notify_value_modified()


func _variable_type_changed(variable_type):
	# TODO: This imposes constraints on the comparison types
	# Booleans can only be "equals"
	# Other types are not restricted I guess
	# TODO: Also changing the type will seem to "wipe out" any entered values
	if variable_type == VariableType.TYPE_BOOL:
		ComparisonTypeOption.selected = ComparisonTypeOption.get_item_index(
			ComparisonType.EQUALS
		)
		for option_id in range(ComparisonType.GREATER_THAN, ComparisonType.SET + 1):
			ComparisonTypeOption.set_item_disabled(
				ComparisonTypeOption.get_item_index(option_id), 
				true
			)
	else:
		for option_id in range(ComparisonType.GREATER_THAN, ComparisonType.SET + 1):
			ComparisonTypeOption.set_item_disabled(
				ComparisonTypeOption.get_item_index(option_id),
				false
			)
	_set_value_container_visibility(ComparisonTypeOption.selected)
	_configure_value_edit_types(
		variable_type
	)
	_validate()
	_notify_value_modified()


func _on_comparison_type_option_item_selected(index):
	# TODO: Changing the comparison type will sometimes appear to "wipe out"
	# values already entered e.g. switching between "equals" and "range"
	_set_value_container_visibility(index)
	_validate()
	_notify_value_modified()


func _on_single_value_edit_value_changed():
	_validate()
	_notify_value_modified()


func _on_min_value_edit_value_changed():
	_validate()
	_notify_value_modified()


func _on_max_value_edit_value_changed():
	_validate()
	_notify_value_modified()


func _on_add_set_value_button_pressed():
	# TODO: Deal with sets
	_validate()
	_notify_value_modified()


func _on_variable_selection_control_variable_selected(variable):
	_current_variable = variable
	_variable_type_changed(_current_variable['type'])
	_validate()
	_notify_value_modified()

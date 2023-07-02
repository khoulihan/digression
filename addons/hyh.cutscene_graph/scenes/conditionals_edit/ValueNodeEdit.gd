@tool
extends VBoxContainer


const Logging = preload("../../scripts/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


const VariableType = preload("../../resources/VariableSetNode.gd").VariableType
const VariableScope = preload("../../resources/VariableSetNode.gd").VariableScope
const ComparisonType = preload("../../resources/conditions/comparisons/ComparisonBase.gd").ComparisonType
const SetConditionEdit = preload("SetConditionEdit.tscn")


# Header controls
@onready var VariableScopeOption = get_node("ValueNodeHeader/VariableScopeOption")
@onready var VariableNameEdit = get_node("ValueNodeHeader/VariableNameContainer/VariableNameEdit")
@onready var VariableNameValidationWarning = get_node("ValueNodeHeader/VariableNameContainer/VariableNameValidationWarning")
@onready var VariableTypeOption = get_node("ValueNodeHeader/VariableTypeContainer/VariableTypeOption")
@onready var VariableTypeValidationWarning = get_node("ValueNodeHeader/VariableTypeContainer/VariableTypeValidationWarning")
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
	VariableNameEdit.text = variable_name
	VariableTypeOption.selected = VariableTypeOption.get_item_index(variable_type)
	VariableScopeOption.selected = VariableScopeOption.get_item_index(scope)
	ComparisonTypeOption.selected = ComparisonTypeOption.get_item_index(comparison_type)
	_configure_value_containers(
		comparison_type,
		variable_type,
		value,
		min_value,
		max_value,
		value_set
	)
	_validate()
	_notify_value_modified()


func _set_value_container_visibility(comparison_type):
	RangeEditContainer.visible = (comparison_type == ComparisonType.RANGE)
	SetEditContainer.visible = (comparison_type == ComparisonType.SET)
	SingleValueEditContainer.visible = (
		comparison_type != ComparisonType.RANGE and
		comparison_type != ComparisonType.SET
	)


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
	
	if VariableNameEdit.text == "":
		is_valid = false
		VariableNameValidationWarning.tooltip_text = "Variable name is required."
		VariableNameValidationWarning.visible = true
	else:
		VariableNameValidationWarning.visible = false
	
	if VariableTypeOption.selected == -1:
		is_valid = false
		VariableTypeValidationWarning.tooltip_text = "Variable type is required."
		VariableTypeValidationWarning.visible = true
	else:
		VariableTypeValidationWarning.visible = false
	
	if not is_valid:
		validation_text = "The state of this comparison is not valid."


func _notify_value_modified():
	value_modified.emit(
		VariableNameEdit.text,
		VariableTypeOption.get_selected_id(),
		VariableScopeOption.get_selected_id(),
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


func _on_variable_type_option_item_selected(index):
	# TODO: This imposes constraints on the comparison types
	# Booleans can only be "equals"
	# Other types are not restricted I guess
	# TODO: Also changing the type will seem to "wipe out" any entered values
	if VariableTypeOption.get_item_id(index) == VariableType.TYPE_BOOL:
		ComparisonTypeOption.selected = ComparisonTypeOption.get_item_index(
			ComparisonType.EQUALS
		)
		_set_value_container_visibility(index)
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
	_configure_value_edit_types(
		VariableTypeOption.get_item_id(index)
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

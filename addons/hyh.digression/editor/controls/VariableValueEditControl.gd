@tool
extends MarginContainer
## A control for defining a value - either a constant or a variable to be
## evaluated at runtime.


signal value_changed()

# Another possible type might be determined by user code...
enum ValueSelectionMode {
	CONSTANT,
	VARIABLE,
	BOTH
}

const Logging = preload("../../utility/Logging.gd")
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

# TODO: Setting this in the inspector does not work because the controls are not
# ready when it is set at runtime (might have fixed this now, need to test)
## The type of the value to edit.
@export var variable_type: VariableType = VariableType.TYPE_BOOL:
	get:
		return variable_type
	set(t):
		variable_type = t
		if is_node_ready():
			_configure()

## The selection mode.
## The control can allow a constant value to be entered, a variable to be
## selected, or both.
@export var mode: ValueSelectionMode = ValueSelectionMode.BOTH:
	get:
		return mode
	set(t):
		mode = t
		if is_node_ready():
			_configure()

var _logger = Logging.new(
	Logging.DGE_EDITOR_LOG_NAME,
	Logging.DGE_EDITOR_LOG_LEVEL
)
var _selecting_variable: bool = false
var _selected_variable

@onready var _variable_check_button = $HB/VariableCheckButton
@onready var _edit_container = $HB/SelectionContainer/EditContainer
@onready var _line_edit_control = $HB/SelectionContainer/EditContainer/LineEdit
@onready var _spin_box_control = $HB/SelectionContainer/EditContainer/SpinBox
@onready var _check_box_control = $HB/SelectionContainer/EditContainer/CheckBox
@onready var _variable_selection_control = $HB/SelectionContainer/VariableSelectionControl
@onready var _validation_warning = $HB/ValidationWarning


func _ready():
	_configure()
	clear_validation_warning()


## Set the variable type
func set_variable_type(t):
	variable_type = t
	# TODO: Seems redundant... The property set does this.
	_configure()


## Clear the values of all edit controls.
func clear_values():
	_check_box_control.button_pressed = true
	_line_edit_control.text = ""
	_spin_box_control.value = 0


## Set the edited constant value.
func set_value(val):
	_selecting_variable = false
	clear_values()
	match variable_type:
		VariableType.TYPE_BOOL:
			if val == null:
				_check_box_control.button_pressed = true
			else:
				_check_box_control.button_pressed = val
		VariableType.TYPE_STRING:
			if val == null:
				_line_edit_control.text = ""
			else:
				_line_edit_control.text = val
		VariableType.TYPE_INT, VariableType.TYPE_FLOAT:
			if val == null:
				_spin_box_control.value = 0
			else:
				_spin_box_control.value = val
	_configure()


## Get the edited constant value.
func get_value():
	match variable_type:
		VariableType.TYPE_BOOL:
			return _check_box_control.button_pressed
		VariableType.TYPE_STRING:
			return _line_edit_control.text
		VariableType.TYPE_INT:
			return _spin_box_control.value as int
		VariableType.TYPE_FLOAT:
			return _spin_box_control.value as float


## Whether the control is currently selecting a variable (as opposed to editing
## a constant).
func is_selecting_variable():
	return _selecting_variable


## Get the selected variable, if possible.
func get_selected_variable():
	if _selecting_variable:
		return _selected_variable
	return null


## Sets the selected variable.
func set_variable(variable, deserialising=false):
	_selecting_variable = true
	_selected_variable = variable
	_variable_selection_control.configure_for_variable(
		variable["name"],
		variable["scope"],
		variable["type"],
	)
	_configure()
	if not deserialising:
		value_changed.emit()


## Sets a validation warning on the control.
func set_validation_warning(t):
	_validation_warning.set_warning(t)


## Clears the validation warning on the control.
func clear_validation_warning():
	_validation_warning.clear_warning()


func _configure():
	var show_variable_selection = _selecting_variable or mode == ValueSelectionMode.VARIABLE
	_variable_selection_control.set_type_restriction(variable_type)
	_variable_selection_control.visible = show_variable_selection
	_variable_check_button.visible = mode == ValueSelectionMode.BOTH
	_edit_container.visible = not show_variable_selection
	_line_edit_control.visible = variable_type == VariableType.TYPE_STRING
	_spin_box_control.visible = variable_type == VariableType.TYPE_INT or variable_type == VariableType.TYPE_FLOAT
	_check_box_control.visible = variable_type == VariableType.TYPE_BOOL
	if variable_type == VariableType.TYPE_INT or variable_type == VariableType.TYPE_FLOAT:
		_spin_box_control.rounded = (variable_type == VariableType.TYPE_INT)
		if variable_type == VariableType.TYPE_INT:
			_spin_box_control.step = 1
			_spin_box_control.value = _spin_box_control.value as int
		else:
			_spin_box_control.step = 0.0001


func _on_check_box_pressed():
	value_changed.emit()


func _on_spin_box_value_changed(value):
	value_changed.emit()


func _on_line_edit_text_changed(new_text):
	value_changed.emit()


func _on_spin_box_changed():
	value_changed.emit()


func _on_variable_check_button_toggled(button_pressed):
	_selecting_variable = button_pressed
	_configure()
	value_changed.emit()


func _on_variable_selection_control_variable_selected(variable):
	_selected_variable = variable
	value_changed.emit()

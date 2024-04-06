@tool
extends HBoxContainer
## A control for selecting a pre-defined variable.


signal variable_selected(variable)

enum PopupMenuItems {
	SELECT,
	NEW_VARIABLE,
}

const WARNING_ICON = preload("../../icons/icon_node_warning.svg")
const ADD_ICON = preload("../../icons/icon_add.svg")
const BOOL_ICON = preload("../../icons/icon_type_bool.svg")
const INT_ICON = preload("../../icons/icon_type_int.svg")
const FLOAT_ICON = preload("../../icons/icon_type_float.svg")
const STRING_ICON = preload("../../icons/icon_type_string.svg")
const TRANSIENT_ICON = preload("../../icons/icon_scope_transient.svg")
const DIALOGUE_GRAPH_SCOPE_ICON = preload("../../icons/icon_scope_dialogue_graph.svg")
const LOCAL_ICON = preload("../../icons/icon_scope_local.svg")
const GLOBAL_ICON = preload("../../icons/icon_scope_global.svg")

const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

const VariableSelectDialog = preload("../dialogs/variable_select_dialog/VariableSelectDialog.tscn")
const VariableCreateDialog = preload("../dialogs/variable_create_dialog/VariableCreateDialog.tscn")

var _popup: PopupMenu
var _type_restriction = null
var _variable: Dictionary

@onready var _scope_margin_container: MarginContainer = $ScopeMarginContainer
@onready var _scope_icon: TextureRect = $ScopeMarginContainer/ScopeIcon
@onready var _type_margin_container: MarginContainer = $TypeMarginContainer
@onready var _type_icon: TextureRect = $TypeMarginContainer/TypeIcon
@onready var _selection_name: LineEdit = $SelectionName
@onready var _variable_menu_button: MenuButton = $MenuButton




# Called when the node enters the scene tree for the first time.
func _ready():
	_scope_icon.texture = null
	_type_icon.texture = null
	_scope_margin_container.hide()
	_type_margin_container.hide()
	_popup = _variable_menu_button.get_popup()
	_popup.index_pressed.connect(_on_popup_index_pressed)


## Set the type restriction.
func set_type_restriction(t):
	_type_restriction = t


## Clear the type restriction.
func clear_type_restriction():
	_type_restriction = null


## Configure the control for the specified variable.
func configure_for_variable(
	name,
	scope,
	variable_type,
):
	_scope_icon.texture = _icon_for_scope(scope)
	_scope_margin_container.show()
	_type_icon.texture = _icon_for_type(variable_type)
	_type_margin_container.show()
	_selection_name.text = name


## Set the selected variable.
func set_variable(variable):
	_variable = variable
	if _variable == null or len(_variable) == 0:
		clear()
	else:
		configure_for_variable(
			_variable['name'],
			_variable['scope'],
			_variable['type'],
		)


## Get the selected variable.
func get_variable():
	return _variable


## Clear the selected variable.
func clear():
	_variable = {}
	_scope_margin_container.hide()
	_type_margin_container.hide()
	_selection_name.text = ""


func _icon_for_type(t):
	match t:
		VariableType.TYPE_BOOL:
			return BOOL_ICON
		VariableType.TYPE_INT:
			return INT_ICON
		VariableType.TYPE_FLOAT:
			return FLOAT_ICON
		VariableType.TYPE_STRING:
			return STRING_ICON
	return WARNING_ICON


func _icon_for_scope(s):
	match s:
		VariableScope.SCOPE_TRANSIENT:
			return TRANSIENT_ICON
		VariableScope.SCOPE_DIALOGUE_GRAPH:
			return DIALOGUE_GRAPH_SCOPE_ICON
		VariableScope.SCOPE_LOCAL:
			return LOCAL_ICON
		VariableScope.SCOPE_GLOBAL:
			return GLOBAL_ICON
	return WARNING_ICON


func _convert_position(pos):
	return get_screen_transform() * pos


func _show_selection_dialog():
	var dialog = VariableSelectDialog.instantiate()
	dialog.type_restriction = _type_restriction
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.selected.connect(_on_select_dialog_variable_selected.bind(dialog))
	dialog.cancelled.connect(_on_select_dialog_cancelled.bind(dialog))
	get_tree().root.add_child(dialog)
	dialog.popup()


func _on_selection_name_gui_input(event):
	_on_control_gui_input(_selection_name, event)


func _on_control_gui_input(control, event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_popup.position = _convert_position(
				control.position + Vector2(0, control.size.y)
			)
			_popup.popup(Rect2(_popup.position, Vector2(control.size.x, 0)))


func _on_scope_margin_container_gui_input(event):
	_on_control_gui_input(_scope_margin_container, event)


func _on_type_margin_container_gui_input(event):
	_on_control_gui_input(_type_margin_container, event)


func _on_select_dialog_variable_selected(variable, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	_variable = variable
	configure_for_variable(
		variable['name'],
		variable['scope'],
		variable['type'],
	)
	variable_selected.emit(variable)


func _on_select_dialog_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _show_create_dialog():
	var dialog = VariableCreateDialog.instantiate()
	dialog.type_restriction = _type_restriction
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.created.connect(_on_variable_created.bind(dialog))
	dialog.cancelled.connect(_on_create_dialog_cancelled.bind(dialog))
	get_tree().root.add_child(dialog)
	dialog.popup()


func _on_variable_created(variable, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	_variable = variable
	configure_for_variable(
		variable['name'],
		variable['scope'],
		variable['type'],
	)
	variable_selected.emit(variable)


func _on_create_dialog_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _on_popup_index_pressed(index):
	match index:
		PopupMenuItems.SELECT:
			_show_selection_dialog()
		PopupMenuItems.NEW_VARIABLE:
			_show_create_dialog()

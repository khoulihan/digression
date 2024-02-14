@tool
extends HBoxContainer

const WarningIcon = preload("../../icons/icon_node_warning.svg")
const AddIcon = preload("../../icons/icon_add.svg")

const BoolIcon = preload("../../icons/icon_type_bool.svg")
const IntIcon = preload("../../icons/icon_type_int.svg")
const FloatIcon = preload("../../icons/icon_type_float.svg")
const StringIcon = preload("../../icons/icon_type_string.svg")

const TransientIcon = preload("../../icons/icon_scope_transient.svg")
const CutsceneScopeIcon = preload("../../icons/icon_scope_cutscene.svg")
const LocalIcon = preload("../../icons/icon_scope_local.svg")
const GlobalIcon = preload("../../icons/icon_scope_global.svg")

const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType

const VariableSelectDialog = preload("../variable_select_dialog/VariableSelectDialog.tscn")
const VariableCreateDialog = preload("../variable_create_dialog/VariableCreateDialog.tscn")

enum PopupMenuItems {
	SELECT,
	NEW_VARIABLE,
}

signal variable_selected(variable)


@onready var ScopeMarginContainer: MarginContainer = get_node("ScopeMarginContainer")
@onready var ScopeIcon: TextureRect = get_node("ScopeMarginContainer/ScopeIcon")
@onready var TypeMarginContainer: MarginContainer = get_node("TypeMarginContainer")
@onready var TypeIcon: TextureRect = get_node("TypeMarginContainer/TypeIcon")
@onready var SelectionName: LineEdit = get_node("SelectionName")
@onready var VariableMenuButton: MenuButton = get_node("MenuButton")

var _popup: PopupMenu

var _type_restriction = null

var _variable: Dictionary

func _create_example_variable(
	name,
	scope,
	variable_type,
):
	return {
		"name": name,
		"scope": scope,
		"type": variable_type,
	}

# Called when the node enters the scene tree for the first time.
func _ready():
	ScopeIcon.texture = null
	TypeIcon.texture = null
	ScopeMarginContainer.hide()
	TypeMarginContainer.hide()
	_popup = VariableMenuButton.get_popup()
	_popup.index_pressed.connect(_popup_index_pressed)


func set_type_restriction(t):
	_type_restriction = t


func clear_type_restriction():
	_type_restriction = null


func configure_for_variable(
	name,
	scope,
	variable_type,
):
	ScopeIcon.texture = _icon_for_scope(scope)
	ScopeMarginContainer.show()
	TypeIcon.texture = _icon_for_type(variable_type)
	TypeMarginContainer.show()
	SelectionName.text = name


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
	


func get_variable():
	return _variable


func clear():
	_variable = {}
	ScopeMarginContainer.hide()
	TypeMarginContainer.hide()
	SelectionName.text = ""


func _icon_for_type(t):
	match t:
		VariableType.TYPE_BOOL:
			return BoolIcon
		VariableType.TYPE_INT:
			return IntIcon
		VariableType.TYPE_FLOAT:
			return FloatIcon
		VariableType.TYPE_STRING:
			return StringIcon
	return WarningIcon


func _icon_for_scope(s):
	match s:
		VariableScope.SCOPE_TRANSIENT:
			return TransientIcon
		VariableScope.SCOPE_CUTSCENE:
			return CutsceneScopeIcon
		VariableScope.SCOPE_LOCAL:
			return LocalIcon
		VariableScope.SCOPE_GLOBAL:
			return GlobalIcon
	return WarningIcon


func _convert_position(pos):
	return get_screen_transform() * pos


func _on_selection_name_gui_input(event):
	_on_control_gui_input(SelectionName, event)


func _on_control_gui_input(control, event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_popup.position = _convert_position(
				control.position + Vector2(0, control.size.y)
			)
			_popup.popup(Rect2(_popup.position, Vector2(control.size.x, 0)))


func _on_scope_margin_container_gui_input(event):
	_on_control_gui_input(ScopeMarginContainer, event)


func _on_type_margin_container_gui_input(event):
	_on_control_gui_input(TypeMarginContainer, event)


func _show_selection_dialog():
	var dialog = VariableSelectDialog.instantiate()
	dialog.type_restriction = _type_restriction
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	dialog.position = get_tree().root.position + Vector2i(200, 200)
	dialog.selected.connect(_variable_selected.bind(dialog))
	dialog.cancelled.connect(_select_dialog_cancelled.bind(dialog))
	get_tree().root.add_child(dialog)
	dialog.popup()


func _variable_selected(variable, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	_variable = variable
	configure_for_variable(
		variable['name'],
		variable['scope'],
		variable['type'],
	)
	variable_selected.emit(variable)


func _select_dialog_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _show_create_dialog():
	var dialog = VariableCreateDialog.instantiate()
	dialog.type_restriction = _type_restriction
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	dialog.position = get_tree().root.position + Vector2i(200, 200)
	dialog.created.connect(_variable_created.bind(dialog))
	dialog.cancelled.connect(_create_dialog_cancelled.bind(dialog))
	get_tree().root.add_child(dialog)
	dialog.popup()


func _variable_created(variable, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	_variable = variable
	configure_for_variable(
		variable['name'],
		variable['scope'],
		variable['type'],
	)
	variable_selected.emit(variable)


func _create_dialog_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _popup_index_pressed(index):
	match index:
		PopupMenuItems.SELECT:
			_show_selection_dialog()
		PopupMenuItems.NEW_VARIABLE:
			_show_create_dialog()

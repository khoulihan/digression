@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/Expression.gd"
## An expression that can be dragged.


signal remove_requested()

const BOOL_ICON = preload("res://addons/hyh.cutscene_graph/icons/icon_type_bool.svg")
const INT_ICON = preload("res://addons/hyh.cutscene_graph/icons/icon_type_int.svg")
const FLOAT_ICON = preload("res://addons/hyh.cutscene_graph/icons/icon_type_float.svg")
const STRING_ICON = preload("res://addons/hyh.cutscene_graph/icons/icon_type_string.svg")

@onready var _panel : PanelContainer = $PanelContainer
@onready var _expression_container : VBoxContainer = $PanelContainer/MC/ExpressionContainer
@onready var _header : HBoxContainer = $PanelContainer/MC/ExpressionContainer/Header
@onready var _drag_handle : TextureRect = $PanelContainer/MC/ExpressionContainer/Header/DragHandle
@onready var _title : Label = $PanelContainer/MC/ExpressionContainer/Header/Title
@onready var _remove_button = $PanelContainer/MC/ExpressionContainer/Header/RemoveButton
@onready var _validation_warning : TextureRect = $PanelContainer/MC/ExpressionContainer/Header/ValidationWarning


## Configure the expression.
func configure():
	super()
	_drag_handle.target = self
	_drag_handle.type = type
	_validation_warning.visible = false


## Set the title text and tooltip.
func set_title(text, tooltip):
	_title.text = text
	_title.tooltip_text = tooltip


## Get a control to serve as a drag preview.
func get_drag_preview():
	var preview = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.texture = _get_type_icon(type)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	var ptext = Label.new()
	# TODO: Maybe include the value for value expressions, function names for
	# functions?
	ptext.text = "%s Expression" % _get_type_name(type)
	preview.add_child(icon)
	preview.add_child(ptext)
	preview.modulate = Color.from_string("#FFFFFF88", Color.WHITE)
	return preview


func _on_remove_button_pressed():
	var confirm = ConfirmationDialog.new()
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.title = "Please confirm"
	confirm.dialog_text = "Are you sure you want to remove this expression? This action cannot be undone."
	confirm.canceled.connect(_on_remove_cancelled.bind(confirm))
	confirm.confirmed.connect(_on_remove_confirmed.bind(confirm))
	get_tree().root.add_child(confirm)
	confirm.show()


func _on_remove_confirmed(confirm):
	get_tree().root.remove_child(confirm)
	remove_requested.emit()


func _on_remove_cancelled(confirm):
	get_tree().root.remove_child(confirm)


func _get_type_icon(t):
	match type:
		VariableType.TYPE_BOOL:
			return BOOL_ICON
		VariableType.TYPE_INT:
			return INT_ICON
		VariableType.TYPE_FLOAT:
			return FLOAT_ICON
		VariableType.TYPE_STRING:
			return STRING_ICON


func _get_type_name(t):
	match type:
		VariableType.TYPE_BOOL:
			return "Boolean"
		VariableType.TYPE_INT:
			return "Integer"
		VariableType.TYPE_FLOAT:
			return "Float"
		VariableType.TYPE_STRING:
			return "String"

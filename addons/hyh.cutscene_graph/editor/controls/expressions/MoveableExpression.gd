@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/Expression.gd"


const BoolIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_type_bool.svg")
const IntIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_type_int.svg")
const FloatIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_type_float.svg")
const StringIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_type_string.svg")


signal remove_requested()


@onready var _panel : PanelContainer = get_node("PanelContainer")
@onready var _expression_container : VBoxContainer = get_node("PanelContainer/MC/ExpressionContainer")
@onready var _header : HBoxContainer = get_node("PanelContainer/MC/ExpressionContainer/Header")
@onready var _drag_handle : TextureRect = get_node("PanelContainer/MC/ExpressionContainer/Header/DragHandle")
@onready var _title : Label = get_node("PanelContainer/MC/ExpressionContainer/Header/Title")
@onready var _remove_button = get_node("PanelContainer/MC/ExpressionContainer/Header/RemoveButton")
@onready var _validation_warning : TextureRect = get_node("PanelContainer/MC/ExpressionContainer/Header/ValidationWarning")


func _ready():
	#_title.set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	#_drag_handle.set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	pass


func configure():
	super()
	_drag_handle.target = self
	_drag_handle.type = type
	_validation_warning.visible = false


func set_title(text, tooltip):
	_title.text = text
	_title.tooltip_text = tooltip


func _on_remove_button_pressed():
	var confirm = ConfirmationDialog.new()
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.title = "Please confirm"
	confirm.dialog_text = "Are you sure you want to remove this expression? This action cannot be undone."
	confirm.canceled.connect(_remove_cancelled.bind(confirm))
	confirm.confirmed.connect(_remove_confirmed.bind(confirm))
	get_tree().root.add_child(confirm)
	confirm.show()


func _remove_confirmed(confirm):
	get_tree().root.remove_child(confirm)
	remove_requested.emit()


func _remove_cancelled(confirm):
	get_tree().root.remove_child(confirm)


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


func _get_type_icon(t):
	match type:
		VariableType.TYPE_BOOL:
			return BoolIcon
		VariableType.TYPE_INT:
			return IntIcon
		VariableType.TYPE_FLOAT:
			return FloatIcon
		VariableType.TYPE_STRING:
			return StringIcon


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

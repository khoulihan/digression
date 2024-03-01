@tool
extends MarginContainer

const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

signal remove_requested()
signal modified()


@onready var ValueEdit = get_node("VBoxContainer/HorizontalLayout/GridContainer/ValueEdit")
@onready var RemoveButton = get_node("VBoxContainer/HorizontalLayout/RemoveButton")

var _type

func _ready():
	if _type != null:
		ValueEdit.set_variable_type(_type)


func set_type(t):
	_type = t
	if ValueEdit != null:
		ValueEdit.set_variable_type(t)


func set_value(val):
	if val != null:
		if typeof(val) == TYPE_DICTIONARY:
			ValueEdit.set_variable(val, true)
		else:
			ValueEdit.set_value(val)


func get_value():
	if ValueEdit.is_selecting_variable():
		return ValueEdit.get_selected_variable()
	return ValueEdit.get_value()


func _on_RemoveButton_pressed():
	emit_signal("remove_requested")


func _on_ValueEdit_value_changed():
	emit_signal("modified")

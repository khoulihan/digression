@tool
extends HBoxContainer


const Logging = preload("../../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


const VariableType = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableType


@onready var PropertyNameLabel = $Label
@onready var OperatorExpression = $PC/MC/OperatorExpression


signal remove_requested()
signal modified()
signal size_changed(size_change)


var _type: VariableType
var _property_name: String


func configure(property: Dictionary) -> void:
	_type = property['type']
	_property_name = property['name']
	PropertyNameLabel.text = "%s:" % _humanise(property['name'])
	OperatorExpression.type = property['type']
	OperatorExpression.deserialise(property['expression'])
	OperatorExpression.configure()


func serialise() -> Dictionary:
	return {
		'name': _property_name,
		'type': _type,
		'expression': OperatorExpression.serialise(),
	}


# This seems like an odd omission seeing that the editor needs to do this
# for property names. Not sure if this implementation will match the editor
# behaviour.
func _humanise(name: String) -> String:
	var parts := name.split("_")
	var humanised: Array[String] = []
	for part in parts:
		humanised.append(part.to_pascal_case())
	return " ".join(humanised)


func get_property_name() -> String:
	return _property_name


func _on_remove_button_pressed():
	remove_requested.emit()


func _on_operator_expression_modified():
	modified.emit()


func _on_operator_expression_size_changed(amount):
	size_changed.emit(amount)

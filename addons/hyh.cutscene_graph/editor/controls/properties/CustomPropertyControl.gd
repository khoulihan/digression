@tool
extends HBoxContainer
## Control for managing an individual custom property.


signal remove_requested()
signal modified()
signal size_changed(size_change)

const Logging = preload("../../../utility/Logging.gd")
const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType

var _logger = Logging.new(
	Logging.DGE_EDITOR_LOG_NAME,
	Logging.DGE_EDITOR_LOG_LEVEL
)
var _type: VariableType
var _property_name: String

@onready var _property_name_label := $PropertyNameLabel
@onready var _operator_expression := $PC/MC/OperatorExpression


## Configure the control for the specified property.
func configure(property: Dictionary) -> void:
	_type = property['type']
	_property_name = property['name']
	_property_name_label.text = "%s:" % _humanise(property['name'])
	_operator_expression.type = property['type']
	_operator_expression.deserialise(property['expression'])
	_operator_expression.configure()


## Serialise the property as a dictionary.
func serialise() -> Dictionary:
	return {
		'name': _property_name,
		'type': _type,
		'expression': _operator_expression.serialise(),
	}


## Get the name of the managed property.
func get_property_name() -> String:
	return _property_name


# This seems like an odd omission seeing that the editor needs to do this
# for property names. Not sure if this implementation will match the editor
# behaviour.
func _humanise(name: String) -> String:
	var parts := name.split("_")
	var humanised: Array[String] = []
	for part in parts:
		humanised.append(part.to_pascal_case())
	return " ".join(humanised)


func _on_remove_button_pressed():
	remove_requested.emit()


func _on_operator_expression_modified():
	modified.emit()


func _on_operator_expression_size_changed(amount):
	size_changed.emit(amount)

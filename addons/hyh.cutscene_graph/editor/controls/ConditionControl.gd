@tool
extends MarginContainer

const Logging = preload("../../utility/Logging.gd")
const Highlighting = preload("../../utility/Highlighting.gd")


const ExpressionResource = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd")


@onready var ConditionExpression = get_node("Condition/PC/MarginContainer/ConditionExpression")

signal condition_set(condition)
signal condition_cleared()
signal set_condition_requested()
signal edit_condition_requested()
signal clear_condition_requested()

var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


var condition_resource:
	get:
		return condition_resource
	set(val):
		condition_resource = val
		_configure_for_condition(condition_resource)


func _configure_for_condition(condition):
	$SetConditionButton.visible = condition == null
	$Condition.visible = condition != null
	if condition == null:
		return
	
	ConditionExpression.deserialise(condition.expression)
	ConditionExpression.configure()


func _on_set_condition_button_pressed():
	Logger.debug("Set condition button pressed")
	$SetConditionButton.visible = false
	$Condition.visible = true
	ConditionExpression.clear()
	ConditionExpression.configure()


func _on_clear_button_pressed():
	self.condition_resource = null
	$Condition.visible = false
	$SetConditionButton.visible = true


func _on_condition_expression_modified():
	# TODO: Maybe display the overall validation status
	ConditionExpression.validate()
	if condition_resource == null:
		condition_resource = ExpressionResource.new()
	# TODO: Serialising the expression every time it is modified like this
	# seems wasteful.
	condition_resource.expression = ConditionExpression.serialise()

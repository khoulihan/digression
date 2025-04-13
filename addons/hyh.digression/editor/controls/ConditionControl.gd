@tool
extends MarginContainer
## A control for managing a condition (an expression).


signal size_changed(size_change)

const Logging = preload("../../utility/Logging.gd")
const Highlighting = preload("../../utility/Highlighting.gd")
const ExpressionResource = preload("../../resources/graph/expressions/ExpressionResource.gd")


@export var show_set_button := true


## The condition to manage.
var condition_resource:
	get:
		return condition_resource
	set(val):
		condition_resource = val
		_configure_for_condition(condition_resource)

var _logger = Logging.new(
	Logging.DGE_EDITOR_LOG_NAME,
	Logging.DGE_EDITOR_LOG_LEVEL
)

@onready var _condition_expression := $Condition/PC/MC/ConditionExpression
@onready var _set_condition_button := $SetConditionButton
@onready var _condition := $Condition


func _ready() -> void:
	_set_condition_button.visible = show_set_button


func configure_for_new_condition() -> void:
	_on_set_condition_button_pressed()


func _configure_for_condition(condition):
	_set_condition_button.visible = show_set_button and condition == null
	_condition.visible = condition != null
	if condition == null:
		return
	
	_condition_expression.deserialise(condition.expression)
	_condition_expression.configure()


func _emit_size_changed(size_before, second_deferral=false):
	# When removing a condition, the size doesn't change on
	# the first idle frame - have to defer a second time.
	if second_deferral:
		size_changed.emit(self.size.y - size_before)
		return
	call_deferred("_emit_size_changed", size_before, true)


func _on_set_condition_button_pressed():
	_logger.debug("Set condition button pressed")
	var size_before = self.size.y
	_set_condition_button.visible = false
	_condition.visible = true
	_condition_expression.clear()
	_condition_expression.configure()
	call_deferred("_emit_size_changed", size_before)


func _on_clear_button_pressed():
	var confirm = ConfirmationDialog.new()
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.title = "Please confirm"
	confirm.dialog_text = "Are you sure you want to remove this condition? This action cannot be undone."
	confirm.canceled.connect(_on_clear_cancelled.bind(confirm))
	confirm.confirmed.connect(_on_clear_confirmed.bind(confirm))
	get_tree().root.add_child(confirm)
	confirm.show()


func _on_clear_confirmed(confirm):
	get_tree().root.remove_child(confirm)
	self.condition_resource = null
	var size_before = self.size.y
	_condition.visible = false
	_set_condition_button.visible = show_set_button
	call_deferred("_emit_size_changed", size_before)


func _on_clear_cancelled(confirm):
	get_tree().root.remove_child(confirm)


func _on_condition_expression_modified():
	# TODO: Maybe display the overall validation status
	_condition_expression.validate()
	if condition_resource == null:
		condition_resource = ExpressionResource.new()
	# TODO: Serialising the expression every time it is modified like this
	# seems wasteful.
	condition_resource.expression = _condition_expression.serialise()


func _on_condition_expression_size_changed(amount):
	size_changed.emit(amount)

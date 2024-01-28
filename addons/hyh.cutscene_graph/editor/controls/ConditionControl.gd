@tool
extends MarginContainer

const Logging = preload("../../utility/Logging.gd")
const Highlighting = preload("../../utility/Highlighting.gd")


const ExpressionResource = preload("res://addons/hyh.cutscene_graph/resources/graph/expressions/ExpressionResource.gd")


@onready var ConditionExpression = get_node("Condition/PC/MarginContainer/ConditionExpression")


signal size_changed(size_change)


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


func _emit_size_changed(size_before, second_deferral=false):
	# When removing a condition, the size doesn't change on
	# the first idle frame - have to defer a second time.
	if second_deferral:
		size_changed.emit(self.size.y - size_before)
		return
	call_deferred("_emit_size_changed", size_before, true)


func _on_set_condition_button_pressed():
	Logger.debug("Set condition button pressed")
	var size_before = self.size.y
	$SetConditionButton.visible = false
	$Condition.visible = true
	ConditionExpression.clear()
	ConditionExpression.configure()
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
	$Condition.visible = false
	$SetConditionButton.visible = true
	call_deferred("_emit_size_changed", size_before)


func _on_clear_cancelled(confirm):
	get_tree().root.remove_child(confirm)


func _on_condition_expression_modified():
	# TODO: Maybe display the overall validation status
	ConditionExpression.validate()
	if condition_resource == null:
		condition_resource = ExpressionResource.new()
	# TODO: Serialising the expression every time it is modified like this
	# seems wasteful.
	condition_resource.expression = ConditionExpression.serialise()

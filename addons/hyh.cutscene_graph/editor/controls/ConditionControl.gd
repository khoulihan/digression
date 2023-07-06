@tool
extends MarginContainer

const Logging = preload("../../utility/Logging.gd")
const Highlighting = preload("../../utility/Highlighting.gd")
# TODO: Dunno if this is required
const EditConditionWindow = preload("../conditionals_edit/ConditionsEditDialog.tscn")
@onready var ConditionLabel = get_node("Condition/MarginContainer/ConditionLabel")

signal condition_set(condition)
signal condition_cleared()
signal set_condition_requested()
signal edit_condition_requested()
signal clear_condition_requested()

var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


var _condition_window


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
	
	ConditionLabel.text = "%s %s" % [
		Highlighting.highlight("if", Highlighting.KEYWORD_COLOUR),
		condition.get_highlighted_syntax()
	]


func _on_set_condition_button_pressed():
	Logger.debug("Set condition button pressed")
	if _condition_window == null:
		_condition_window = EditConditionWindow.instantiate()
		# TODO: Figure out how to determine central position in editor window
		_condition_window.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
		_condition_window.position = get_tree().root.position + Vector2i(300, 300)
		_condition_window.configure(condition_resource)
		self.get_tree().root.add_child(_condition_window)
		_condition_window.cancelled.connect(
			_edit_condition_window_cancelled
		)
		_condition_window.saved.connect(
			_edit_condition_window_saved
		)
		_condition_window.configure(condition_resource)
		_condition_window.popup()


func _edit_condition_window_cancelled():
	Logger.debug("Edit condition cancelled")
	_condition_window.hide()
	self.get_tree().root.remove_child(_condition_window)
	_condition_window.cancelled.disconnect(_edit_condition_window_cancelled)
	_condition_window.saved.disconnect(_edit_condition_window_saved)
	_condition_window.queue_free()


func _edit_condition_window_saved(condition):
	Logger.debug("Condition saved")
	Logger.debug("%s" % condition)
	_condition_window.hide()
	self.condition_resource = condition
	self.remove_child(_condition_window)
	_condition_window.cancelled.disconnect(_edit_condition_window_cancelled)
	_condition_window.saved.disconnect(_edit_condition_window_saved)
	_condition_window.queue_free()


func _on_edit_button_pressed():
	# TODO: Mostly duplicate code here
	Logger.debug("Edit condition button pressed")
	if _condition_window == null:
		_condition_window = EditConditionWindow.instantiate()
		# TODO: Figure out how to determine central position in editor window
		_condition_window.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
		_condition_window.position = get_tree().root.position + Vector2i(300, 300)
		_condition_window.configure(condition_resource)
		self.add_child(_condition_window)
		_condition_window.cancelled.connect(
			_edit_condition_window_cancelled
		)
		_condition_window.saved.connect(
			_edit_condition_window_saved
		)
		_condition_window.configure(condition_resource)
		_condition_window.popup()


func _on_clear_button_pressed():
	self.condition_resource = null

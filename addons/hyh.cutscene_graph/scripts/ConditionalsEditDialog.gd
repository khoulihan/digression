@tool
extends Window

const Logging = preload("../scripts/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


signal saved(condition)
signal cancelled()


# This did not have the desired effect
func set_theme(theme):
	self.theme = theme
	$ConditionalsEditDialogContents.theme = theme


# Called when the node enters the scene tree for the first time.
func _ready():
	await $ConditionsEditDialogContents.ready


## Configure the window to edit an existing condition
## or create a new one.
func configure(condition = null):
	await $ConditionsEditDialogContents.ready
	$ConditionsEditDialogContents.configure(condition)


func _on_conditions_edit_dialog_contents_cancelled():
	Logger.debug("Cancel handled by dialog")
	cancelled.emit()


func _on_conditions_edit_dialog_contents_saved(condition):
	Logger.debug("Save handled by dialog")
	saved.emit(condition)


func _on_close_requested():
	# TODO: This need to do validation as well, but the internal
	# control handles that...
	cancelled.emit()

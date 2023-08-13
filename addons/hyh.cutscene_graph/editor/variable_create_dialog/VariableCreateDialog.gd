@tool
extends Window


const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


signal cancelled()
signal created(variable)


@onready var Contents = get_node("VariableCreateDialogContents")


func _ready():
	self.size = get_node("VariableCreateDialogContents").size


func _on_variable_create_dialog_contents_resized():
	Logger.debug("Resized signal")
	if Contents != null:
		self.size = Contents.size


func _on_close_requested():
	Logger.debug("Variable create dialog closed")
	cancelled.emit()


func _on_variable_create_dialog_contents_cancelled():
	Logger.debug("Variable create dialog cancelled")
	cancelled.emit()


func _on_variable_create_dialog_contents_created(variable):
	Logger.debug("Variable create dialog completed")
	created.emit(variable)

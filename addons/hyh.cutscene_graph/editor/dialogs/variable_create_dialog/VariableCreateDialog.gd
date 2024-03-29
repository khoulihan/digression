@tool
extends Window
## Dialog for creating a variable definition.


signal cancelled()
signal created(variable)

const Logging = preload("../../../utility/Logging.gd")
const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType

## The type to restrict the search to, if any.
var type_restriction : Variant

var _logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

@onready var _contents = $VariableCreateDialogContents
@onready var _background_panel = $BackgroundPanel


func _ready() -> void:
	self.size = get_node("VariableCreateDialogContents").size
	_background_panel.color = get_theme_color("base_color", "Editor")


func _on_variable_create_dialog_contents_resized():
	_logger.debug("Resized signal")
	if _contents != null:
		self.size = _contents.size


func _on_close_requested():
	_logger.debug("Variable create dialog closed")
	cancelled.emit()


func _on_variable_create_dialog_contents_cancelled():
	_logger.debug("Variable create dialog cancelled")
	cancelled.emit()


func _on_variable_create_dialog_contents_created(variable):
	_logger.debug("Variable create dialog completed")
	created.emit(variable)

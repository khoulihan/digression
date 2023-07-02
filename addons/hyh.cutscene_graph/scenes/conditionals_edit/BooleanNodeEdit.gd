@tool
extends GridContainer

const Logging = preload("../../scripts/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

const BooleanType = preload("../../resources/conditions/BooleanCondition.gd").BooleanType

signal boolean_type_selected(boolean_type)

@onready var Select = get_node("OptionButton")

#var edited_node: TreeItem:
#	get:
#		return edited_node
#	set(value):
#		Logger.debug("Editing node %s" % value)
#		edited_node = value
#		if edited_node != null:
#			Select.selected = edited_node.get_meta("boolean_type")


var boolean_type: BooleanType:
	get:
		return Select.selected
	set(value):
		Select.selected = value



func _on_option_button_item_selected(index):
	Logger.debug("Boolean type selected")
	boolean_type_selected.emit(index)
	
	#edited_node.set_meta("boolean_type", index)
	#match edited_node.get_meta("boolean_type"):
	#	BooleanType.BOOLEAN_AND:
	#		Logger.debug("Setting And")
	#		edited_node.set_text(0, "And")
	#	BooleanType.BOOLEAN_OR:
	#		Logger.debug("Setting Or")
	#		edited_node.set_text(0, "Or")

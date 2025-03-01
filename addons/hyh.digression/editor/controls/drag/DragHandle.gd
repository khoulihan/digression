@tool
extends TextureRect


enum DragClass {
	ARGUMENT,
	DIALOGUE_SECTION,
	MATCH_BRANCH,
	IF_BRANCH,
	RANDOM_BRANCH,
	CHOICE,
	EXPRESSION
}

enum DragVariableTypeRestriction {
	NONE = 0,
	BOOL = 1,
	INT = 2,
	FLOAT = 3,
	STRING = 4
}

const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const Logging = preload("../../../utility/Logging.gd")
const HANDLE_ICON = preload("../../../icons/icon_drag_vertical_light.svg")


@export var target : Node
@export var drag_class : DragClass
@export var type_restriction : DragVariableTypeRestriction

var _logger = Logging.new(Logging.DGE_EDITOR_LOG_NAME, Logging.DGE_EDITOR_LOG_LEVEL)


func _get_drag_data(at_position):
	if target == null:
		return
	if not target.has_method("get_drag_preview"):
		_logger.warn("Drag handle target does not have get_drag_preview method.")
		set_drag_preview(_get_default_drag_preview())
	else:
		set_drag_preview(target.get_drag_preview())
	var drag_data := {
		"dge_drag_class": drag_class,
		"control": target,
	}
	if self.type_restriction != DragVariableTypeRestriction.NONE:
		drag_data["dge_drag_variable_type"] = map_type_restriction_to_type(type_restriction)
	return drag_data


static func map_type_restriction_to_type(restriction_type: DragVariableTypeRestriction) -> VariableType:
	match (restriction_type):
		DragVariableTypeRestriction.BOOL:
			return VariableType.TYPE_BOOL
		DragVariableTypeRestriction.INT:
			return VariableType.TYPE_INT
		DragVariableTypeRestriction.FLOAT:
			return VariableType.TYPE_FLOAT
		DragVariableTypeRestriction.STRING:
			return VariableType.TYPE_STRING
		_:
			# We should never end up here.
			return VariableType.TYPE_BOOL


static func map_type_to_type_restriction(vartype: VariableType) -> DragVariableTypeRestriction:
	match (vartype):
		VariableType.TYPE_BOOL:
			return DragVariableTypeRestriction.BOOL
		VariableType.TYPE_INT:
			return DragVariableTypeRestriction.INT
		VariableType.TYPE_FLOAT:
			return DragVariableTypeRestriction.FLOAT
		VariableType.TYPE_STRING:
			return DragVariableTypeRestriction.STRING
		_:
			return DragVariableTypeRestriction.NONE


func _get_drag_class_string(dc : DragClass) -> String:
	return str(DragClass.find_key(dc)).to_lower()


func _get_default_drag_preview():
	var preview = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.texture = HANDLE_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	var ptext = Label.new()
	ptext.text = _get_type_name()
	preview.add_child(icon)
	preview.add_child(ptext)
	# TODO: This is hard to see over a node, which is where it should be most visible!
	preview.modulate = Color.from_string("#777777FF", Color.DIM_GRAY)
	return preview


func _get_type_name() -> String:
	var name_sections := str(DragClass.find_key(drag_class)).split("_")
	var processed : Array[String] = []
	for n in name_sections:
		processed.append(n.to_pascal_case())
	return " ".join(processed)

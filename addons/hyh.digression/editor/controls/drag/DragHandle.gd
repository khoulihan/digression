@tool
extends TextureRect


enum DragClass {
	ARGUMENT,
	DIALOGUE_SECTION
}

const Logging = preload("../../../utility/Logging.gd")
const HANDLE_ICON = preload("../../../icons/icon_triple_bar.svg")


@export var target : Node
@export var drag_class : DragClass

var _logger = Logging.new(Logging.DGE_EDITOR_LOG_NAME, Logging.DGE_EDITOR_LOG_LEVEL)


func _get_drag_data(at_position):
	if target == null:
		return
	if not target.has_method("get_drag_preview"):
		_logger.warn("Drag handle target does not have get_drag_preview method.")
		set_drag_preview(_get_default_drag_preview())
	else:
		set_drag_preview(target.get_drag_preview())
	return {
		"dge_drag_class": drag_class,
		"control": target,
	}


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
	preview.modulate = Color.from_string("#FFFFFF88", Color.WHITE)
	return preview


func _get_type_name() -> String:
	var name_sections := str(DragClass.find_key(drag_class)).split("_")
	var processed : Array[String] = []
	for n in name_sections:
		processed.append(n.to_pascal_case())
	return " ".join(processed)

@tool
extends MarginContainer


signal dropped(arg, at_position)


const DragClass = preload("res://addons/hyh.digression/editor/controls/drag/DragHandle.gd").DragClass
const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const DragVariableTypeRestriction = preload("DragHandle.gd").DragVariableTypeRestriction


@export var accepted_classes : Array[DragClass]
@export var accepted_type_restriction : DragVariableTypeRestriction
@export var hide_until_hover : bool = false

var _mouse_over := false

@onready var _drop_icon_left := $HB/DropIconLeft
@onready var _separator := $HB/HSeparator
@onready var _drop_icon_right := $HB/DropIconRight


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_drop_icon_left.visible = false
	_drop_icon_right.visible = false
	_separator.accepted_classes = accepted_classes
	_separator.accepted_type_restriction = accepted_type_restriction
	if hide_until_hover:
		_separator.modulate = Color.TRANSPARENT


func update_accepted_type_restriction(t: DragVariableTypeRestriction) -> void:
	accepted_type_restriction = t
	_separator.accepted_type_restriction = accepted_type_restriction


func _indicate_droppable(state: bool) -> void:
	#_separator.visible = state if hide_until_hover else true
	_drop_icon_left.visible = state
	_drop_icon_right.visible = state
	if not hide_until_hover:
		_separator.modulate = Color.BLACK if state else Color.WHITE
	else:
		_separator.modulate = Color.BLACK if state else Color.TRANSPARENT


func _on_drag_target_can_drop(at_position: Variant, data: Variant) -> void:
	_indicate_droppable(_mouse_over)


func _on_drag_target_dropped(arg: Variant, at_position: Variant) -> void:
	_indicate_droppable(false)
	dropped.emit(arg, at_position)


func _on_drag_target_mouse_entered() -> void:
	_mouse_over = true


func _on_drag_target_mouse_exited() -> void:
	_mouse_over = false
	_indicate_droppable(false)

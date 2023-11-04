@tool
extends "res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/DialogueTextEvent.gd"


@onready var _type_label_player = $VB/VB/HB/HB/TypeLabelLeft
@onready var _dialogue_indicator_right = $VB/VB/HB/DialogueIndicatorRight


func populate(
	type,
	character,
	variant,
	dialogue,
	panel_resource,
	indicator_resource,
	display_characterwise
):
	super(
		type,
		character,
		variant,
		dialogue,
		panel_resource,
		indicator_resource,
		display_characterwise
	)
	if type == null:
		_type_label_player.hide()
	else:
		_type_label_player.text = type
	if indicator_resource != null:
		_dialogue_indicator_right.add_theme_stylebox_override("panel", indicator_resource)

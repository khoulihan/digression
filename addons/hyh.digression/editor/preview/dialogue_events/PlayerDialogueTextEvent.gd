@tool
extends "DialogueTextEvent.gd"
## Displays player dialogue in the graph previewer.


@onready var _type_label_player = $VB/VB/HB/HB/TypeLabelLeft
@onready var _dialogue_indicator_right = $VB/VB/HB/DialogueIndicatorRight


## Populate the control with the dialogue details.
func populate(
	type,
	character,
	variant,
	dialogue,
	panel_resource,
	indicator_resource,
	display_characterwise,
	properties
):
	super(
		type,
		character,
		variant,
		dialogue,
		panel_resource,
		indicator_resource,
		display_characterwise,
		properties,
	)
	if type == null:
		_type_label_player.hide()
	else:
		_type_label_player.text = type
	if indicator_resource != null:
		_dialogue_indicator_right.add_theme_stylebox_override("panel", indicator_resource)
	for property_label: Label in _properties_container.get_children():
		property_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

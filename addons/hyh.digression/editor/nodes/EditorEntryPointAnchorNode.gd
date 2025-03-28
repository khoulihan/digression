@tool
extends "res://addons/hyh.digression/editor/nodes/EditorAnchorNode.gd"


const ENTRY_POINT_ANCHOR_NAME = "entry_point"


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	# Hide the close button.
	_close_button.visible = false
	


## Return the name of the anchor.
func get_name():
	return ENTRY_POINT_ANCHOR_NAME


## Set the anchor name. This does nothing for the entry point anchor node,
## as it has a fixed name.
func set_name(name):
	pass

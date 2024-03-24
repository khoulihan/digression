@tool
extends "EditorGraphNodeBase.gd"
## Editor node corresponding to the Repeat resource node.


func _on_gui_input(ev):
	super._on_gui_input(ev)


## Get an array of the port numbers for output connections.
func get_output_port_numbers() -> Array[int]:
	return []

@tool
extends "EditorGraphNodeBase.gd"
## Editor node for managing navigation to Anchor nodes.


signal destination_chosen(name)

@onready var _destination_option = $MC/DestinationOption


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	set_destination(n.next)


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	super.persist_changes_to_node()
	# Should not need to set the `next` here because relationships are
	# managed elsewhere.


## Set the destination anchor by ID.
func set_destination(id):
	if id == -1:
		id = 0
	for idx in range(0, _destination_option.item_count):
		if _destination_option.get_item_id(idx) == id:
			_destination_option.selected = idx
			break


## Populate the possible destinations.
func populate_destinations(destinations):
	if not is_node_ready():
		await ready
	
	var current_id
	if _destination_option.selected != -1:
		current_id = _destination_option.get_item_id(_destination_option.selected)
	
	_destination_option.clear()
	_destination_option.add_item("", 0)
	for id in destinations:
		_destination_option.add_item(destinations[id], id)
	
	if current_id != null:
		set_destination(current_id)


func _on_option_button_item_selected(index):
	var id = _destination_option.get_item_id(index)
	if id == 0: id = -1
	destination_chosen.emit(
		id
	)


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_connected_to_node(port_index, node_id):
	set_destination(node_id)


func _on_disconnected(port_index):
	set_destination(-1)

@tool
extends "EditorGraphNodeBase.gd"

signal destination_chosen(name)

@onready var DestinationOption = get_node("MarginContainer/DestinationOption")


func configure_for_node(g, n):
	super.configure_for_node(g, n)
	set_destination(n.next)


func persist_changes_to_node():
	super.persist_changes_to_node()
	# Should not need to set the `next` here because relationships are
	# managed elsewhere.


func set_destination(id):
	if id == -1:
		id = 0
	for idx in range(0, DestinationOption.item_count):
		if DestinationOption.get_item_id(idx) == id:
			DestinationOption.selected = idx
			break


func populate_destinations(destinations):
	if not is_node_ready():
		await ready
	
	var current_id
	if DestinationOption.selected != -1:
		current_id = DestinationOption.get_item_id(DestinationOption.selected)
	
	DestinationOption.clear()
	DestinationOption.add_item("", 0)
	for id in destinations:
		DestinationOption.add_item(destinations[id], id)
	
	if current_id != null:
		set_destination(current_id)


func _on_option_button_item_selected(index):
	var id = DestinationOption.get_item_id(index)
	if id == 0: id = -1
	destination_chosen.emit(
		id
	)


func _on_gui_input(ev):
	super._on_gui_input(ev)

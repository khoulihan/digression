@tool
extends MarginContainer

const PropertyCollection = preload("../../../resources/properties/PropertyCollection.gd")
const CustomProperty = preload("../../../resources/properties/CustomProperty.gd")
const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType

const REMOVE_ICON = preload("res://addons/hyh.cutscene_graph/icons/icon_close.svg")

@onready var PropertyTree: Tree = get_node("VB/PropertyTree")


enum PropertyTreeColumns {
	PROPERTY_NAME,
	VALUE,
	REMOVE_BUTTON,
}


var property_collection: PropertyCollection:
	get:
		return property_collection
	set(value):
		property_collection = value
		_populate(property_collection)


func _ready():
	print("Configuring tree")
	PropertyTree.set_column_expand(
		PropertyTreeColumns.PROPERTY_NAME, true
	)
	PropertyTree.set_column_expand(
		PropertyTreeColumns.VALUE, true
	)
	PropertyTree.set_column_expand(
		PropertyTreeColumns.REMOVE_BUTTON, false
	)
	PropertyTree.set_column_clip_content(
		PropertyTreeColumns.REMOVE_BUTTON,
		false,
	)


func _populate(collection: PropertyCollection) -> void:
	PropertyTree.clear()
	var root := PropertyTree.create_item()
	for property_name in collection.properties:
		var item := root.create_child()
		_configure_item_for_property(
			item,
			collection.properties[property_name],
		)


func _configure_item_for_property(
	item: TreeItem,
	property: CustomProperty,
) -> void:
	item.set_cell_mode(
		PropertyTreeColumns.PROPERTY_NAME,
		TreeItem.CELL_MODE_STRING,
	)
	item.set_editable(
		PropertyTreeColumns.PROPERTY_NAME,
		false,
	)
	item.set_text(
		PropertyTreeColumns.PROPERTY_NAME,
		_humanise(property.property)
	)
	match property.type:
		VariableType.TYPE_BOOL:
			item.set_cell_mode(
				PropertyTreeColumns.VALUE,
				TreeItem.CELL_MODE_CHECK,
			)
			item.set_text(PropertyTreeColumns.VALUE, "On")
		VariableType.TYPE_STRING:
			item.set_cell_mode(
				PropertyTreeColumns.VALUE,
				TreeItem.CELL_MODE_STRING,
			)
		VariableType.TYPE_INT:
			item.set_cell_mode(
				PropertyTreeColumns.VALUE,
				TreeItem.CELL_MODE_RANGE,
			)
			# TODO: Is there no way to get the max and min int value?
			item.set_range_config(
				PropertyTreeColumns.VALUE,
				-9223372036854775808,
				9223372036854775807,
				1.0,
			)
		VariableType.TYPE_FLOAT:
			item.set_cell_mode(
				PropertyTreeColumns.VALUE,
				TreeItem.CELL_MODE_RANGE,
			)
			# TODO: Is there no way to get the max and min float value?
			item.set_range_config(
				PropertyTreeColumns.VALUE,
				-9223372036854775808,
				9223372036854775807,
				0.0001,
			)
	item.set_editable(
		PropertyTreeColumns.VALUE,
		true,
	)
	item.add_button(
		PropertyTreeColumns.REMOVE_BUTTON,
		REMOVE_ICON,
		-1,
		false,
		"Remove property",
	)


# This seems like an odd omission seeing that the editor needs to do this
# for property names. Not sure if this implementation will match the editor
# behaviour.
func _humanise(name: String) -> String:
	var parts := name.split("_")
	var humanised: Array[String] = []
	for part in parts:
		humanised.append(part.to_pascal_case())
	return " ".join(humanised)


func _on_add_button_pressed():
	print ("Add button pressed")
	# TODO: Just adding a nonsense item for now, for testing.
	var prop := CustomProperty.new()
	prop.property = "test_time_8"
	prop.type = VariableType.TYPE_INT
	property_collection.properties['test_time_8'] = prop
	var item := PropertyTree.get_root().create_child()
	_configure_item_for_property(item, prop)
	#PropertyTree.get_root().add_child(item)
	for i in PropertyTree.get_root().get_children():
		print (i.get_text(PropertyTreeColumns.PROPERTY_NAME))
	#property_collection.property_list_changed.emit()
	property_collection.notify_property_list_changed()
	PropertyTree.queue_redraw()
	

func _on_property_tree_button_clicked(item, column, id, mouse_button_index):
	pass # Replace with function body.


func _on_property_tree_item_edited():
	pass # Replace with function body.

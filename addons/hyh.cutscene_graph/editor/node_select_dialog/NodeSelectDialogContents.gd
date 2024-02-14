@tool
extends MarginContainer


@onready var Filter = $VB/Filter
@onready var NodeTree = $VB/NodeTree
@onready var OkButton = $VB/MC/HB/OkButton


signal cancelled()
signal selected(node)


var _theme : Theme
var _scene : Node

# Called when the node enters the scene tree for the first time.
func _ready():
	_scene = EditorInterface.get_edited_scene_root()
	_theme = EditorInterface.get_editor_theme()
	_populate_for_scene(_scene)
	OkButton.disabled = true


func _populate_for_scene(scene):
	var root = NodeTree.create_item()
	# TODO: This only gets the correct icons for built-in nodes.
	# Custom nodes get default "Node" icons.
	root.set_icon(0, _theme.get_icon(scene.get_class(), "EditorIcons"))
	root.set_text(0, scene.name)
	root.set_meta("path", _scene.get_path_to(scene))
	for child in scene.get_children():
		_add_to_parent(child, root)


func _add_to_parent(node, parent):
	var tree_node = NodeTree.create_item(parent)
	# TODO: This only gets the correct icons for built-in nodes.
	# Custom nodes get default "Node" icons.
	tree_node.set_icon(0, _theme.get_icon(node.get_class(), "EditorIcons"))
	tree_node.set_text(0, node.name)
	tree_node.set_meta("path", _scene.get_path_to(node))
	for child in node.get_children():
		_add_to_parent(child, tree_node)


func _on_filter_text_changed(new_text):
	pass # Replace with function body.


func _on_cancel_button_pressed():
	cancelled.emit()


func _on_ok_button_pressed():
	selected.emit(NodeTree.get_selected().get_meta("path"))


func _on_node_tree_item_selected():
	OkButton.disabled = false


func _on_node_tree_nothing_selected():
	OkButton.disabled = true


func _on_node_tree_item_activated():
	selected.emit(NodeTree.get_selected().get_meta("path"))

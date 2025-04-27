@tool
extends MarginContainer


signal restore_requested()
signal modified(resource_node: GraphNodeBase)
signal delete_request(resource_node: GraphNodeBase)

const Dialogs = preload("../dialogs/Dialogs.gd")

const GraphNodeBase = preload("res://addons/hyh.digression/resources/graph/GraphNodeBase.gd")
const DialogueNode = preload("res://addons/hyh.digression/resources/graph/DialogueNode.gd")
const MaximisedDialogueNode = preload("./MaximisedDialogueNode.gd")
const MaximisedDialogueNodeScene = preload("./MaximisedDialogueNode.tscn")


@onready var _header: HBoxContainer = $VB/HeaderContainer/Header
@onready var _body_container: MarginContainer = $VB/BodyScrollContainer/BodyContainer


var _hosted_editor: Control
var _edited_node: GraphNodeBase


func configure_for_node(
	graph: DigressionDialogueGraph,
	resource_node: GraphNodeBase
) -> void:
	_edited_node = resource_node
	if resource_node is DialogueNode:
		_instantiate_and_configure_dialogue_node(
			graph,
			resource_node as DialogueNode
		)


func _instantiate_and_configure_dialogue_node(
	graph: DigressionDialogueGraph,
	resource_node: DialogueNode
) -> void:
	var node_editor: MaximisedDialogueNode = MaximisedDialogueNodeScene.instantiate()
	_hosted_editor = node_editor
	if _body_container.get_child_count() > 0:
		var previous := _body_container.get_child(0)
		_body_container.remove_child(previous)
		previous.queue_free()
	_body_container.add_child(node_editor)
	node_editor.configure_titlebar(_header)
	node_editor.configure_for_node(graph, resource_node)
	node_editor.modified.connect(_on_node_editor_modified.bind(resource_node))


func _show_delete_confirmation_dialog():
	if await Dialogs.request_confirmation(
		"Are you sure you want to remove this node? This action cannot be undone."
	):
		delete_request.emit(_edited_node)


func _cleanup() -> void:
	if _hosted_editor.has_method("cleanup"):
		_hosted_editor.cleanup()
	_body_container.remove_child(_hosted_editor)
	_hosted_editor.queue_free()


func _on_restore_button_pressed() -> void:
	_cleanup()
	restore_requested.emit()


func _on_node_editor_modified(resource_node: GraphNodeBase) -> void:
	modified.emit(resource_node)


func _on_close_button_pressed() -> void:
	_show_delete_confirmation_dialog()

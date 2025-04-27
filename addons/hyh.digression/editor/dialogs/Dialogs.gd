@tool
extends RefCounted


const ChoiceTypesEdit: PackedScene = preload("./choice_types_edit/ChoiceTypesEditDialog.tscn")
const DialogueTypesEdit: PackedScene = preload("./dialogue_types_edit/DialogueTypesEditDialog.tscn")
const GraphTypesEdit: PackedScene = preload("./graph_types_edit/GraphTypeEditDialog.tscn")
const NodeSelect: PackedScene = preload("./node_select_dialog/NodeSelectDialog.tscn")
const PropertyDefinitionEdit: PackedScene = preload("./property_definition_edit/PropertyDefinitionEditDialog.tscn")
const PropertySelect: PackedScene = preload("./property_select_dialog/PropertySelectDialog.tscn")
const VariableCreate: PackedScene = preload("./variable_create_dialog/VariableCreateDialog.tscn")
const VariableSelect: PackedScene = preload("./variable_select_dialog/VariableSelectDialog.tscn")


const DEFAULT_ERROR_DIALOG_TITLE = "Error"
const DEFAULT_CONFIRMATION_DIALOG_TITLE = "Please Confirm"
const VALIDATION_FAILED_DIALOG_TITLE = "Validation Failed"


static func show_error(
	text: String,
	parent_from_node: Node = null,
	title: String = "",
) -> void:
	var alert := AcceptDialog.new()
	alert.exclusive = true
	alert.unresizable = true
	alert.title = _error_title_or_default(title)
	alert.dialog_text = text
	alert.set_unparent_when_invisible(true)
	if parent_from_node:
		alert.popup_exclusive_centered(parent_from_node)
	else:
		alert.popup_exclusive_centered(EditorInterface.get_base_control())
	await alert.confirmed
	alert.queue_free()


static func request_confirmation(
	text: String,
	parent_from_node: Node = null,
	title: String = "",
) -> bool:
	var confirm = ConfirmationDialog.new()
	confirm.exclusive = true
	confirm.unresizable = true
	#confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.title = _confirmation_title_or_default(title)
	confirm.dialog_text = text
	confirm.set_unparent_when_invisible(true)
	var promise = ConfirmationPromise.new(confirm)
	if parent_from_node:
		confirm.popup_exclusive_centered(parent_from_node)
	else:
		confirm.popup_exclusive_centered(EditorInterface.get_base_control())
	await promise.completed
	confirm.queue_free()
	return promise.confirmed


static func _error_title_or_default(title: String) -> String:
	if title.is_empty():
		return DEFAULT_ERROR_DIALOG_TITLE
	return title


static func _confirmation_title_or_default(title: String) -> String:
	if title.is_empty():
		return DEFAULT_CONFIRMATION_DIALOG_TITLE
	return title


class ConfirmationPromise:
	
	signal completed(confirmed: bool)
	
	var confirmed: bool
	
	func _init(dialog: ConfirmationDialog):
		confirmed = false
		dialog.confirmed.connect(_confirmed)
		dialog.canceled.connect(_canceled)
	
	func _confirmed() -> void:
		confirmed = true
		completed.emit(confirmed)
	
	func _canceled() -> void:
		confirmed = false
		completed.emit(confirmed)

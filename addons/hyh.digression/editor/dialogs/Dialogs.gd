@tool
extends RefCounted


const Promise = preload("../promises/Promise.gd")

const ChoiceTypesEdit: PackedScene = preload("./choice_types_edit/ChoiceTypesEditDialog.tscn")
const DialogueTypesEdit: PackedScene = preload("./dialogue_types_edit/DialogueTypesEditDialog.tscn")
const GraphTypesEdit: PackedScene = preload("./graph_types_edit/GraphTypeEditDialog.tscn")
const NodeSelect: PackedScene = preload("./node_select_dialog/NodeSelectDialog.tscn")
const PropertyDefinitionsEdit: PackedScene = preload("./property_definitions_edit/PropertyDefinitionsEditDialog.tscn")
const PropertySelect: PackedScene = preload("./property_select_dialog/PropertySelectDialog.tscn")
const VariableCreate: PackedScene = preload("./variable_create_dialog/VariableCreateDialog.tscn")
const VariableSelect: PackedScene = preload("./variable_select_dialog/VariableSelectDialog.tscn")

const NodeSelectDialog := preload("./node_select_dialog/NodeSelectDialog.gd")
const PropertySelectDialog := preload("./property_select_dialog/PropertySelectDialog.gd")
const VariableCreateDialog := preload("./variable_create_dialog/VariableCreateDialog.gd")
const VariableSelectDialog := preload("./variable_select_dialog/VariableSelectDialog.gd")


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
	return promise.value


static func select_node(parent_from_node: Node = null) -> NodePath:
	var dialog := NodeSelect.instantiate()
	dialog.set_unparent_when_invisible(true)
	var promise := NodeSelectPromise.new(dialog)
	# The "centered" part of these calls seemed to be ignored... Have set an
	# initial position on the window instead.
	if parent_from_node:
		dialog.popup_exclusive(parent_from_node)
	else:
		dialog.popup_exclusive(EditorInterface.get_base_control())
	await promise.completed
	dialog.queue_free()
	if promise.state == Promise.PromiseState.REJECTED:
		return NodePath()
	return promise.value


static func select_property(
	use_restriction: PropertySelectDialog.PropertyUse,
	parent_from_node: Node = null,
) -> Dictionary:
	var dialog := PropertySelect.instantiate()
	dialog.use_restriction = use_restriction
	dialog.set_unparent_when_invisible(true)
	var promise := PropertySelectPromise.new(dialog)
	# The "centered" part of these calls seemed to be ignored... Have set an
	# initial position on the window instead.
	if parent_from_node:
		dialog.popup_exclusive(parent_from_node)
	else:
		dialog.popup_exclusive(EditorInterface.get_base_control())
	await promise.completed
	dialog.queue_free()
	if promise.state == Promise.PromiseState.REJECTED:
		return Dictionary()
	return promise.value


static func select_variable(
	type_restriction: Variant = null,
	parent_from_node: Node = null,
) -> Dictionary:
	var dialog := VariableSelect.instantiate()
	dialog.type_restriction = type_restriction
	dialog.set_unparent_when_invisible(true)
	var promise := VariableSelectPromise.new(dialog)
	# The "centered" part of these calls seemed to be ignored... Have set an
	# initial position on the window instead.
	if parent_from_node:
		dialog.popup_exclusive(parent_from_node)
	else:
		dialog.popup_exclusive(EditorInterface.get_base_control())
	await promise.completed
	dialog.queue_free()
	if promise.state == Promise.PromiseState.REJECTED:
		return Dictionary()
	return promise.value


static func create_variable(
	type_restriction: Variant = null,
	parent_from_node: Node = null,
) -> Dictionary:
	var dialog := VariableCreate.instantiate()
	dialog.type_restriction = type_restriction
	dialog.set_unparent_when_invisible(true)
	var promise := VariableCreatePromise.new(dialog)
	# The "centered" part of these calls seemed to be ignored... Have set an
	# initial position on the window instead.
	if parent_from_node:
		dialog.popup_exclusive(parent_from_node)
	else:
		dialog.popup_exclusive(EditorInterface.get_base_control())
	await promise.completed
	dialog.queue_free()
	if promise.state == Promise.PromiseState.REJECTED:
		return Dictionary()
	return promise.value


static func _error_title_or_default(title: String) -> String:
	if title.is_empty():
		return DEFAULT_ERROR_DIALOG_TITLE
	return title


static func _confirmation_title_or_default(title: String) -> String:
	if title.is_empty():
		return DEFAULT_CONFIRMATION_DIALOG_TITLE
	return title



class ConfirmationPromise extends Promise:
	func _init(dialog: ConfirmationDialog):
		super()
		dialog.confirmed.connect(_resolved.bind(true))
		dialog.canceled.connect(_rejected.bind(false))


class NodeSelectPromise extends Promise:
	func _init(dialog: NodeSelectDialog):
		super()
		dialog.selected.connect(_resolved)
		dialog.canceled.connect(_rejected)


class PropertySelectPromise extends Promise:
	func _init(dialog: PropertySelectDialog):
		super()
		dialog.selected.connect(_resolved)
		dialog.canceled.connect(_rejected)


class VariableSelectPromise extends Promise:
	func _init(dialog: VariableSelectDialog):
		super()
		dialog.selected.connect(_resolved)
		dialog.canceled.connect(_rejected)


class VariableCreatePromise extends Promise:
	func _init(dialog: VariableCreateDialog):
		super()
		dialog.created.connect(_resolved)
		dialog.canceled.connect(_rejected)

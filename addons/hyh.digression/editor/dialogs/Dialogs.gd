@tool
extends RefCounted


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
	return promise.confirmed


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
	return promise.path


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
	return promise.property


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
	return promise.variable


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
	return promise.variable


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


class NodeSelectPromise:
	
	signal completed(selected: bool)
	
	var selected: bool
	var path: NodePath
	
	func _init(dialog: NodeSelectDialog):
		selected = false
		path = NodePath()
		dialog.selected.connect(_selected)
		dialog.canceled.connect(_canceled)
	
	func _selected(path: NodePath) -> void:
		selected = true
		self.path = path
		completed.emit(selected)
	
	func _canceled() -> void:
		selected = false
		completed.emit(selected)


class PropertySelectPromise:
	
	signal completed(selected: bool)
	
	var selected: bool
	var property: Dictionary
	
	func _init(dialog: PropertySelectDialog):
		selected = false
		property = {}
		dialog.selected.connect(_selected)
		dialog.canceled.connect(_canceled)
	
	func _selected(property: Dictionary) -> void:
		selected = true
		self.property = property
		completed.emit(selected)
	
	func _canceled() -> void:
		selected = false
		completed.emit(selected)


class VariableSelectPromise:
	
	signal completed(selected: bool)
	
	var selected: bool
	var variable: Dictionary
	
	func _init(dialog: VariableSelectDialog):
		selected = false
		variable = {}
		dialog.selected.connect(_selected)
		dialog.canceled.connect(_canceled)
	
	func _selected(variable: Dictionary) -> void:
		selected = true
		self.variable = variable
		completed.emit(selected)
	
	func _canceled() -> void:
		selected = false
		completed.emit(selected)


class VariableCreatePromise:
	
	signal completed(created: bool)
	
	var created: bool
	var variable: Dictionary
	
	func _init(dialog: VariableCreateDialog):
		created = false
		variable = {}
		dialog.created.connect(_created)
		dialog.canceled.connect(_canceled)
	
	func _created(variable: Dictionary) -> void:
		created = true
		self.variable = variable
		completed.emit(created)
	
	func _canceled() -> void:
		created = false
		completed.emit(created)

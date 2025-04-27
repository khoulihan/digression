@tool
extends MarginContainer
## Control for managing custom properties in a graph node.


signal size_changed(size_change)
signal modified()
signal add_property_requested(property)
signal remove_property_requested(property_name)

const Dialogs = preload("../../dialogs/Dialogs.gd")
const PropertySelectDialog = preload("../../dialogs/property_select_dialog/PropertySelectDialog.tscn")
const PropertySelectDialogClass = preload("../../dialogs/property_select_dialog/PropertySelectDialog.gd")
const PropertyUse = PropertySelectDialogClass.PropertyUse
const CustomPropertyControl = preload("CustomPropertyControl.tscn")

## The PropertyUse to restrict the control to.
@export var use_restriction: PropertyUse
@export var show_add_button := true

var _populating := false

@onready var _properties_container = $VB/PropertiesContainer
@onready var _add_button = $VB/AddButton


func _ready() -> void:
	_add_button.visible = show_add_button


## Configure the control for the specified properties.
func configure(properties: Dictionary) -> void:
	_populating = true
	for property_name in properties:
		var property: Dictionary = properties[property_name]
		add_property(property)
	_populating = false


## Retrieve the properties.
func serialise() -> Dictionary:
	var props = {}
	for child in _properties_container.get_children():
		props[child.get_property_name()] = child.serialise()
	return props


## Add the specified property
func add_property(property: Dictionary) -> void:
	var size_before := size.y
	var new_property = CustomPropertyControl.instantiate()
	new_property.remove_requested.connect(
		_on_property_remove_requested.bind(property['name'])
	)
	new_property.modified.connect(_on_property_modified)
	new_property.size_changed.connect(_on_property_size_changed)
	new_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_properties_container.add_child(new_property)
	new_property.configure(property)
	if not _populating:
		_emit_size_changed(size_before, 10)
		modified.emit()


## Remove the specified property.
func remove_property(property_name: String) -> void:
	var size_before := self.size.y
	for child in _properties_container.get_children():
		if child.get_property_name() == property_name:
			_properties_container.remove_child(child)
			_emit_size_changed(size_before, 10)
			modified.emit()
			return


func request_property_and_add() -> void:
	var dialog = PropertySelectDialog.instantiate()
	dialog.use_restriction = self.use_restriction
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.cancelled.connect(_on_property_select_dialog_cancelled.bind(dialog))
	dialog.selected.connect(_on_property_select_dialog_selected.bind(dialog))
	get_tree().root.add_child(dialog)
	dialog.popup()


func _emit_size_changed(size_before, deferrals_required=2, deferral_count=0):
	# Some changes to the UI aren't reflected in the controls
	# size on the next idle frame, so have to defer until they are.
	if deferral_count == deferrals_required:
		size_changed.emit(self.size.y - size_before)
		return
	call_deferred("_emit_size_changed", size_before, deferrals_required, deferral_count + 1)


func _on_add_button_pressed():
	request_property_and_add()


func _on_property_select_dialog_cancelled(dialog) -> void:
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _on_property_select_dialog_selected(property, dialog) -> void:
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	add_property_requested.emit(property)


func _on_property_remove_requested(property_name) -> void:
	if await Dialogs.request_confirmation(
		"Are you sure you want to remove this property? This action cannot be undone."
	):
		remove_property_requested.emit(property_name)


func _on_property_modified() -> void:
	modified.emit()


func _on_property_size_changed(size_change) -> void:
	size_changed.emit(size_change)

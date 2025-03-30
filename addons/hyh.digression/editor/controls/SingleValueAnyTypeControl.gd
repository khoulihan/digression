@tool
extends MarginContainer
## A control that allows a single value of any type to be specified as an expression.


signal size_changed(size_change)


const Logging = preload("../../utility/Logging.gd")
const ExpressionResource = preload("../../resources/graph/expressions/ExpressionResource.gd")


@export var type_menu_title: String
@export var value_label_text: String


var _logger = Logging.new(
	Logging.DGE_EDITOR_LOG_NAME,
	Logging.DGE_EDITOR_LOG_LEVEL
)


@onready var _type_menu := $TypeMenuButton
@onready var _value_label := $ValueContainer/Label
@onready var _value_container := $ValueContainer
@onready var _value_expression := $ValueContainer/PC/MC/ValueExpression


## The value to manage.
var value_resource:
	get:
		return value_resource
	set(val):
		value_resource = val
		_configure_for_value(value_resource)


func _ready() -> void:
	var menu: PopupMenu = _type_menu.get_popup()
	menu.id_pressed.connect(_on_type_menu_id_pressed)
	_type_menu.text = type_menu_title
	_value_label.text = value_label_text


func _configure_for_value(value):
	_type_menu.visible = value == null
	_value_container.visible = value != null
	if value == null:
		return
	
	_value_expression.deserialise(value.expression)
	_value_expression.configure()


func _emit_size_changed(size_before, second_deferral=false):
	# When removing a value, the size doesn't change on
	# the first idle frame - have to defer a second time.
	if second_deferral:
		size_changed.emit(self.size.y - size_before)
		return
	call_deferred("_emit_size_changed", size_before, true)


func _on_type_menu_id_pressed(id):
	_logger.debug("Value type selected")
	var size_before = self.size.y
	_type_menu.visible = false
	_value_container.visible = true
	_value_expression.clear()
	_value_expression.type = id
	_value_expression.configure()
	call_deferred("_emit_size_changed", size_before)


func _on_clear_button_pressed() -> void:
	var confirm = ConfirmationDialog.new()
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.title = "Please confirm"
	confirm.dialog_text = "Are you sure you want to remove this value? This action cannot be undone."
	confirm.canceled.connect(_on_clear_cancelled.bind(confirm))
	confirm.confirmed.connect(_on_clear_confirmed.bind(confirm))
	get_tree().root.add_child(confirm)
	confirm.show()


func _on_clear_confirmed(confirm):
	get_tree().root.remove_child(confirm)
	self.value_resource = null
	var size_before = self.size.y
	_value_container.visible = false
	_type_menu.visible = true
	call_deferred("_emit_size_changed", size_before)


func _on_clear_cancelled(confirm):
	get_tree().root.remove_child(confirm)


func _on_value_expression_size_changed(amount: Variant) -> void:
	size_changed.emit(amount)


func _on_value_expression_modified() -> void:
	# TODO: Maybe display the overall validation status
	_value_expression.validate()
	if value_resource == null:
		value_resource = ExpressionResource.new()
	# TODO: Serialising the expression every time it is modified like this
	# seems wasteful.
	value_resource.expression = _value_expression.serialise()

@tool
extends "EditorGraphNodeBase.gd"
## Action node UI.


enum ActionAddArgumentMenuId {
	CHARACTER,
	EXPRESSION,
	EXPRESSION_INT,
	EXPRESSION_FLOAT,
	EXPRESSION_STRING,
	EXPRESSION_BOOL,
	DATA_STORE,
	DATA_STORE_TRANSIENT,
	DATA_STORE_DIALOGUE_GRAPH,
	DATA_STORE_LOCAL,
	DATA_STORE_GLOBAL,
}

const TITLE_FONT = preload("styles/TitleOptionFont.tres")

const ExpressionArgument = preload("../controls/arguments/ExpressionArgument.tscn")
const CharacterArgument = preload("../controls/arguments/CharacterArgument.tscn")
const DataStoreArgument = preload("../controls/arguments/DataStoreArgument.tscn")
const ExpressionArgumentClass = preload("../controls/arguments/ExpressionArgument.gd")
const CharacterArgumentClass = preload("../controls/arguments/CharacterArgument.gd")
const DataStoreArgumentClass = preload("../controls/arguments/DataStoreArgument.gd")

const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const ActionMechanism = preload("../../resources/graph/ActionNode.gd").ActionMechanism
const ActionReturnType = preload("../../resources/graph/ActionNode.gd").ActionReturnType
const ActionArgumentType = preload("../../resources/graph/ActionNode.gd").ActionArgumentType

var _characters
var _action_mechanism_option: OptionButton

@onready var _signal_container = $RootContainer/SignalContainer
@onready var _action_name_edit = $RootContainer/SignalContainer/ActionNameEdit
@onready var _method_container = $RootContainer/MethodContainer
@onready var _node_selection_control = $RootContainer/MethodContainer/NodeSelectionControl
@onready var _method_name_edit = $RootContainer/MethodContainer/MethodNameEdit
@onready var _returns_immediately_check = $RootContainer/MethodContainer/ReturnsImmediatelyCheck
@onready var _return_option = $ReturnContainer/GC/ReturnOption
@onready var _return_variable_label = $ReturnContainer/GC/ReturnVariableLabel
@onready var _return_variable_selection_control = $ReturnContainer/GC/ReturnVariableSelectionControl
@onready var _add_argument_button = $ArgumentsContainer/VB/HB/AddArgumentButton
@onready var _arguments_list_container = $ArgumentsContainer/VB/MC/ArgumentsListContainer


func _init():
	_action_mechanism_option = OptionButton.new()
	_action_mechanism_option.item_selected.connect(_on_action_mechanism_option_item_selected)
	_action_mechanism_option.flat = true
	_action_mechanism_option.fit_to_longest_item = true
	_action_mechanism_option.add_theme_font_override("font", TITLE_FONT)
	_action_mechanism_option.add_item("Action (signal)", ActionMechanism.SIGNAL)
	_action_mechanism_option.add_item("Action (method call)", ActionMechanism.METHOD)


func _ready():
	var titlebar = get_titlebar_hbox()
	titlebar.add_child(_action_mechanism_option)
	# By moving to index 0, the empty title label serves as a spacer.
	titlebar.move_child(_action_mechanism_option, 0)
	_action_mechanism_option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_configure_add_argument_button()
	super()


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	_configure_for_action_mechanism(
		n.action_mechanism
	)
	_populate_action_details(
		n.action_mechanism,
		n.node,
		n.action_or_method_name,
		n.returns_immediately,
	)
	_populate_return_details(
		n.return_type,
		n.return_variable,
	)
	_populate_arguments(
		n.arguments
	)


func persist_changes_to_node():
	super.persist_changes_to_node()
	_persist_action_details()
	_persist_return_details()
	_persist_arguments()


func populate_characters(characters):
	_logger.debug("Populating characters")
	_characters = characters
	# TODO: Update any character arguments


func _configure_for_action_mechanism(id):
	_signal_container.visible = (id == ActionMechanism.SIGNAL)
	_method_container.visible = (id == ActionMechanism.METHOD)
	_correct_size()


func _correct_size():
	self.size = Vector2(self.size.x,0)


func _configure_add_argument_button():
	var menu = _add_argument_button.get_popup()
	menu.clear()
	# Children need to be removed or the wrong submenus may show up
	for child in menu.get_children():
		menu.remove_child(child)
	
	#menu.add_item("Expression")
	_add_expressions_sub_menu(menu)
	menu.add_item("Character", ActionAddArgumentMenuId.CHARACTER)
	_add_data_stores_sub_menu(menu)
	
	if not menu.id_pressed.is_connected(_add_argument_menu_item_selected):
		menu.id_pressed.connect(_add_argument_menu_item_selected)


func _add_expressions_sub_menu(menu):
	var submenu = PopupMenu.new()
	submenu.set_name("expression")
	submenu.id_pressed.connect(_add_expression_argument_menu_item_selected)
	
	submenu.add_item("Integer", ActionAddArgumentMenuId.EXPRESSION_INT)
	submenu.add_item("Float", ActionAddArgumentMenuId.EXPRESSION_FLOAT)
	submenu.add_item("String", ActionAddArgumentMenuId.EXPRESSION_STRING)
	submenu.add_item("Boolean", ActionAddArgumentMenuId.EXPRESSION_BOOL)
	
	menu.add_child(submenu)
	menu.add_submenu_item(
		"Expression",
		"expression",
		ActionAddArgumentMenuId.EXPRESSION,
	)


func _add_data_stores_sub_menu(menu):
	var submenu = PopupMenu.new()
	submenu.set_name("datastore")
	submenu.id_pressed.connect(_add_data_store_argument_menu_item_selected)
	
	submenu.add_item("Transient", ActionAddArgumentMenuId.DATA_STORE_TRANSIENT)
	submenu.add_item("Cutscene", ActionAddArgumentMenuId.DATA_STORE_DIALOGUE_GRAPH)
	submenu.add_item("Local", ActionAddArgumentMenuId.DATA_STORE_LOCAL)
	submenu.add_item("Global", ActionAddArgumentMenuId.DATA_STORE_GLOBAL)
	
	menu.add_child(submenu)
	menu.add_submenu_item(
		"Data Store",
		"datastore",
		ActionAddArgumentMenuId.DATA_STORE,
	)


func _add_argument_menu_item_selected(id):
	match id:
		ActionAddArgumentMenuId.CHARACTER:
			_add_character_argument()
	modified.emit()


func _add_expression_argument_menu_item_selected(id):
	match id:
		ActionAddArgumentMenuId.EXPRESSION_INT:
			_add_expression_argument(VariableType.TYPE_INT)
		ActionAddArgumentMenuId.EXPRESSION_FLOAT:
			_add_expression_argument(VariableType.TYPE_FLOAT)
		ActionAddArgumentMenuId.EXPRESSION_STRING:
			_add_expression_argument(VariableType.TYPE_STRING)
		ActionAddArgumentMenuId.EXPRESSION_BOOL:
			_add_expression_argument(VariableType.TYPE_BOOL)
	modified.emit()


func _add_expression_argument(variable_type, expression=null):
	var arg = ExpressionArgument.instantiate()
	arg.type = variable_type
	_add_argument_to_list(arg)
	if expression != null:
		arg.set_expression(expression)


func _add_character_argument(character=null, variant=null):
	var arg = CharacterArgument.instantiate()
	arg.set_characters(_characters)
	_add_argument_to_list(arg)
	if character != null:
		arg.set_character(character)
	if variant != null:
		arg.set_variant(variant)


func _add_data_store_argument_menu_item_selected(id):
	match id:
		ActionAddArgumentMenuId.DATA_STORE_TRANSIENT:
			_add_data_store_argument(VariableScope.SCOPE_TRANSIENT)
		ActionAddArgumentMenuId.DATA_STORE_DIALOGUE_GRAPH:
			_add_data_store_argument(VariableScope.SCOPE_DIALOGUE_GRAPH)
		ActionAddArgumentMenuId.DATA_STORE_LOCAL:
			_add_data_store_argument(VariableScope.SCOPE_LOCAL)
		ActionAddArgumentMenuId.DATA_STORE_GLOBAL:
			_add_data_store_argument(VariableScope.SCOPE_GLOBAL)
	modified.emit()


func _add_data_store_argument(scope):
	var arg = DataStoreArgument.instantiate()
	arg.scope = scope
	_add_argument_to_list(arg)


func _add_argument_to_list(arg):
	arg.ordinal = _arguments_list_container.get_child_count()
	_arguments_list_container.add_child(arg)
	arg.remove_requested.connect(_argument_remove_requested.bind(arg))
	arg.remove_immediately.connect(_argument_remove_immediately.bind(arg))
	arg.modified.connect(_argument_modified)
	arg.configure()


func _argument_modified():
	modified.emit()


func _argument_remove_requested(ordinal, argument):
	var confirm = ConfirmationDialog.new()
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.title = "Please confirm"
	confirm.dialog_text = "Are you sure you want to remove this argument? This action cannot be undone."
	confirm.canceled.connect(_on_argument_remove_cancelled.bind(confirm))
	confirm.confirmed.connect(_on_argument_remove_confirmed.bind(argument, confirm))
	get_tree().root.add_child(confirm)
	confirm.show()


func _argument_remove_immediately(ordinal, argument):
	argument.remove_requested.disconnect(_argument_remove_requested)
	argument.remove_immediately.disconnect(_argument_remove_immediately)
	argument.modified.disconnect(_argument_modified)
	_arguments_list_container.remove_child(argument)
	_recalculate_ordinals()
	_correct_size()


func _recalculate_ordinals():
	var ord = 0
	for child in _arguments_list_container.get_children():
		child.ordinal = ord
		child.refresh()
		ord = ord + 1


func _populate_action_details(
	action_mechanism,
	node_path,
	action_or_method_name,
	returns_immediately,
):
	_action_mechanism_option.select(
		_action_mechanism_option.get_item_index(
			action_mechanism
		)
	)
	if action_mechanism == ActionMechanism.SIGNAL:
		_action_name_edit.text = action_or_method_name
	else:
		_node_selection_control.populate(node_path)
		_method_name_edit.text = action_or_method_name
		_returns_immediately_check.button_pressed = returns_immediately


func _populate_arguments(arguments):
	for child in _arguments_list_container.get_children():
		_arguments_list_container.remove_child(child)
	for argument in arguments:
		_populate_argument(argument)
	_recalculate_ordinals()
	_correct_size()


func _populate_argument(argument):
	match argument['argument_type']:
		ActionArgumentType.DATA_STORE:
			_populate_data_store_argument(argument)
		ActionArgumentType.CHARACTER:
			_populate_character_argument(argument)
		ActionArgumentType.EXPRESSION:
			_populate_expression_argument(argument)


func _populate_data_store_argument(argument):
	_add_data_store_argument(argument['data_store_type'])


func _populate_character_argument(argument):
	_add_character_argument(
		argument['character'],
		argument['variant'],
	)


func _populate_expression_argument(argument):
	_add_expression_argument(
		argument['variable_type'],
		argument['expression'],
	)


func _populate_return_details(return_type, variable):
	_return_option.select(
		_return_option.get_item_index(
			return_type
		)
	)
	_configure_for_return_type(return_type)
	if return_type == ActionReturnType.ASSIGN_TO_VARIABLE:
		if variable != null and not len(variable) == 0:
			_return_variable_selection_control.set_variable(
				variable,
			)


func _persist_action_details():
	node_resource.action_mechanism = _action_mechanism_option.get_selected_id()
	
	if node_resource.action_mechanism ==ActionMechanism.METHOD:
		node_resource.action_or_method_name = _method_name_edit.text
		node_resource.node = _node_selection_control.get_selected_path()
		node_resource.returns_immediately = _returns_immediately_check.button_pressed
	else:
		node_resource.action_or_method_name = _action_name_edit.text
		node_resource.node = NodePath()
		node_resource.returns_immediately = false


func _persist_return_details():
	node_resource.return_type = _return_option.get_selected_id()
	if node_resource.return_type == ActionReturnType.ASSIGN_TO_VARIABLE:
		node_resource.return_variable = _return_variable_selection_control.get_variable()
	else:
		node_resource.return_variable = {}


func _persist_arguments():
	node_resource.arguments.clear()
	for argument_node in _arguments_list_container.get_children():
		_persist_argument(argument_node)


func _persist_argument(argument_node):
	var argument = {}
	if argument_node is ExpressionArgumentClass:
		argument['argument_type'] = ActionArgumentType.EXPRESSION
		argument['variable_type'] = argument_node.type
		argument['expression'] = argument_node.get_expression()
	elif argument_node is CharacterArgumentClass:
		argument['argument_type'] = ActionArgumentType.CHARACTER
		argument['character'] = argument_node.get_selected_character()
		argument['variant'] = argument_node.get_selected_variant()
	elif argument_node is DataStoreArgumentClass:
		argument['argument_type'] = ActionArgumentType.DATA_STORE
		argument['data_store_type'] = argument_node.scope
	node_resource.arguments.append(argument)


func _configure_for_return_type(id):
	_return_variable_label.visible = (id == ActionReturnType.ASSIGN_TO_VARIABLE)
	_return_variable_selection_control.visible = (id == ActionReturnType.ASSIGN_TO_VARIABLE)
	_correct_size()


func _get_closest_argument(at_position, target):
	var children = _arguments_list_container.get_children()
	var distance_to_child = null
	var closest = null
	var add_before = false
	var y = at_position.y
	var distances = {}

	# Calculate the distance to each child.
	for child in children:
		var top = child.offset_top
		var bottom = child.offset_bottom
		# This calculates the centre of the child.
		distances[child] = abs(y - (top + bottom) / 2.0)
	
	# Determine which child is the closest.
	for child in distances:
		if distance_to_child == null:
			distance_to_child = distances[child]
			closest = child
			continue
		if distances[child] < distance_to_child:
			distance_to_child = distances[child]
			closest = child
	
	# Determine if we are before or after the identified closest child
	if closest != null:
		var top = closest.offset_top
		var bottom = closest.offset_bottom
		var centre = (top + bottom) / 2.0
		add_before = y < centre
	
	return [closest, add_before]


func _add_at_position(at_position, target):
	var cab = _get_closest_argument(at_position, target)
	var closest = cab[0]
	var add_before = cab[1]
	
	# Don't insert if the target was closest to itself!
	if closest == null or closest != target:
		_arguments_list_container.add_child(target)
	if closest != null:
		# Don't move if the target was closest to itself!
		if closest != target:
			if add_before:
				_arguments_list_container.move_child(target, closest.get_index())
			else:
				_arguments_list_container.move_child(target, closest.get_index() + 1)
	target.remove_requested.connect(_argument_remove_requested.bind(target))
	target.remove_immediately.connect(_argument_remove_immediately.bind(target))


func _move_to_position(at_position, target):
	var cab = _get_closest_argument(at_position, target)
	var closest = cab[0]
	var add_before = cab[1]
	
	if closest != null:
		var closest_index = closest.get_index()
		var target_index = target.get_index()
		var move_index = closest_index if add_before else closest_index + 1
		if target_index < closest_index:
			move_index = move_index - 1
		_arguments_list_container.move_child(target, move_index)


func _on_action_mechanism_option_item_selected(index):
	var id = _action_mechanism_option.get_item_id(index)
	_configure_for_action_mechanism(
		id
	)
	modified.emit()


func _on_argument_remove_confirmed(argument, confirm):
	get_tree().root.remove_child(confirm)
	argument.remove_requested.disconnect(_argument_remove_requested)
	argument.remove_immediately.disconnect(_argument_remove_immediately)
	_arguments_list_container.remove_child(argument)
	_recalculate_ordinals()
	_correct_size()
	modified.emit()


func _on_argument_remove_cancelled(confirm):
	get_tree().root.remove_child(confirm)


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_return_option_item_selected(index):
	var id = _return_option.get_item_id(index)
	_configure_for_return_type(id)
	modified.emit()


func _on_argument_dropped(arg, at_position):
	if arg.get_parent() == _arguments_list_container:
		_move_to_position(at_position, arg)
	else:
		arg.remove_from_parent()
		_add_at_position(at_position, arg)
	_recalculate_ordinals()
	_correct_size()
	modified.emit()


func _on_method_name_edit_text_changed(new_text):
	modified.emit()


func _on_returns_immediately_check_pressed():
	modified.emit()


func _on_node_selection_control_node_cleared():
	modified.emit()


func _on_node_selection_control_node_selected(path):
	modified.emit()


func _on_return_variable_selection_control_variable_selected(variable):
	modified.emit()

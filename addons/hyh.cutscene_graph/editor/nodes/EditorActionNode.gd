@tool
extends "EditorGraphNodeBase.gd"

const TITLE_FONT = preload("res://addons/hyh.cutscene_graph/editor/nodes/styles/TitleOptionFont.tres")

const ExpressionArgument = preload("res://addons/hyh.cutscene_graph/editor/controls/arguments/ExpressionArgument.tscn")
const CharacterArgument = preload("res://addons/hyh.cutscene_graph/editor/controls/arguments/CharacterArgument.tscn")
const DataStoreArgument = preload("res://addons/hyh.cutscene_graph/editor/controls/arguments/DataStoreArgument.tscn")
const ExpressionArgumentClass = preload("res://addons/hyh.cutscene_graph/editor/controls/arguments/ExpressionArgument.gd")
const CharacterArgumentClass = preload("res://addons/hyh.cutscene_graph/editor/controls/arguments/CharacterArgument.gd")
const DataStoreArgumentClass = preload("res://addons/hyh.cutscene_graph/editor/controls/arguments/DataStoreArgument.gd")


const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const ActionMechanism = preload("../../resources/graph/ActionNode.gd").ActionMechanism
const ActionReturnType = preload("../../resources/graph/ActionNode.gd").ActionReturnType
const ActionArgumentType = preload("../../resources/graph/ActionNode.gd").ActionArgumentType

enum ActionAddArgumentMenuId {
	CHARACTER,
	EXPRESSION,
	EXPRESSION_INT,
	EXPRESSION_FLOAT,
	EXPRESSION_STRING,
	EXPRESSION_BOOL,
	DATA_STORE,
	DATA_STORE_TRANSIENT,
	DATA_STORE_CUTSCENE,
	DATA_STORE_LOCAL,
	DATA_STORE_GLOBAL,
}

@onready var SignalContainer = get_node("RootContainer/SignalContainer")
@onready var ActionNameEdit = get_node("RootContainer/SignalContainer/ActionNameEdit")

@onready var MethodContainer = get_node("RootContainer/MethodContainer")
@onready var NodeSelectionControl = get_node("RootContainer/MethodContainer/NodeSelectionControl")
@onready var MethodNameEdit = get_node("RootContainer/MethodContainer/MethodNameEdit")
@onready var ReturnsImmediatelyCheck = get_node("RootContainer/MethodContainer/ReturnsImmediatelyCheck")

@onready var ReturnContainer = get_node("ReturnContainer")
@onready var ReturnOption = get_node("ReturnContainer/GridContainer/ReturnOption")
@onready var ReturnVariableLabel = get_node("ReturnContainer/GridContainer/ReturnVariableLabel")
@onready var ReturnVariableSelectionControl = get_node("ReturnContainer/GridContainer/ReturnVariableSelectionControl")

@onready var AddArgumentButton = get_node("ArgumentsContainer/VB/HB/AddArgumentButton")
@onready var ArgumentsListContainer = get_node("ArgumentsContainer/VB/MC/ArgumentsListContainer")

var ActionMechanismOption: OptionButton

var _characters


func _init():
	ActionMechanismOption = OptionButton.new()
	ActionMechanismOption.item_selected.connect(_on_action_mechanism_option_item_selected)
	ActionMechanismOption.flat = true
	ActionMechanismOption.fit_to_longest_item = true
	ActionMechanismOption.add_theme_font_override("font", TITLE_FONT)
	ActionMechanismOption.add_item("Action (signal)", ActionMechanism.SIGNAL)
	ActionMechanismOption.add_item("Action (method call)", ActionMechanism.METHOD)


func _ready():
	var titlebar = get_titlebar_hbox()
	titlebar.add_child(ActionMechanismOption)
	# By moving to index 0, the empty title label serves as a spacer.
	titlebar.move_child(ActionMechanismOption, 0)
	ActionMechanismOption.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_configure_add_argument_button()
	super()


func _on_action_mechanism_option_item_selected(index):
	var id = ActionMechanismOption.get_item_id(index)
	_configure_for_action_mechanism(
		id
	)


func _configure_for_action_mechanism(id):
	SignalContainer.visible = (id == ActionMechanism.SIGNAL)
	MethodContainer.visible = (id == ActionMechanism.METHOD)
	_correct_size()


func _correct_size():
	self.size = Vector2(self.size.x,0)


func _configure_add_argument_button():
	var menu = AddArgumentButton.get_popup()
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
	submenu.add_item("Cutscene", ActionAddArgumentMenuId.DATA_STORE_CUTSCENE)
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
		ActionAddArgumentMenuId.DATA_STORE_CUTSCENE:
			_add_data_store_argument(VariableScope.SCOPE_CUTSCENE)
		ActionAddArgumentMenuId.DATA_STORE_LOCAL:
			_add_data_store_argument(VariableScope.SCOPE_LOCAL)
		ActionAddArgumentMenuId.DATA_STORE_GLOBAL:
			_add_data_store_argument(VariableScope.SCOPE_GLOBAL)


func _add_data_store_argument(scope):
	var arg = DataStoreArgument.instantiate()
	arg.scope = scope
	_add_argument_to_list(arg)


func _add_argument_to_list(arg):
	arg.ordinal = ArgumentsListContainer.get_child_count()
	ArgumentsListContainer.add_child(arg)
	arg.remove_requested.connect(_argument_remove_requested.bind(arg))
	arg.remove_immediately.connect(_argument_remove_immediately.bind(arg))
	arg.configure()


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
	ArgumentsListContainer.remove_child(argument)
	_recalculate_ordinals()
	_correct_size()


func _on_argument_remove_confirmed(argument, confirm):
	get_tree().root.remove_child(confirm)
	argument.remove_requested.disconnect(_argument_remove_requested)
	argument.remove_immediately.disconnect(_argument_remove_immediately)
	ArgumentsListContainer.remove_child(argument)
	_recalculate_ordinals()
	_correct_size()


func _on_argument_remove_cancelled(confirm):
	get_tree().root.remove_child(confirm)


func _recalculate_ordinals():
	var ord = 0
	for child in ArgumentsListContainer.get_children():
		child.ordinal = ord
		child.refresh()
		ord = ord + 1


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


func _populate_action_details(
	action_mechanism,
	node_path,
	action_or_method_name,
	returns_immediately,
):
	ActionMechanismOption.select(
		ActionMechanismOption.get_item_index(
			action_mechanism
		)
	)
	if action_mechanism == ActionMechanism.SIGNAL:
		ActionNameEdit.text = action_or_method_name
	else:
		NodeSelectionControl.populate(node_path)
		MethodNameEdit.text = action_or_method_name
		ReturnsImmediatelyCheck.button_pressed = returns_immediately


func _populate_arguments(arguments):
	for child in ArgumentsListContainer.get_children():
		ArgumentsListContainer.remove_child(child)
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
	ReturnOption.select(
		ReturnOption.get_item_index(
			return_type
		)
	)
	_configure_for_return_type(return_type)
	if return_type == ActionReturnType.ASSIGN_TO_VARIABLE:
		if variable != null and not len(variable) == 0:
			ReturnVariableSelectionControl.set_variable(
				variable,
			)


func persist_changes_to_node():
	super.persist_changes_to_node()
	_persist_action_details()
	_persist_return_details()
	_persist_arguments()


func _persist_action_details():
	node_resource.action_mechanism = ActionMechanismOption.get_selected_id()
	
	if node_resource.action_mechanism ==ActionMechanism.METHOD:
		node_resource.action_or_method_name = MethodNameEdit.text
		node_resource.node = NodeSelectionControl.get_selected_path()
		node_resource.returns_immediately = ReturnsImmediatelyCheck.button_pressed
	else:
		node_resource.action_or_method_name = ActionNameEdit.text
		node_resource.node = NodePath()
		node_resource.returns_immediately = false


func _persist_return_details():
	node_resource.return_type = ReturnOption.get_selected_id()
	if node_resource.return_type == ActionReturnType.ASSIGN_TO_VARIABLE:
		node_resource.return_variable = ReturnVariableSelectionControl.get_variable()
	else:
		node_resource.return_variable = {}


func _persist_arguments():
	node_resource.arguments.clear()
	for argument_node in ArgumentsListContainer.get_children():
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


func populate_characters(characters):
	Logger.debug("Populating characters")
	_characters = characters
	# TODO: Update any character arguments


func _on_gui_input(ev):
	super._on_gui_input(ev)


func _on_action_name_edit_text_changed(new_text):
	emit_signal("modified")


func _on_argument_edit_text_changed(new_text):
	emit_signal("modified")


func _on_return_option_item_selected(index):
	var id = ReturnOption.get_item_id(index)
	_configure_for_return_type(id)


func _configure_for_return_type(id):
	ReturnVariableLabel.visible = (id == ActionReturnType.ASSIGN_TO_VARIABLE)
	ReturnVariableSelectionControl.visible = (id == ActionReturnType.ASSIGN_TO_VARIABLE)
	_correct_size()


func _on_argument_dropped(arg, at_position):
	if arg.get_parent() == ArgumentsListContainer:
		_move_to_position(at_position, arg)
	else:
		arg.remove_from_parent()
		_add_at_position(at_position, arg)
	_recalculate_ordinals()
	_correct_size()


func _get_closest_argument(at_position, target):
	var children = ArgumentsListContainer.get_children()
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
		ArgumentsListContainer.add_child(target)
	if closest != null:
		# Don't move if the target was closest to itself!
		if closest != target:
			if add_before:
				ArgumentsListContainer.move_child(target, closest.get_index())
			else:
				ArgumentsListContainer.move_child(target, closest.get_index() + 1)
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
		ArgumentsListContainer.move_child(target, move_index)

@tool
extends VBoxContainer
## In-editor graph previewer.


signal starting_preview()
signal stopping_preview()

enum StoresMenuItemId {
	ADD_VARIABLE,
	SEP1,
	LOAD_ADD,
	LOAD_REPLACE,
	SAVE,
	SEP2,
	CLEAR_ALL,
}

enum DialogueColour {
	DEFAULT,
	GRAY,
	TOMATO,
	APRICOT,
	BITTERSWEET,
	COLOMBIA,
	TROPICAL,
	SAFFRON,
	PINK,
	ORANGE
}

enum DialogueColourResourceIndex {
	LEFT_PANEL,
	LEFT_INDICATOR,
	RIGHT_PANEL,
	RIGHT_INDICATOR
}

const Dialogs = preload("../dialogs/Dialogs.gd")
const Logging = preload("../../utility/Logging.gd")

const VISIBLE_ICON = preload("../../icons/icon_visible.svg")
const INVISIBLE_ICON = preload("../../icons/icon_invisible.svg")
const NOTIFICATION_ICON = preload("../../icons/icon_notification.svg")
const NOTIFICATION_DISABLED_ICON = preload("../../icons/icon_notification_disabled.svg")

const DialogueEvent = preload("dialogue_events/DialogueEvent.tscn")
const PlayerDialogueEvent = preload("dialogue_events/PlayerDialogueEvent.tscn")
const StaticInformationalEvent = preload("dialogue_events/StaticInformationalEvent.tscn")
const FinalStaticInformationalEvent = preload("dialogue_events/FinalStaticInformationalEvent.tscn")
const ChoiceEvent = preload("dialogue_events/ChoiceEvent.tscn")

const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const Controller = preload("../DigressionDialogueController.gd")
const ProceedSignal = Controller.ProceedSignal
const CharacterDetails = Controller.CharacterDetails
const EditorEntryPointAnchorNode = preload("../../editor/nodes/EditorEntryPointAnchorNode.gd")

const DIALOGUE_PANEL_STYLE_BOX_LEFT = preload("dialogue_events/styles/dialogue_box_panel_green_left.tres")
const DIALOGUE_PANEL_STYLE_BOX_RIGHT = preload("dialogue_events/styles/dialogue_box_panel_green_right.tres")
const DIALOGUE_INDICATOR_STYLE_BOX_LEFT = preload("dialogue_events/styles/dialogue_box_indicator_green_left.tres")
const DIALOGUE_INDICATOR_STYLE_BOX_RIGHT = preload("dialogue_events/styles/dialogue_box_indicator_green_right.tres")
const COLOUR_INDICATOR_ICON = preload("../../icons/icon_colour_indicator.svg")

var _dialogue_colours = [
	Color("#54D8BD"),
	Color("#949CBC"),
	Color("#F55536"),
	Color("#FFD8BE"),
	Color("#CC444B"),
	Color("#BBD5ED"),
	Color("#A288E3"),
	Color("#F1C146"),
	Color("#F56476"),
	Color("#EB8B42")
]

var _colour_pool = [
	DialogueColour.APRICOT,
	DialogueColour.BITTERSWEET,
	DialogueColour.COLOMBIA,
	DialogueColour.GRAY,
	DialogueColour.ORANGE,
	DialogueColour.PINK,
	DialogueColour.SAFFRON,
	DialogueColour.TOMATO,
	DialogueColour.TROPICAL,
]

var _dialogue_colour_resources = {}

var _graph_stack = []
var _current_process
var _play_audio = true
var _show_processing = false
var _fast_forward = false
var _characterwise_display = false
var _character_colours = {}
var _transient_state

var _dialogue_scrollbar
var _continue_button
var _transient_store_root: TreeItem
var _dialogue_graph_store_root: TreeItem
var _local_store_root: TreeItem
var _global_store_root: TreeItem
var _logger = Logging.new("Digression Dialogue Graph Preview", Logging.DGE_NODES_LOG_LEVEL)

@onready var _show_processing_checkbox = $HSplitContainer/HSplitContainer/VB/PanelContainer/MC/BeginContainer/VB/ShowProcessingCheckBox
@onready var _entry_point_option = $HSplitContainer/HSplitContainer/VB/PanelContainer/MC/BeginContainer/VB/EntryPointContainer/EntryPointOption
@onready var _graph_mini_map = $HSplitContainer/HSplitContainer/VSplitContainer/GraphMiniMap
@onready var _dialogue_scroll_container = $HSplitContainer/HSplitContainer/VB/PanelContainer/MC/DialogueScrollContainer
@onready var _dialogue_container = $HSplitContainer/HSplitContainer/VB/PanelContainer/MC/DialogueScrollContainer/MC/DialogueContainer
@onready var _dialogue_container_panel = $HSplitContainer/HSplitContainer/VB/PanelContainer
@onready var _begin_container = $HSplitContainer/HSplitContainer/VB/PanelContainer/MC/BeginContainer
@onready var _breadcrumbs = $TitleBar/GraphBreadcrumbs
@onready var _characters_tree = $HSplitContainer/HSplitContainer/VSplitContainer/VB/CharactersTree
@onready var _variable_stores_tree = $HSplitContainer/VariableStoresContainer/VariableStoresTree
@onready var _start_button = $HSplitContainer/HSplitContainer/VB/HB/StartButton
@onready var _stop_button = $HSplitContainer/HSplitContainer/VB/HB/StopButton
@onready var _restart_button = $HSplitContainer/HSplitContainer/VB/HB/RestartButton
@onready var _play_audio_button = $HSplitContainer/HSplitContainer/VB/HB/PlayAudioButton
@onready var _show_processing_button = $HSplitContainer/HSplitContainer/VB/HB/ShowProcessingButton
@onready var _fast_forward_button = $HSplitContainer/HSplitContainer/VB/HB/FastForwardButton
@onready var _characterwise_display_button = $HSplitContainer/HSplitContainer/VB/HB/CharacterwiseButton
@onready var _stores_menu_button = $HSplitContainer/VariableStoresContainer/HB/StoresMenuButton
@onready var _controller = $GraphController
@onready var _dialogue_graph = $DialogueGraph
@onready var _dialogue_displayed_player = $DialogueDisplayedPlayer
@onready var _character_displayed_player = $CharacterDisplayedPlayer


func _ready():
	_dialogue_container_panel.add_theme_stylebox_override("panel", get_theme_stylebox("TextureRegionPreviewBG", "EditorStyles"))
	_clear_dialogue()
	_dialogue_graph.set_controller(_controller)
	_connect_internal_signals()
	_dialogue_scrollbar = _dialogue_scroll_container.get_v_scroll_bar()
	_dialogue_scrollbar.changed.connect(_on_scroll_changed)
	_create_dialogue_colour_resources()
	_stores_menu_button.get_popup().id_pressed.connect(
		_on_stores_menu_id_pressed
	)
	_configure_entry_point_options()


func _create_dialogue_colour_resources():
	for i in range(10):
		_dialogue_colour_resources[i] = _create_dialogue_colour_set(
			_dialogue_colours[i]
		)


func _create_dialogue_colour_set(colour):
	var left_panel = DIALOGUE_PANEL_STYLE_BOX_LEFT.duplicate()
	var right_panel = DIALOGUE_PANEL_STYLE_BOX_RIGHT.duplicate()
	var left_indicator = DIALOGUE_INDICATOR_STYLE_BOX_LEFT.duplicate()
	var right_indicator = DIALOGUE_INDICATOR_STYLE_BOX_RIGHT.duplicate()
	left_panel.bg_color = colour
	left_panel.border_color = colour
	right_panel.bg_color = colour
	right_panel.border_color = colour
	left_indicator.bg_color = colour
	left_indicator.border_color = colour
	right_indicator.bg_color = colour
	right_indicator.border_color = colour
	return [left_panel, left_indicator, right_panel, right_indicator]


func _connect_internal_signals():
	var i = _controller._internal
	i.processed_set_node.connect(_processed_set_node)
	i.processed_match_branch_node.connect(_processed_match_branch_node)
	i.processed_if_branch_node.connect(_processed_if_branch_node)
	i.processed_random_node.connect(_processed_random_node)
	i.processed_repeat_node.connect(_processed_repeat_node)
	i.processed_jump_node.connect(_processed_jump_node)
	i.processed_anchor_node.connect(_processed_anchor_node)
	i.processed_routing_node.connect(_processed_routing_node)
	i.processed_exit_node.connect(_processed_exit_node)


func _configure_entry_point_options():
	if _dialogue_graph == null or _dialogue_graph.dialogue_graph == null:
		return
	
	_entry_point_option.clear()
	var id: int = 0
	_entry_point_option.add_item(
		EditorEntryPointAnchorNode.ENTRY_POINT_ANCHOR_NAME,
		id
	)
	_entry_point_option.selected = 0
	var anchor_maps = _dialogue_graph.dialogue_graph.get_anchor_maps()
	var by_name = anchor_maps[0]
	var names = by_name.keys()
	names.sort()
	for name in names:
		if name == EditorEntryPointAnchorNode.ENTRY_POINT_ANCHOR_NAME:
			continue
		id += 1
		_entry_point_option.add_item(name, id)


func _processed_routing_node():
	if not _show_processing:
		return
	_add_static_processing_event("Processed routing node...")


func _processed_anchor_node(anchor_name):
	if not _show_processing:
		return
	_add_static_processing_event("Processed anchor node \"%s\"..." % anchor_name)


func _processed_jump_node(destination_name):
	if not _show_processing:
		return
	if destination_name == null or destination_name == "":
		_add_static_processing_event("Processed jump node with no destination...")
	else:
		_add_static_processing_event(
			"Processed jump node with destination \"%s\"..." % destination_name
		)


func _processed_repeat_node():
	if not _show_processing:
		return
	_add_static_processing_event("Processed repeat node...")


func _processed_random_node():
	if not _show_processing:
		return
	# TODO: Will want to show more information on this.
	_add_static_processing_event("Processed random node...")


func _processed_match_branch_node(variable, scope, value, branch_matched):
	if not _show_processing:
		return
	# TODO: Will want to show more information on this.
	_add_static_processing_event("Processed branch (match) node...")


func _processed_if_branch_node(branch_matched):
	if not _show_processing:
		return
	# TODO: Will want to show more information on this.
	_add_static_processing_event("Processed branch (if) node...")


func _processed_set_node(variable, scope, value):
	if not _show_processing:
		return
	# TODO: Will want to show more information on this.
	_add_static_processing_event(
		'Set %s variable "%s" to "%s"...' % [
			_get_scope_description(scope),
			variable,
			value,
		]
	)


func _processed_exit_node():
	if not _show_processing:
		return
	_add_static_processing_event("Processed exit node...")


func _get_scope_description(scope):
	match scope:
		VariableScope.SCOPE_TRANSIENT:
			return "transient"
		VariableScope.SCOPE_DIALOGUE_GRAPH:
			return "dialogue graph"
		VariableScope.SCOPE_LOCAL:
			return "local"
		VariableScope.SCOPE_GLOBAL:
			return "global"


func _add_static_processing_event(text):
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate(text)


func prepare_to_preview_graph(graph):
	_character_colours = {}
	_clear_dialogue()
	_graph_stack = []
	_graph_stack.append(graph)
	_breadcrumbs.populate(_graph_stack)
	_dialogue_graph.dialogue_graph = graph
	_show_hide(_begin_container, _dialogue_scroll_container)
	_assign_colours_to_characters(graph.characters)
	_populate_characters(graph.characters)
	_initialise_variable_stores_tree()
	# TODO: This clear is resulting in a bunch of errors when
	# a graph is re-displayed for some reason.
	_graph_mini_map.clear()
	_graph_mini_map.display_graph(graph)
	_configure_entry_point_options()


func _reset_to_root_graph():
	var graph = _graph_stack[0]
	_graph_stack = [graph]
	_breadcrumbs.populate(_graph_stack)
	_dialogue_graph.dialogue_graph = graph
	_assign_colours_to_characters(graph.characters)
	_populate_characters(graph.characters)
	# TODO: This clear is resulting in a bunch of errors when
	# a graph is re-displayed for some reason.
	_graph_mini_map.clear()
	_graph_mini_map.display_graph(graph)


func _assign_colours_to_characters(characters):
	for character in characters:
		if _character_colours.has(character):
			continue
		if character.is_player:
			_character_colours[character] = DialogueColour.DEFAULT
			continue
		# If there are more than 10 characters we can't be too picky about
		# avoiding duplicates - but avoid the "player" colour
		if len(_colour_pool) == 0:
			_character_colours[character] = (randi() % 9) + 1
			continue
		var selected = _colour_pool.pick_random()
		_colour_pool.remove_at(_colour_pool.find(selected))
		_character_colours[character] = selected


func _focus_current_node_in_minimap():
	_graph_mini_map.focus_on_node(_get_context().current_node)


func _populate_characters(characters):
	_characters_tree.clear()
	_characters_tree.set_column_title(0, "Colour")
	_characters_tree.set_column_title(1, "Name")
	_characters_tree.set_column_title(2, "Is Player")
	_characters_tree.set_column_expand(0, false)
	_characters_tree.set_column_expand(1, true)
	
	var root = _characters_tree.create_item()
	for character in characters:
		var c = _characters_tree.create_item(root)
		c.set_icon(0, COLOUR_INDICATOR_ICON)
		c.set_icon_modulate(0, _dialogue_colours[_character_colours[character]])
		c.set_text(1, character.get_full_name())
		c.set_cell_mode(2, TreeItem.TreeCellMode.CELL_MODE_CHECK)
		c.set_checked(2, character.is_player)


func _initialise_variable_stores_tree():
	_variable_stores_tree.clear()
	_variable_stores_tree.set_column_title(0, "Variable")
	_variable_stores_tree.set_column_title(1, "Value")
	_variable_stores_tree.set_column_expand(0, true)
	var root = _variable_stores_tree.create_item()
	_transient_store_root = _variable_stores_tree.create_item(root)
	_transient_store_root.set_text(0, "Transient")
	_dialogue_graph_store_root = _variable_stores_tree.create_item(root)
	_dialogue_graph_store_root.set_text(0, "Dialogue Graph")
	_local_store_root = _variable_stores_tree.create_item(root)
	_local_store_root.set_text(0, "Local")
	_global_store_root = _variable_stores_tree.create_item(root)
	_global_store_root.set_text(0, "Global")


func _update_variable_stores_tree():
	# Note that this method examines "private" properties of the controller
	_update_variable_stores_branch(
		_transient_store_root,
		_get_context().transient_store
	)
	_update_variable_stores_branch(
		_dialogue_graph_store_root,
		_get_context().dialogue_graph_state_store
	)
	_update_variable_stores_branch(
		_local_store_root,
		_get_context().local_store.store_data
	)
	_update_variable_stores_branch(
		_global_store_root,
		_get_context().global_store.store_data
	)


func _update_variable_stores_branch(branch_root, store):
	# Need to:
	# 1) Find and update existing entries
	# 2) Add new entries
	# 3) Remove deleted entries
	var existing = []
	var leaves = branch_root.get_children()
	for leaf in leaves:
		var variable = leaf.get_text(0)
		existing.append(variable)
		if store.has(variable):
			var value = store.get(variable)
			if typeof(value) == TYPE_BOOL:
				leaf.set_checked(1, value)
			else:
				leaf.set_text(1, "%s" % store.get(variable))
		else:
			# Deleted
			branch_root.remove_child(leaf)
			leaf.free()
	# Check for new
	for key in store.keys():
		if key in existing:
			continue
		# Omit "private" variables
		if not key.is_empty() and key.left(1) == "_":
			continue
		var ni = _variable_stores_tree.create_item(branch_root)
		ni.set_text(0, key)
		var value = store.get(key)
		if typeof(value) == TYPE_BOOL:
			ni.set_cell_mode(1, TreeItem.TreeCellMode.CELL_MODE_CHECK)
			ni.set_checked(1, value)
		else:
			ni.set_text(1, "%s" % store.get(key))
		ni.set_editable(1, true)


func _show_hide(show, hide):
	show.visible = true
	hide.visible = false


func _set_control_states(running):
	_start_button.disabled = running
	_stop_button.disabled = not running
	_restart_button.disabled = not running


func _clear_dialogue():
	for child in _dialogue_container.get_children():
		_dialogue_container.remove_child(child)
		child.free()
	_continue_button = Button.new()
	_continue_button.text = "Continue"
	_continue_button.icon = preload("../../icons/icon_play.svg")
	_dialogue_container.add_child(_continue_button)
	_continue_button.pressed.connect(_on_continue_requested)
	_continue_button.shortcut = Shortcut.new()
	_continue_button.shortcut.resource_name = "Continue"
	var enter_key_event = InputEventKey.new()
	enter_key_event.keycode = KEY_ENTER
	enter_key_event.pressed = true
	var space_key_event = InputEventKey.new()
	space_key_event.keycode = KEY_SPACE
	space_key_event.pressed = true
	_continue_button.shortcut.events.append(
		enter_key_event
	)
	_continue_button.shortcut.events.append(
		space_key_event
	)
	_continue_button.hide()


func _start_processing():
	_logger.debug("Triggering Graph")
	#_show_processing = _show_processing_checkbox.button_pressed
	# TODO: `_show_processing` will require setting something on the controller
	# as well, and probably connecting events.
	_show_hide(_dialogue_scroll_container, _begin_container)
	_set_control_states(true)
	starting_preview.emit()
	_clear_dialogue()
	_transient_state = _get_context().transient_store.duplicate()
	var entry_point = _entry_point_option.get_item_text(
		_entry_point_option.selected
	)
	_dialogue_graph.trigger(entry_point)


func _stop_processing():
	_logger.debug("Stopping")
	_set_control_states(false)
	_controller.cancel()
	_get_context().transient_store = _transient_state.duplicate()
	_hide_continue()
	if _dialogue_container.get_child_count() >= 2:
		var last_event = _dialogue_container.get_child(-2)
		if last_event != null and "cancel" in last_event:
			last_event.cancel()
	stopping_preview.emit()


func _prepare_to_wait(process):
	_current_process = process
	_continue_button.visible = true


func _hide_continue():
	_continue_button.visible = false


func _insert_event(ev):
	_dialogue_container.add_child(ev)
	_dialogue_container.move_child(_continue_button, -1)


func _action_method(method_name, immediate_return, arguments):
	_logger.debug("Action Method Called")
	var user_arguments = arguments
	if not immediate_return:
		user_arguments = arguments.slice(0, -1)
	
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	var event_text = "Action method \"%s\" called" % method_name
	
	var arguments_text = _prepare_arguments_text(arguments)
	
	if not arguments_text.is_empty():
		event_text = "%s with arguments: %s" % [
			event_text,
			arguments_text
		]
	n.populate(event_text, "The effects of actions cannot be modelled by the previewer.")
	_update_variable_stores_tree()
	_focus_current_node_in_minimap()
	
	if not immediate_return:
		var process = arguments[-1]
		if _fast_forward:
			process.proceed()
		else:
			_prepare_to_wait(process)


func _prepare_arguments_text(arguments):
	var argument_descriptions = []
	for argument in arguments:
		match typeof(argument):
			TYPE_NIL:
				argument_descriptions.append("null")
			TYPE_OBJECT:
				if argument is ProceedSignal:
					argument_descriptions.append(
						"Proceed signal object"
					)
				elif argument is CharacterDetails:
					argument_descriptions.append(
						"Character (%s)" % argument.character.character_display_name
					)
				elif argument is Node:
					argument_descriptions.append("Data store")
				else:
					# TODO: Handle custom 
					argument_descriptions.append("Object")
			TYPE_DICTIONARY:
				argument_descriptions.append("Data store")
			TYPE_STRING, TYPE_STRING_NAME:
				argument_descriptions.append('"%s"' % argument)
			_:
				argument_descriptions.append(str(argument))
	return ", ".join(argument_descriptions)


func _scroll_to_bottom():
	_dialogue_scroll_container.set_deferred(
		"scroll_vertical",
		_dialogue_scroll_container.get_v_scroll_bar().max_value
	)


func _set_show_processing_button_state(show):
	_show_processing_button.set_pressed_no_signal(show)
	if show:
		_show_processing_button.icon = VISIBLE_ICON
	else:
		_show_processing_button.icon = INVISIBLE_ICON


func _set_show_processing_checkbox_state(show):
	_show_processing_checkbox.set_pressed_no_signal(show)


func _save_stores():
	var dialog = EditorFileDialog.new()
	get_tree().root.add_child(dialog)
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.json", "JSON Files")
	dialog.canceled.connect(_on_dialog_cancelled.bind(dialog))
	dialog.file_selected.connect(_on_store_save_file_selected.bind(dialog))
	dialog.popup_centered(Vector2i(800, 600))


func _load_stores(replace):
	var dialog = EditorFileDialog.new()
	get_tree().root.add_child(dialog)
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.json", "JSON Files")
	dialog.canceled.connect(_on_dialog_cancelled.bind(dialog))
	dialog.file_selected.connect(_on_store_load_file_selected.bind(replace, dialog))
	dialog.popup_centered(Vector2i(800, 600))


func _get_context():
	return _controller._context


func clear_variable_stores():
	_get_context().transient_store.clear()
	_get_context().dialogue_graph_state_store.clear()
	_get_context().local_store.store_data.clear()
	_get_context().global_store.store_data.clear()


func _show_add_variable_dialog():
	var selected := await Dialogs.select_variable(null, self)
	if not selected.is_empty():
		_add_variable(selected)


func _add_variable(variable: Dictionary) -> void:
	var val = _get_default_value_for_type(variable['type'])
	var name = variable['name']
	var store
	match variable['scope']:
		VariableScope.SCOPE_TRANSIENT:
			store = _get_context().transient_store
		VariableScope.SCOPE_DIALOGUE_GRAPH:
			store = _get_context().dialogue_graph_state_store
		VariableScope.SCOPE_LOCAL:
			store = _get_context().local_store.store_data
		VariableScope.SCOPE_GLOBAL:
			store = _get_context().global_store.store_data
	if store.has(name):
		return
	store[name] = val
	_update_variable_stores_tree()


func _confirm_clear_all_stores():
	_logger.debug("Confirming variable store clear")
	if await Dialogs.request_confirmation(
		"Are you sure you want to clear all variable stores? This action cannot be undone."
	):
		_clear_all_stores()


func _get_default_value_for_type(t):
	match t:
		VariableType.TYPE_BOOL:
			return false
		VariableType.TYPE_FLOAT:
			return 0.0
		VariableType.TYPE_INT:
			return 0
		VariableType.TYPE_STRING:
			return ""
	return null


func _get_variable_store_for_branch(branch):
	if branch == _transient_store_root:
		return _get_context().transient_store
	if branch == _dialogue_graph_store_root:
		return _get_context().dialogue_graph_state_store
	if branch == _local_store_root:
		return _get_context().local_store.store_data
	if branch == _global_store_root:
		return _get_context().global_store.store_data
	return null


func _set_play_audio_button_state(show):
	_play_audio_button.set_pressed_no_signal(show)
	if show:
		_play_audio_button.icon = NOTIFICATION_ICON
	else:
		_play_audio_button.icon = NOTIFICATION_DISABLED_ICON


func _use_characterwise():
	return _characterwise_display and not _fast_forward


func _clear_all_stores():
	_logger.debug("Clearing all stores")
	clear_variable_stores()
	_update_variable_stores_tree()


func _on_stop_button_pressed():
	_stop_processing()
	var n = FinalStaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate("Stopped.")
	n.back_button_pressed.connect(_on_back_button_pressed)
	_reset_to_root_graph()


func _on_graph_controller_dialogue_graph_started(graph_name, graph_type):
	_logger.debug("Dialogue Graph Started")
	# Restore the backup of the transient store from before the
	# graph was triggered, as the controller will have cleared it.
	_get_context().transient_store = _transient_state.duplicate()
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate("Dialogue graph started...")
	_hide_continue()
	_update_variable_stores_tree()


func _on_graph_controller_dialogue_graph_completed(exit_value):
	_logger.debug("Dialogue Graph Completed")
	_get_context().transient_store = _transient_state.duplicate()
	var n = FinalStaticInformationalEvent.instantiate()
	_insert_event(n)
	if exit_value == null:
		n.populate("Dialogue graph complete.")
	else:
		n.populate("Dialogue graph complete with exit value \"%s\"." % exit_value)
	n.back_button_pressed.connect(_on_back_button_pressed)
	_hide_continue()
	_update_variable_stores_tree()
	_set_control_states(false)
	stopping_preview.emit()


func _on_graph_controller_action_requested(action, arguments, process):
	_logger.debug("Action Requested")
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	var event_text = "Action \"%s\" requested" % action
	
	var arguments_text = _prepare_arguments_text(arguments)
	
	if not arguments_text.is_empty():
		event_text = "%s with arguments: %s" % [
			event_text,
			arguments_text
		]
	n.populate(event_text, "The effects of actions cannot be modelled by the previewer.")
	_update_variable_stores_tree()
	_focus_current_node_in_minimap()
	if _fast_forward:
		process.proceed()
	else:
		_prepare_to_wait(process)


func _on_graph_controller_choice_dialogue_display_requested(
	choice_type,
	dialogue_type,
	text,
	character,
	character_variant,
	properties,
	process
):
	# TODO: Do actually need to display the choice type here
	_on_graph_controller_dialogue_display_requested(
		dialogue_type,
		text,
		character,
		character_variant,
		properties,
		process
	)


func _on_graph_controller_choice_display_requested(
	choice_type,
	choices,
	process
):
	# TODO: Need to display the choice type here, there is nowhere for it currently
	_logger.debug("Choice Display Requested")
	var n = ChoiceEvent.instantiate()
	_insert_event(n)
	n.populate(choices)
	n.choice_selected.connect(
		_on_choice_selected.bind(process)
	)
	_hide_continue()
	_update_variable_stores_tree()
	_focus_current_node_in_minimap()
	if _fast_forward and _play_audio:
		_dialogue_displayed_player.play()


func _on_graph_controller_dialogue_display_requested(
	dialogue_type,
	text,
	character,
	character_variant,
	properties,
	process
):
	_logger.debug("Dialogue Display Requested")
	var n
	var panel
	var indicator
	var colour_resources
	if character != null:
		var colour = _character_colours[character]
		colour_resources = _dialogue_colour_resources[colour]
	if character != null and character.is_player:
		n = PlayerDialogueEvent.instantiate()
		panel = colour_resources[DialogueColourResourceIndex.RIGHT_PANEL]
		indicator = colour_resources[DialogueColourResourceIndex.RIGHT_INDICATOR]
	else:
		n = DialogueEvent.instantiate()
		if colour_resources != null:
			panel = colour_resources[DialogueColourResourceIndex.LEFT_PANEL]
			indicator = colour_resources[DialogueColourResourceIndex.LEFT_INDICATOR]
	#await n.ready
	_insert_event(n)
	n.populate(
		dialogue_type,
		character,
		character_variant,
		text,
		panel,
		indicator,
		_use_characterwise(),
		properties,
	)
	n.character_displayed.connect(
		_on_dialogue_node_character_displayed
	)
	n.ready_to_continue.connect(
		_on_dialogue_node_ready_to_continue.bind(process)
	)
	_update_variable_stores_tree()
	_focus_current_node_in_minimap()
	if _fast_forward:
		process.proceed()
	else:
		if _play_audio and not _use_characterwise():
			_dialogue_displayed_player.play()
		if not _use_characterwise():
			_prepare_to_wait(process)
		else:
			_continue_button.visible = false


func _on_scroll_changed():
	_dialogue_scroll_container.set_deferred(
		"scroll_vertical",
		_dialogue_scrollbar.max_value
	)


func _on_dialogue_node_ready_to_continue(process):
	_prepare_to_wait(process)


func _on_dialogue_node_character_displayed():
	if _play_audio:
		_character_displayed_player.play()


func _on_choice_selected(choice, process):
	process.proceed_with_choice(choice)


func _on_continue_requested():
	_current_process.proceed()
	_current_process = null


func _on_graph_controller_sub_graph_entered(graph_name, graph_type):
	_logger.debug("Sub-graph \"%s\" entered" % graph_name)
	var graph = _get_context().graph
	_graph_stack.append(graph)
	_assign_colours_to_characters(graph.characters)
	_populate_characters(graph.characters)
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate("Sub-graph \"%s\" entered..." % graph_name)
	_hide_continue()
	_update_variable_stores_tree()
	_breadcrumbs.populate(_graph_stack)
	_graph_mini_map.clear()
	_graph_mini_map.display_graph(graph)


func _on_graph_controller_dialogue_graph_resumed(
	graph_name,
	graph_type,
	exit_value,
):
	_logger.debug("Graph \"%s\" resumed" % graph_name)
	_graph_stack.pop_back()
	var graph = _get_context().graph
	_assign_colours_to_characters(graph.characters)
	_populate_characters(graph.characters)
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	if exit_value == null:
		n.populate("Graph \"%s\" resumed..." % graph_name)
	else:
		n.populate(
			"Graph \"%s\" resumed with exit value \"%s\"..." % [
				graph_name,
				exit_value,
			]
		)
	_hide_continue()
	_update_variable_stores_tree()
	_breadcrumbs.populate(_graph_stack)
	_graph_mini_map.clear()
	_graph_mini_map.display_graph(graph)


func _on_run_button_pressed():
	_start_processing()


func _on_start_button_pressed():
	_start_processing()


func _on_restart_button_pressed():
	_stop_processing()
	_reset_to_root_graph()
	_start_processing()


func _on_show_processing_button_toggled(button_pressed):
	_show_processing = button_pressed
	_set_show_processing_button_state(button_pressed)
	_set_show_processing_checkbox_state(button_pressed)


func _on_fast_forward_button_toggled(button_pressed):
	_fast_forward = button_pressed
	_characterwise_display_button.disabled = _fast_forward


func _on_show_processing_check_box_toggled(button_pressed):
	_show_processing = button_pressed
	_set_show_processing_button_state(button_pressed)


func _on_stores_menu_id_pressed(id):
	match id:
		StoresMenuItemId.ADD_VARIABLE:
			_show_add_variable_dialog()
		StoresMenuItemId.LOAD_ADD:
			_load_stores(false)
		StoresMenuItemId.LOAD_REPLACE:
			_load_stores(true)
		StoresMenuItemId.SAVE:
			_save_stores()
		StoresMenuItemId.CLEAR_ALL:
			_confirm_clear_all_stores()


func _on_store_save_file_selected(path, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	
	# Create a dictionary with the contents of the data stores
	var data = {
		'transient': _get_context().transient_store.duplicate(),
		'dialogue_graph': _get_context().dialogue_graph_state_store.duplicate(),
		'local': _get_context().local_store.store_data.duplicate(),
		'global': _get_context().global_store.store_data.duplicate(),
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err = FileAccess.get_open_error()
		_logger.error("Error opening file for saving preview variable stores: %s" % err)
		Dialogs.show_error(
			"File open failed: %s" % err
		)
		return
	file.store_string(JSON.stringify(data, "  ", false))
	file.close()


func _on_store_load_file_selected(path, replace, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var err = FileAccess.get_open_error()
		_logger.error("Error opening file for saving preview variable stores: %s" % err)
		Dialogs.show_error(
			"File open failed: %s" % err
		)
		return
	
	var data_str = file.get_as_text()
	file.close()
	var data = JSON.parse_string(data_str)
	if replace:
		clear_variable_stores()
	if data.has('transient'):
		_get_context().transient_store.merge(data['transient'], true)
	if data.has('dialogue_graph'):
		_get_context().dialogue_graph_state_store.merge(data['dialogue_graph'], true)
	if data.has('local'):
		_get_context().local_store.store_data.merge(data['local'], true)
	if data.has('global'):
		_get_context().global_store.store_data.merge(data['global'], true)
	_update_variable_stores_tree()


func _on_dialog_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _on_variable_stores_tree_item_edited():
	var edited = _variable_stores_tree.get_edited()
	var new_value_str = edited.get_text(1)
	var variable_name = edited.get_text(0)
	# Need to determine the store, and the type
	var parent = edited.get_parent()
	var store: Variant = _get_variable_store_for_branch(parent)
	if store == null:
		return
	var current_value = store[variable_name]
	var new_value = current_value
	match typeof(current_value):
		TYPE_BOOL:
			new_value = edited.is_checked(1)
		TYPE_INT:
			if new_value_str.is_valid_int():
				new_value = int(new_value_str)
		TYPE_FLOAT:
			if new_value_str.is_valid_float():
				new_value = float(new_value_str)
		TYPE_STRING:
			new_value = new_value_str
	store[variable_name] = new_value
	_update_variable_stores_tree()


func _on_play_audio_button_toggled(button_pressed):
	_play_audio = button_pressed
	_set_play_audio_button_state(button_pressed)


func _on_characterwise_button_toggled(button_pressed):
	_characterwise_display = button_pressed


func _on_back_button_pressed():
	_show_hide(_begin_container, _dialogue_scroll_container)

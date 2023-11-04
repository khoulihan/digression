@tool
extends VBoxContainer


const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Preview", Logging.CGE_NODES_LOG_LEVEL)


signal starting_preview()
signal stopping_preview()


@onready var _show_processing_checkbox = $HSplitContainer/HSplitContainer/VB/PanelContainer/MarginContainer/BeginContainer/VBoxContainer/ShowProcessingCheckBox
@onready var _graph_mini_map = $HSplitContainer/HSplitContainer/VSplitContainer/GraphMiniMap
@onready var _dialogue_scroll_container = $HSplitContainer/HSplitContainer/VB/PanelContainer/MarginContainer/DialogueScrollContainer
@onready var _dialogue_container = $HSplitContainer/HSplitContainer/VB/PanelContainer/MarginContainer/DialogueScrollContainer/MarginContainer/DialogueContainer
@onready var _begin_container = $HSplitContainer/HSplitContainer/VB/PanelContainer/MarginContainer/BeginContainer
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
@onready var _stores_menu_button = $HSplitContainer/VariableStoresContainer/HBoxContainer/StoresMenuButton
@onready var _controller = $CutsceneController
@onready var _cutscene = $Cutscene
@onready var _dialogue_displayed_player = $DialogueDisplayedPlayer
@onready var _character_displayed_player = $CharacterDisplayedPlayer
var _dialogue_scrollbar
var _continue_button
var _transient_store_root: TreeItem
var _cutscene_store_root: TreeItem
var _local_store_root: TreeItem
var _global_store_root: TreeItem


const VisibleIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_visible.svg")
const InvisibleIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_invisible.svg")
const NotificationIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_notification.svg")
const NotificationDisabledIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_notification_disabled.svg")


const DialogueTextEvent = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/DialogueTextEvent.tscn")
const PlayerDialogueTextEvent = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/PlayerDialogueTextEvent.tscn")
const StaticInformationalEvent = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/StaticInformationalEvent.tscn")
const ChoiceEvent = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/ChoiceEvent.tscn")
const VariableSelectDialog = preload("../variable_select_dialog/VariableSelectDialog.tscn")


const VariableScope = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableScope
const VariableType = preload("res://addons/hyh.cutscene_graph/resources/graph/VariableSetNode.gd").VariableType


const DialoguePanelStyleBoxLeftResource = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/styles/dialogue_box_panel_green_left.tres")
const DialoguePanelStyleBoxRightResource = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/styles/dialogue_box_panel_green_right.tres")
const DialogueIndicatorStyleBoxLeftResource = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/styles/dialogue_box_indicator_green_left.tres")
const DialogueIndicatorStyleBoxRightResource = preload("res://addons/hyh.cutscene_graph/editor/preview/dialogue_events/styles/dialogue_box_indicator_green_right.tres")
const ColourIndicatorIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_colour_indicator.svg")


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


# Called when the node enters the scene tree for the first time.
func _ready():
	_clear_dialogue()
	_cutscene.set_controller(_controller)
	_connect_internal_signals()
	_dialogue_scrollbar = _dialogue_scroll_container.get_v_scroll_bar()
	_dialogue_scrollbar.changed.connect(_scroll_changed)
	_create_dialogue_colour_resources()
	_stores_menu_button.get_popup().id_pressed.connect(
		_on_stores_menu_id_pressed
	)


func _create_dialogue_colour_resources():
	for i in range(10):
		_dialogue_colour_resources[i] = _create_dialogue_colour_set(
			_dialogue_colours[i]
		)


func _create_dialogue_colour_set(colour):
	var left_panel = DialoguePanelStyleBoxLeftResource.duplicate()
	var right_panel = DialoguePanelStyleBoxRightResource.duplicate()
	var left_indicator = DialogueIndicatorStyleBoxLeftResource.duplicate()
	var right_indicator = DialogueIndicatorStyleBoxRightResource.duplicate()
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
	i.processed_branch_node.connect(_processed_branch_node)
	i.processed_random_node.connect(_processed_random_node)
	i.processed_repeat_node.connect(_processed_repeat_node)
	i.processed_jump_node.connect(_processed_jump_node)
	i.processed_anchor_node.connect(_processed_anchor_node)
	i.processed_routing_node.connect(_processed_routing_node)


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


func _processed_branch_node(variable, scope, value, branch_matched):
	if not _show_processing:
		return
	# TODO: Will want to show more information on this.
	_add_static_processing_event("Processed branch node...")


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


func _get_scope_description(scope):
	match scope:
		VariableScope.SCOPE_TRANSIENT:
			return "transient"
		VariableScope.SCOPE_CUTSCENE:
			return "cutscene"
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
	_cutscene.cutscene = graph
	_show_hide(_begin_container, _dialogue_scroll_container)
	_assign_colours_to_characters(graph.characters)
	_populate_characters(graph.characters)
	_initialise_variable_stores_tree()
	# TODO: This clear is resulting in a bunch of errors when
	# a graph is re-displayed for some reason.
	_graph_mini_map.clear()
	_graph_mini_map.display_graph(graph)


func _reset_to_root_graph():
	var graph = _graph_stack[0]
	_graph_stack = [graph]
	_breadcrumbs.populate(_graph_stack)
	_cutscene.cutscene = graph
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
	_graph_mini_map.focus_on_node(_controller._current_node)


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
		c.set_icon(0, ColourIndicatorIcon)
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
	_cutscene_store_root = _variable_stores_tree.create_item(root)
	_cutscene_store_root.set_text(0, "Cutscene")
	_local_store_root = _variable_stores_tree.create_item(root)
	_local_store_root.set_text(0, "Local")
	_global_store_root = _variable_stores_tree.create_item(root)
	_global_store_root.set_text(0, "Global")


func _update_variable_stores_tree():
	# Note that this method examines "private" properties of the controller
	_update_variable_stores_branch(
		_transient_store_root,
		_controller._transient_store
	)
	_update_variable_stores_branch(
		_cutscene_store_root,
		_controller._cutscene_state_store
	)
	_update_variable_stores_branch(
		_local_store_root,
		_controller._local_store.store_data
	)
	_update_variable_stores_branch(
		_global_store_root,
		_controller._global_store.store_data
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
	_continue_button.icon = preload("res://addons/hyh.cutscene_graph/icons/icon_play.svg")
	_dialogue_container.add_child(_continue_button)
	_continue_button.pressed.connect(_continue_requested)
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
	Logger.debug("Triggering Graph")
	#_show_processing = _show_processing_checkbox.button_pressed
	# TODO: `_show_processing` will require setting something on the controller
	# as well, and probably connecting events.
	_show_hide(_dialogue_scroll_container, _begin_container)
	_set_control_states(true)
	starting_preview.emit()
	_clear_dialogue()
	_transient_state = _controller._transient_store.duplicate()
	_cutscene.trigger()


func _stop_processing():
	Logger.debug("Stopping")
	_set_control_states(false)
	_controller.cancel()
	_controller._transient_store = _transient_state.duplicate()
	_hide_continue()
	if _dialogue_container.get_child_count() >= 2:
		var last_event = _dialogue_container.get_child(-2)
		if last_event != null and "cancel" in last_event:
			last_event.cancel()
	stopping_preview.emit()


func _on_stop_button_pressed():
	_stop_processing()
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate("Stopped.")
	_reset_to_root_graph()


func _prepare_to_wait(process):
	_current_process = process
	_continue_button.visible = true


func _hide_continue():
	_continue_button.visible = false


func _insert_event(ev):
	_dialogue_container.add_child(ev)
	_dialogue_container.move_child(_continue_button, -1)


func _on_cutscene_controller_cutscene_started(cutscene_name, graph_type):
	Logger.debug("Cutscene Started")
	# Restore the backup of the transient store from before the
	# cutscene was triggered, as the controller will have cleared it.
	_controller._transient_store = _transient_state.duplicate()
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate("Cutscene started...")
	_hide_continue()
	_update_variable_stores_tree()


func _on_cutscene_controller_cutscene_completed():
	Logger.debug("Cutscene Completed")
	_controller._transient_store = _transient_state.duplicate()
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate("Cutscene complete.")
	_hide_continue()
	_update_variable_stores_tree()
	_set_control_states(false)
	stopping_preview.emit()


func _on_cutscene_controller_action_requested(action, character, character_variant, argument, process):
	Logger.debug("Action Requested")
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	var event_text = "Action \"%s\" requested" % action
	if character != null:
		event_text = "%s with character \"%s\"" % [event_text, character.get_full_name()]
	if character_variant != null:
		var conjunction = "and"
		event_text = "%s %s variant \"%s\"" % [
			event_text,
			conjunction,
			character_variant.get_full_name()
		]
	if argument != null and argument != "":
		var conjunction = "and"
		if character == null:
			conjunction = "with"
		event_text = "%s %s argument \"%s\"" % [
			event_text,
			conjunction,
			argument
		]
	n.populate(event_text)
	_update_variable_stores_tree()
	_focus_current_node_in_minimap()
	if _fast_forward:
		process.proceed()
	else:
		_prepare_to_wait(process)


func _on_cutscene_controller_choice_dialogue_display_requested(choice_type, dialogue_type, text, character, character_variant, process):
	# TODO: Do actually need to display the choice type here
	_on_cutscene_controller_dialogue_display_requested(dialogue_type, text, character, character_variant, process)


func _on_cutscene_controller_choice_display_requested(choice_type, choices, process):
	# TODO: Need to display the choice type here, there is nowhere for it currently
	Logger.debug("Choice Display Requested")
	var n = ChoiceEvent.instantiate()
	_insert_event(n)
	n.populate(choices)
	n.choice_selected.connect(
		_choice_selected.bind(process)
	)
	_hide_continue()
	_update_variable_stores_tree()
	_focus_current_node_in_minimap()
	if _fast_forward and _play_audio:
		_dialogue_displayed_player.play()


func _on_cutscene_controller_dialogue_display_requested(dialogue_type, text, character, character_variant, process):
	Logger.debug("Dialogue Display Requested")
	var n
	var panel
	var indicator
	var colour_resources
	if character != null:
		var colour = _character_colours[character]
		colour_resources = _dialogue_colour_resources[colour]
	if character != null and character.is_player:
		n = PlayerDialogueTextEvent.instantiate()
		panel = colour_resources[DialogueColourResourceIndex.RIGHT_PANEL]
		indicator = colour_resources[DialogueColourResourceIndex.RIGHT_INDICATOR]
	else:
		n = DialogueTextEvent.instantiate()
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
		_use_characterwise()
	)
	n.character_displayed.connect(
		_dialogue_node_character_displayed
	)
	n.ready_to_continue.connect(
		_dialogue_node_ready_to_continue.bind(process)
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


func _scroll_changed():
	_dialogue_scroll_container.set_deferred(
		"scroll_vertical",
		_dialogue_scrollbar.max_value
	)

func _scroll_to_bottom():
	_dialogue_scroll_container.set_deferred(
		"scroll_vertical",
		_dialogue_scroll_container.get_v_scroll_bar().max_value
	)


func _dialogue_node_ready_to_continue(process):
	_prepare_to_wait(process)


func _dialogue_node_character_displayed():
	if _play_audio:
		_character_displayed_player.play()


func _choice_selected(choice, process):
	process.proceed(choice)


func _continue_requested():
	_current_process.proceed()
	_current_process = null


func _on_cutscene_controller_sub_graph_entered(cutscene_name, graph_type):
	Logger.debug("Sub-graph \"%s\" entered" % cutscene_name)
	_graph_stack.append(_controller._current_graph)
	_assign_colours_to_characters(_controller._current_graph.characters)
	_populate_characters(_controller._current_graph.characters)
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate("Sub-graph \"%s\" entered..." % cutscene_name)
	_hide_continue()
	_update_variable_stores_tree()
	_breadcrumbs.populate(_graph_stack)
	_graph_mini_map.clear()
	_graph_mini_map.display_graph(_controller._current_graph)


func _on_cutscene_controller_cutscene_resumed(cutscene_name, graph_type):
	Logger.debug("Graph \"%s\" resumed" % cutscene_name)
	_graph_stack.pop_back()
	_assign_colours_to_characters(_controller._current_graph.characters)
	_populate_characters(_controller._current_graph.characters)
	var n = StaticInformationalEvent.instantiate()
	_insert_event(n)
	n.populate("Graph \"%s\" resumed..." % cutscene_name)
	_hide_continue()
	_update_variable_stores_tree()
	_breadcrumbs.populate(_graph_stack)
	_graph_mini_map.clear()
	_graph_mini_map.display_graph(_controller._current_graph)


func _on_run_button_pressed():
	_start_processing()


func _on_start_button_pressed():
	_start_processing()


func _on_restart_button_pressed():
	_stop_processing()
	_reset_to_root_graph()
	_start_processing()


func _set_show_processing_button_state(show):
	_show_processing_button.set_pressed_no_signal(show)
	if show:
		_show_processing_button.icon = VisibleIcon
	else:
		_show_processing_button.icon = InvisibleIcon


func _set_show_processing_checkbox_state(show):
	_show_processing_checkbox.set_pressed_no_signal(show)


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


func _save_stores():
	var dialog = EditorFileDialog.new()
	get_tree().root.add_child(dialog)
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.json", "JSON Files")
	dialog.canceled.connect(_dialog_cancelled.bind(dialog))
	dialog.file_selected.connect(_store_save_file_selected.bind(dialog))
	dialog.popup_centered(Vector2i(800, 600))


func _store_save_file_selected(path, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	
	# Create a dictionary with the contents of the data stores
	var data = {
		'transient': _controller._transient_store.duplicate(),
		'cutscene': _controller._cutscene_state_store.duplicate(),
		'local': _controller._local_store.store_data.duplicate(),
		'global': _controller._global_store.store_data.duplicate(),
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err = FileAccess.get_open_error()
		Logger.error("Error opening file for saving preview variable stores: %s" % err)
		var error_dialog = AcceptDialog.new()
		error_dialog.dialog_text = "File open failed: %s" % err
		error_dialog.title = "Error"
		error_dialog.confirmed.connect(_dialog_cancelled.bind(error_dialog))
		error_dialog.canceled.connect(_dialog_cancelled.bind(error_dialog))
		get_tree().root.add_child(error_dialog)
		error_dialog.popup_centered()
		return
	file.store_string(JSON.stringify(data, "  ", false))
	file.close()
	

func _load_stores(replace):
	var dialog = EditorFileDialog.new()
	get_tree().root.add_child(dialog)
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.json", "JSON Files")
	dialog.canceled.connect(_dialog_cancelled.bind(dialog))
	dialog.file_selected.connect(_store_load_file_selected.bind(replace, dialog))
	dialog.popup_centered(Vector2i(800, 600))


func _store_load_file_selected(path, replace, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var err = FileAccess.get_open_error()
		Logger.error("Error opening file for saving preview variable stores: %s" % err)
		var error_dialog = AcceptDialog.new()
		error_dialog.dialog_text = "File open failed: %s" % err
		error_dialog.title = "Error"
		error_dialog.confirmed.connect(_dialog_cancelled.bind(error_dialog))
		error_dialog.canceled.connect(_dialog_cancelled.bind(error_dialog))
		get_tree().root.add_child(error_dialog)
		error_dialog.popup_centered()
		return
	
	var data_str = file.get_as_text()
	file.close()
	var data = JSON.parse_string(data_str)
	if replace:
		clear_variable_stores()
	if data.has('transient'):
		_controller._transient_store.merge(data['transient'], true)
	if data.has('cutscene'):
		_controller._cutscene_state_store.merge(data['cutscene'], true)
	if data.has('local'):
		_controller._local_store.store_data.merge(data['local'], true)
	if data.has('global'):
		_controller._global_store.store_data.merge(data['global'], true)
	_update_variable_stores_tree()


func clear_variable_stores():
	_controller._transient_store.clear()
	_controller._cutscene_state_store.clear()
	_controller._local_store.store_data.clear()
	_controller._global_store.store_data.clear()


func _clear_all_stores(dialog):
	Logger.debug("Clearing all stores")
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	clear_variable_stores()
	_update_variable_stores_tree()


func _confirm_clear_all_stores():
	Logger.debug("Confirming variable store clear")
	var d = ConfirmationDialog.new()
	get_tree().root.add_child(d)
	d.title = "Confirm"
	d.dialog_text = "Are you sure you want to clear all variable stores? This action cannot be undone."
	d.confirmed.connect(_clear_all_stores.bind(d))
	d.canceled.connect(_dialog_cancelled.bind(d))
	d.popup_centered()


func _show_add_variable_dialog():
	var dialog = VariableSelectDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	dialog.position = get_tree().root.position + Vector2i(200, 200)
	dialog.selected.connect(_variable_selected.bind(dialog))
	dialog.cancelled.connect(_dialog_cancelled.bind(dialog))
	get_tree().root.add_child(dialog)
	dialog.popup()


func _variable_selected(variable, dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()
	
	var val = _get_default_value_for_type(variable['type'])
	var name = variable['name']
	var store
	match variable['scope']:
		VariableScope.SCOPE_TRANSIENT:
			store = _controller._transient_store
		VariableScope.SCOPE_CUTSCENE:
			store = _controller._cutscene_state_store
		VariableScope.SCOPE_LOCAL:
			store = _controller._local_store.store_data
		VariableScope.SCOPE_GLOBAL:
			store = _controller._global_store.store_data
	if store.has(name):
		return
	store[name] = val
	_update_variable_stores_tree()


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


func _dialog_cancelled(dialog):
	get_tree().root.remove_child(dialog)
	dialog.queue_free()


func _on_variable_stores_tree_item_edited():
	var edited = _variable_stores_tree.get_edited()
	var new_value_str = edited.get_text(1)
	var variable_name = edited.get_text(0)
	# Need to determine the store, and the type
	var parent = edited.get_parent()
	var store = _get_variable_store_for_branch(parent)
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


func _get_variable_store_for_branch(branch):
	if branch == _transient_store_root:
		return _controller._transient_store
	if branch == _cutscene_store_root:
		return _controller._cutscene_state_store
	if branch == _local_store_root:
		return _controller._local_store.store_data
	if branch == _global_store_root:
		return _controller._global_store.store_data
	return null


func _set_play_audio_button_state(show):
	_play_audio_button.set_pressed_no_signal(show)
	if show:
		_play_audio_button.icon = NotificationIcon
	else:
		_play_audio_button.icon = NotificationDisabledIcon


func _on_play_audio_button_toggled(button_pressed):
	_play_audio = button_pressed
	_set_play_audio_button_state(button_pressed)


func _on_characterwise_button_toggled(button_pressed):
	_characterwise_display = button_pressed


func _use_characterwise():
	return _characterwise_display and not _fast_forward

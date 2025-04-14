@tool
extends EditorPlugin
## Digression Dialogue Graph Editor plugin.


enum ToolMenuItems {
	EDIT_GRAPH_TYPES,
	EDIT_DIALOGUE_TYPES,
	EDIT_CHOICE_TYPES,
	EDIT_PROPERTY_DEFINITIONS,
}

const SettingsHelper = preload("editor/helpers/SettingsHelper.gd")
const Logging = preload("utility/Logging.gd")
const DialogueGraphEditor = preload("editor/DialogueGraphEditor.tscn")
const DigressionDialogue = preload("editor/DigressionDialogue.gd")
const GraphTypeEditDialog = preload("editor/dialogs/graph_types_edit/GraphTypeEditDialog.tscn")
const GraphTypeEditDialogClass = preload("editor/dialogs/graph_types_edit/GraphTypeEditDialog.gd")
const DialogueTypesEditDialog = preload("editor/dialogs/dialogue_types_edit/DialogueTypesEditDialog.tscn")
const DialogueTypesEditDialogClass = preload("editor/dialogs/dialogue_types_edit/DialogueTypesEditDialog.gd")
const ChoiceTypesEditDialog = preload("editor/dialogs/choice_types_edit/ChoiceTypesEditDialog.tscn")
const ChoiceTypesEditDialogClass = preload("editor/dialogs/choice_types_edit/ChoiceTypesEditDialog.gd")
const PropertyDefinitionEditDialog = preload("editor/dialogs/property_definition_edit/PropertyDefinitionEditDialog.tscn")
const PropertyDefinitionEditDialogClass = preload("editor/dialogs/property_definition_edit/PropertyDefinitionEditDialog.gd")
const CustomPropertyInspectorPlugin = preload("editor/inspector/custom_property_edit/CustomPropertyInspectorPlugin.gd")

var editor_host
var editor
var editor_button
var expand_button
var menu

var _custom_inspector : CustomPropertyInspectorPlugin
var _current_graph_is_in_scene
var _logger = Logging.new(
	Logging.DGE_EDITOR_LOG_NAME,
	Logging.DGE_EDITOR_LOG_LEVEL
)


func _enter_tree():
	# TODO: Need a new icon for these - should be white at the very least, like other Node-derived types
	add_custom_type(
		"DigressionDialogueController",
		"Node",
		preload("editor/DigressionDialogueController.gd"),
		preload("icons/icon_dialogue_controller.svg")
	)
	add_custom_type(
		"DigressionDialogue",
		"Node",
		preload("editor/DigressionDialogue.gd"),
		preload("icons/icon_chat.svg")
	)
	add_custom_type(
		"DigressionDialogueVariableStore",
		"Node",
		preload("editor/DigressionDialogueVariableStore.gd"),
		preload("icons/icon_datastore.svg")
	)
	
	# Add inspector plugins
	_custom_inspector = CustomPropertyInspectorPlugin.new()
	add_inspector_plugin(_custom_inspector)
	
	# Check if the settings exist, and create some defaults if necessary
	_create_default_project_settings()
	
	_create_editor_host()
	_create_menu()


func _exit_tree():
	remove_custom_type("DigressionDialogueController")
	remove_custom_type("DigressionDialogue")
	remove_custom_type("DigressionDialogueVariableStore")
	remove_inspector_plugin(_custom_inspector)
	if editor != null:
		editor.save_requested.disconnect(
			_save_requested
		)
		editor.graph_edited.disconnect(_on_editor_graph_edited)
		editor.display_filesystem_path_requested.disconnect(
			_on_editor_display_filesystem_path_requested
		)
		editor.current_graph_modified.disconnect(
			_on_editor_current_graph_modified
		)
	EditorInterface.get_editor_main_screen().remove_child(editor_host)
	menu.id_pressed.disconnect(_on_tool_menu_item_selected)
	remove_tool_menu_item("Digression Dialogue Graph Editor")
	if editor_host != null:
		editor_host.queue_free()
		editor = null


func _has_main_screen() -> bool:
	return true


func _handles(object: Object) -> bool:
	return (object is DigressionDialogueGraph or object is DigressionDialogue)


func _edit(object):
	var graph
	if object is DigressionDialogue:
		graph = object.dialogue_graph
		_current_graph_is_in_scene = true
	else:
		graph = object
		_current_graph_is_in_scene = false
	if graph != null:
		var current_resource_path = graph.resource_path
		call_deferred("_request_edit", graph, current_resource_path)
	else:
		call_deferred("_request_clear")


func _apply_changes():
	if editor != null:
		editor.perform_save()


func _get_plugin_name():
	return "Dialogue"


func _get_plugin_icon():
	return preload("icons/icon_chat.svg")


func _make_visible(visible):
	if is_instance_valid(editor_host):
		editor_host.visible = visible


func clear():
	if editor != null:
		_request_clear()


func _create_default_project_settings():
	SettingsHelper.create_default_project_settings()


func _create_editor_host():
	_logger.debug("Creating host...")
	editor_host = preload("editor/DialogueGraphEditorHost.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(editor_host)
	editor_host.visible = false
	_get_editor()


func _get_editor():
	_logger.debug("Getting editor from host...")
	editor = editor_host.editor
	editor.save_requested.connect(
		_save_requested
	)
	editor.display_filesystem_path_requested.connect(
		_on_editor_display_filesystem_path_requested
	)
	editor.graph_edited.connect(
		_on_editor_graph_edited
	)
	editor.current_graph_modified.connect(
		_on_editor_current_graph_modified
	)
	return editor


func _on_editor_graph_edited(graph):
	get_editor_interface().edit_resource(graph)


func _on_editor_current_graph_modified():
	if _current_graph_is_in_scene:
		# This is not available until 4.1
		# I don't see a way to do this in earlier versions.
		var interface = get_editor_interface()
		if interface.has_method("mark_scene_as_unsaved"):
			get_editor_interface().mark_scene_as_unsaved()


func _on_editor_display_filesystem_path_requested(path):
	_logger.debug("Navigating to path %s" % path)
	get_editor_interface().get_file_system_dock().navigate_to_path(path)


func _create_menu():
	menu = PopupMenu.new()
	menu.add_item("Edit Graph Types...", ToolMenuItems.EDIT_GRAPH_TYPES)
	menu.add_item("Edit Dialogue Types...", ToolMenuItems.EDIT_DIALOGUE_TYPES)
	menu.add_item("Edit Choice Types...", ToolMenuItems.EDIT_CHOICE_TYPES)
	menu.add_item("Edit Property Definitions...", ToolMenuItems.EDIT_PROPERTY_DEFINITIONS)
	menu.id_pressed.connect(_on_tool_menu_item_selected)
	
	add_tool_submenu_item("Digression Dialogue Graph Editor", menu)


func _on_tool_menu_item_selected(id):
	match id:
		ToolMenuItems.EDIT_GRAPH_TYPES:
			_show_edit_graph_types_dialog()
		ToolMenuItems.EDIT_DIALOGUE_TYPES:
			_show_edit_dialogue_types_dialog()
		ToolMenuItems.EDIT_CHOICE_TYPES:
			_show_edit_choice_types_dialog()
		ToolMenuItems.EDIT_PROPERTY_DEFINITIONS:
			_show_edit_property_definitions_dialog()


func _show_edit_graph_types_dialog():
	var dialog = GraphTypeEditDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	self.add_child(dialog)
	dialog.popup()
	await (dialog as GraphTypeEditDialogClass).closing
	dialog.hide()
	dialog.queue_free()


func _show_edit_dialogue_types_dialog():
	var dialog = DialogueTypesEditDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	self.add_child(dialog)
	dialog.popup()
	await (dialog as DialogueTypesEditDialogClass).closing
	dialog.hide()
	dialog.queue_free()


func _show_edit_choice_types_dialog():
	var dialog = ChoiceTypesEditDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	self.add_child(dialog)
	dialog.popup()
	await (dialog as ChoiceTypesEditDialogClass).closing
	dialog.hide()
	dialog.queue_free()


func _show_edit_property_definitions_dialog():
	var dialog = PropertyDefinitionEditDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	self.add_child(dialog)
	dialog.popup()
	await (dialog as PropertyDefinitionEditDialogClass).closing
	dialog.hide()
	dialog.queue_free()


func _save_requested(object, path):
	if path != "" and object.resource_path != "":
		_logger.debug("Save requested to path %s" % path)
		_logger.debug("Resource.resource_path is %s" % object.resource_path)
		ResourceSaver.save(object, path)
	else:
		_logger.warn("Save requested but no resource path is available.")
	# Not sure if/why this was necessary?
	#ResourceLoader.load(path)


func _request_edit(object, current_resource_path):
	editor.edit_graph(object, current_resource_path)


func _request_clear():
	_logger.debug("Clearing graph editor...")
	editor.clear()

@tool
extends RefCounted
## Helper class for dealing with project settings.


enum BuiltinTheme {
	NONE,
	DEFAULT,
	HIGH_CONTRAST,
}


const SETTINGS_APPLICATION = "digression_dialogue_graph_editor"
const SETTINGS_SCHEMA_SECTION = "schema"
const SETTINGS_THEME_SECTION = "theme"
const SETTINGS_EDITOR_SECTION = "editor"
const SETTINGS_LOGGING_SECTION = "logging"

const _DEFAULT_THEME = BuiltinTheme.DEFAULT
const _DEFAULT_CUSTOM_THEME = ""
const _DEFAULT_GRAPH_TYPES = [
	{
		"name": "dialogue",
		"split_dialogue": true,
		"default": true
	},
	{
		"name": "cutscene",
		"split_dialogue": true,
		"default": false
	}
]
const _DEFAULT_DIALOGUE_TYPES = [
	{
		"name": "dialogue",
		"split_dialogue": null,
		"involves_character": true,
		"allowed_in_graph_types": [
			"dialogue",
			"cutscene",
		],
		"default_in_graph_types": [
			"dialogue",
			"cutscene",
		],
	},
	{
		"name": "narration",
		"split_dialogue": null,
		"involves_character": false,
		"allowed_in_graph_types": [
			"dialogue",
			"cutscene",
		],
		"default_in_graph_types": [],
	},
]
const _DEFAULT_CHOICE_TYPES = [
	{
		"name": "choice",
		"include_dialogue": false,
		"skip_for_repeat": false,
		"allowed_in_graph_types": [
			"dialogue",
			"cutscene",
		],
		"default_in_graph_types": [],
	},
	{
		"name": "choice_with_dialogue",
		"include_dialogue": true,
		"skip_for_repeat": false,
		"allowed_in_graph_types": [
			"dialogue",
			"cutscene",
		],
		"default_in_graph_types": [
			"dialogue",
			"cutscene",
		],
	},
]
const _DEFAULT_LINE_LENGTH_GUIDELINES = []
const _DEFAULT_EDITOR_LOG_LEVEL = 1
const _DEFAULT_PREVIEWER_LOG_LEVEL = 1
const _DEFAULT_RUNTIME_LOG_LEVEL = 1
const _DEFAULT_PROPERTY_DEFINITIONS = []
const _DEFAULT_VARIABLES = []
const _NODE_DEFAULT_INITIAL_WIDTH = 600.0
const _SCHEMA_INTERNAL = false


#static func _static_init() -> void:
#	print("RUNNING SETTINGS STATIC INIT")
#	_configure_settings()


static func get_graph_types_key() -> String:
	return "%s/%s/graph_types" % [SETTINGS_APPLICATION, SETTINGS_SCHEMA_SECTION]


static func get_dialogue_types_key() -> String:
	return "%s/%s/dialogue_types" % [SETTINGS_APPLICATION, SETTINGS_SCHEMA_SECTION]


static func get_choice_types_key() -> String:
	return "%s/%s/choice_types" % [SETTINGS_APPLICATION, SETTINGS_SCHEMA_SECTION]


static func get_property_definitions_key() -> String:
	return "%s/%s/property_definitions" % [SETTINGS_APPLICATION, SETTINGS_SCHEMA_SECTION]


static func get_variables_key() -> String:
	return "%s/%s/variables" % [SETTINGS_APPLICATION, SETTINGS_SCHEMA_SECTION]


static func get_theme_key() -> String:
	return "%s/%s/theme" % [SETTINGS_APPLICATION, SETTINGS_THEME_SECTION]


static func get_custom_theme_key() -> String:
	return "%s/%s/custom_theme" % [SETTINGS_APPLICATION, SETTINGS_THEME_SECTION]


static func get_editor_dialogue_line_length_guidelines_key() -> String:
	return "%s/%s/dialogue_line_length_guidelines" % [
		SETTINGS_APPLICATION,
		SETTINGS_EDITOR_SECTION
	]


static func get_editor_dialogue_node_initial_width_key() -> String:
	return "%s/%s/dialogue_node_initial_width" % [
		SETTINGS_APPLICATION,
		SETTINGS_EDITOR_SECTION
	]


static func get_editor_choice_node_initial_width_key() -> String:
	return "%s/%s/choice_node_initial_width" % [
		SETTINGS_APPLICATION,
		SETTINGS_EDITOR_SECTION
	]


static func get_editor_log_level_key() -> String:
	return "%s/%s/editor_log_level" % [
		SETTINGS_APPLICATION,
		SETTINGS_LOGGING_SECTION
	]


static func get_previewer_log_level_key() -> String:
	return "%s/%s/previewer_log_level" % [
		SETTINGS_APPLICATION,
		SETTINGS_LOGGING_SECTION
	]


static func get_runtime_log_level_key() -> String:
	return "%s/%s/runtime_log_level" % [
		SETTINGS_APPLICATION,
		SETTINGS_LOGGING_SECTION
	]


static func get_setting(key: String, default: Variant) -> Variant:
	return ProjectSettings.get_setting(
		key,
		default
	)


static func get_collection_setting(key: String) -> Array:
	return get_setting(key, [])


static func save_setting(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(
		key,
		value
	)
	ProjectSettings.save()


static func get_variables() -> Array:
	return get_collection_setting(
		get_variables_key()
	)


static func get_graph_types() -> Array:
	return get_collection_setting(
		get_graph_types_key()
	)


static func get_dialogue_types() -> Array:
	return get_collection_setting(
		get_dialogue_types_key()
	)


static func get_dialogue_types_for_graph_type(graph_type: String) -> Array:
	var all_types := get_dialogue_types()
	var allowed_types = []
	for dt in all_types:
		if graph_type in dt['allowed_in_graph_types']:
			allowed_types.append(dt)
	return allowed_types


static func get_choice_types() -> Array:
	return get_collection_setting(
		get_choice_types_key()
	)


static func get_choice_types_for_graph_type(graph_type: String) -> Array:
	var all_types := get_choice_types()
	var allowed_types = []
	for ct in all_types:
		if graph_type in ct['allowed_in_graph_types']:
			allowed_types.append(ct)
	return allowed_types


static func get_property_definitions() -> Array:
	return get_collection_setting(
		get_property_definitions_key()
	)


static func get_built_in_theme() -> BuiltinTheme:
	return get_setting(
		get_theme_key(),
		BuiltinTheme.DEFAULT,
	)


static func get_custom_theme() -> String:
	return get_setting(
		get_custom_theme_key(),
		"",
	)


static func get_dialogue_line_length_guidelines() -> Array:
	return get_setting(
		get_editor_dialogue_line_length_guidelines_key(),
		[],
	)


static func get_dialogue_node_initial_width() -> float:
	return get_setting(
		get_editor_dialogue_node_initial_width_key(),
		_NODE_DEFAULT_INITIAL_WIDTH,
	)


static func get_choice_node_initial_width() -> float:
	return get_setting(
		get_editor_choice_node_initial_width_key(),
		_NODE_DEFAULT_INITIAL_WIDTH,
	)


static func get_editor_log_level() -> int:
	return get_setting(
		get_editor_log_level_key(),
		1,
	)


static func get_previewer_log_level() -> int:
	return get_setting(
		get_previewer_log_level_key(),
		1,
	)


static func get_runtime_log_level() -> int:
	return get_setting(
		get_runtime_log_level_key(),
		1,
	)


static func save_variables(collection: Array) -> void:
	save_setting(
		get_variables_key(),
		collection,
	)


static func save_graph_types(collection: Array) -> void:
	save_setting(
		get_graph_types_key(),
		collection,
	)


static func save_dialogue_types(collection: Array) -> void:
	save_setting(
		get_dialogue_types_key(),
		collection,
	)


static func save_choice_types(collection: Array) -> void:
	save_setting(
		get_choice_types_key(),
		collection,
	)


static func save_property_definitions(collection: Array) -> void:
	save_setting(
		get_property_definitions_key(),
		collection,
	)


static func configure_settings() -> void:
	if not ProjectSettings.has_setting(get_theme_key()):
		ProjectSettings.set_setting(
			get_theme_key(),
			_DEFAULT_THEME
		)
	ProjectSettings.add_property_info(
		{
			"name": get_theme_key(),
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "None,Default,High Contrast",
		}
	)
	ProjectSettings.set_as_basic(get_theme_key(), true)
	ProjectSettings.set_initial_value(get_theme_key(), _DEFAULT_THEME)
	
	if not ProjectSettings.has_setting(get_custom_theme_key()):
		ProjectSettings.set_setting(
			get_custom_theme_key(),
			_DEFAULT_CUSTOM_THEME
		)
	ProjectSettings.add_property_info(
		{
			"name": get_custom_theme_key(),
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tres"
		}
	)
	ProjectSettings.set_as_basic(get_custom_theme_key(), false)
	ProjectSettings.set_initial_value(
		get_custom_theme_key(),
		_DEFAULT_CUSTOM_THEME
	)
	
	if not ProjectSettings.has_setting(get_graph_types_key()):
		ProjectSettings.set_setting(
			get_graph_types_key(),
			_DEFAULT_GRAPH_TYPES
		)
	ProjectSettings.set_as_basic(get_graph_types_key(), false)
	ProjectSettings.set_as_internal(get_graph_types_key(), _SCHEMA_INTERNAL)
	ProjectSettings.set_initial_value(
		get_graph_types_key(),
		_DEFAULT_GRAPH_TYPES
	)
	
	if not ProjectSettings.has_setting(get_dialogue_types_key()):
		ProjectSettings.set_setting(
			get_dialogue_types_key(),
			_DEFAULT_DIALOGUE_TYPES
		)
	ProjectSettings.set_as_basic(get_dialogue_types_key(), false)
	ProjectSettings.set_as_internal(get_dialogue_types_key(), _SCHEMA_INTERNAL)
	ProjectSettings.set_initial_value(
		get_dialogue_types_key(),
		_DEFAULT_DIALOGUE_TYPES
	)
	
	if not ProjectSettings.has_setting(get_choice_types_key()):
		ProjectSettings.set_setting(
			get_choice_types_key(),
			_DEFAULT_CHOICE_TYPES
		)
	ProjectSettings.set_as_basic(get_choice_types_key(), false)
	ProjectSettings.set_as_internal(get_choice_types_key(), _SCHEMA_INTERNAL)
	ProjectSettings.set_initial_value(
		get_choice_types_key(),
		_DEFAULT_CHOICE_TYPES
	)
	
	if not ProjectSettings.has_setting(
		get_editor_dialogue_line_length_guidelines_key()
	):
		ProjectSettings.set_setting(
			get_editor_dialogue_line_length_guidelines_key(),
			_DEFAULT_LINE_LENGTH_GUIDELINES
		)
	ProjectSettings.add_property_info(
		{
			"name": get_editor_dialogue_line_length_guidelines_key(),
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "int",
		}
	)
	ProjectSettings.set_as_basic(
		get_editor_dialogue_line_length_guidelines_key(),
		true
	)
	ProjectSettings.set_initial_value(
		get_editor_dialogue_line_length_guidelines_key(),
		_DEFAULT_LINE_LENGTH_GUIDELINES
	)
	
	if not ProjectSettings.has_setting(
		get_editor_dialogue_node_initial_width_key()
	):
		ProjectSettings.set_setting(
			get_editor_dialogue_node_initial_width_key(),
			_NODE_DEFAULT_INITIAL_WIDTH
		)
	ProjectSettings.set_as_basic(
		get_editor_dialogue_node_initial_width_key(),
		true
	)
	ProjectSettings.set_initial_value(
		get_editor_dialogue_node_initial_width_key(),
		_NODE_DEFAULT_INITIAL_WIDTH
	)
	
	if not ProjectSettings.has_setting(
		get_editor_choice_node_initial_width_key()
	):
		ProjectSettings.set_setting(
			get_editor_choice_node_initial_width_key(),
			_NODE_DEFAULT_INITIAL_WIDTH
		)
	ProjectSettings.set_as_basic(
		get_editor_choice_node_initial_width_key(),
		true
	)
	ProjectSettings.set_initial_value(
		get_editor_choice_node_initial_width_key(),
		_NODE_DEFAULT_INITIAL_WIDTH
	)
	
	if not ProjectSettings.has_setting(
		get_editor_log_level_key()
	):
		ProjectSettings.set_setting(
			get_editor_log_level_key(),
			_DEFAULT_EDITOR_LOG_LEVEL
		)
	ProjectSettings.add_property_info(
		{
			"name": get_editor_log_level_key(),
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Trace,Debug,Info,Warn,Error,Fatal",
		}
	)
	ProjectSettings.set_as_basic(
		get_editor_log_level_key(),
		false
	)
	ProjectSettings.set_initial_value(
		get_editor_log_level_key(),
		_DEFAULT_EDITOR_LOG_LEVEL
	)
	
	if not ProjectSettings.has_setting(
		get_previewer_log_level_key()
	):
		ProjectSettings.set_setting(
			get_previewer_log_level_key(),
			_DEFAULT_PREVIEWER_LOG_LEVEL
		)
	ProjectSettings.add_property_info(
		{
			"name": get_previewer_log_level_key(),
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Trace,Debug,Info,Warn,Error,Fatal",
		}
	)
	ProjectSettings.set_as_basic(
		get_previewer_log_level_key(),
		false
	)
	ProjectSettings.set_initial_value(
		get_previewer_log_level_key(),
		_DEFAULT_PREVIEWER_LOG_LEVEL
	)
	
	if not ProjectSettings.has_setting(
		get_runtime_log_level_key()
	):
		ProjectSettings.set_setting(
			get_runtime_log_level_key(),
			_DEFAULT_RUNTIME_LOG_LEVEL
		)
	ProjectSettings.add_property_info(
		{
			"name": get_runtime_log_level_key(),
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Trace,Debug,Info,Warn,Error,Fatal",
		}
	)
	ProjectSettings.set_as_basic(
		get_runtime_log_level_key(),
		false
	)
	ProjectSettings.set_initial_value(
		get_runtime_log_level_key(),
		_DEFAULT_RUNTIME_LOG_LEVEL
	)
	
	if not ProjectSettings.has_setting(
		get_property_definitions_key()
	):
		ProjectSettings.set_setting(
			get_property_definitions_key(),
			_DEFAULT_PROPERTY_DEFINITIONS
		)
	ProjectSettings.add_property_info(
		{
			"name": get_property_definitions_key(),
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "Dictionary",
		}
	)
	ProjectSettings.set_as_basic(
		get_property_definitions_key(),
		false
	)
	ProjectSettings.set_as_internal(
		get_property_definitions_key(),
		_SCHEMA_INTERNAL
	)
	ProjectSettings.set_initial_value(
		get_property_definitions_key(),
		_DEFAULT_PROPERTY_DEFINITIONS
	)
	
	if not ProjectSettings.has_setting(
		get_variables_key()
	):
		ProjectSettings.set_setting(
			get_variables_key(),
			_DEFAULT_VARIABLES
		)
	ProjectSettings.add_property_info(
		{
			"name": get_variables_key(),
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "Dictionary",
		}
	)
	ProjectSettings.set_as_basic(
		get_variables_key(),
		false
	)
	ProjectSettings.set_as_internal(
		get_variables_key(),
		_SCHEMA_INTERNAL
	)
	ProjectSettings.set_initial_value(
		get_variables_key(),
		_DEFAULT_VARIABLES
	)
	
	ProjectSettings.save()

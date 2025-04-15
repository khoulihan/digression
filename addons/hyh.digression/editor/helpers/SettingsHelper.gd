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


static func get_editor_dialogue_line_length_guidelines() -> String:
	return "%s/%s/dialogue_line_length_guidelines" % [
		SETTINGS_APPLICATION,
		SETTINGS_EDITOR_SECTION
	]


static func create_default_project_settings() -> void:
	if not ProjectSettings.has_setting(get_theme_key()):
		ProjectSettings.set_setting(
			get_theme_key(),
			BuiltinTheme.DEFAULT
		)
	ProjectSettings.add_property_info(
		{
			"name": get_theme_key(),
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "None,Default,High Contrast",
		}
	)
	if not ProjectSettings.has_setting(get_custom_theme_key()):
		ProjectSettings.set_setting(
			get_custom_theme_key(),
			""
		)
	ProjectSettings.add_property_info(
		{
			"name": get_custom_theme_key(),
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tres"
		}
	)
	if not ProjectSettings.has_setting(get_graph_types_key()):
		ProjectSettings.set_setting(
			get_graph_types_key(),
			[
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
		)
	if not ProjectSettings.has_setting(get_dialogue_types_key()):
		ProjectSettings.set_setting(
			get_dialogue_types_key(),
			[
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
		)
	if not ProjectSettings.has_setting(get_choice_types_key()):
		ProjectSettings.set_setting(
			get_choice_types_key(),
			[
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
		)
	if not ProjectSettings.has_setting(get_editor_dialogue_line_length_guidelines()):
		ProjectSettings.set_setting(
			get_editor_dialogue_line_length_guidelines(),
			[80]
		)
	ProjectSettings.add_property_info(
		{
			"name": get_editor_dialogue_line_length_guidelines(),
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "int",
		}
	)
	ProjectSettings.save()


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


static func get_variables() -> Array[Dictionary]:
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


static func get_choice_types() -> Array:
	return get_collection_setting(
		get_choice_types_key()
	)


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
		get_editor_dialogue_line_length_guidelines(),
		[],
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

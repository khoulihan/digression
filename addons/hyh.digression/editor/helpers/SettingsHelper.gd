@tool
extends RefCounted
## Helper class for dealing with project settings.

const SETTINGS_SECTION = "digression_dialogue_graph_editor"


static func get_graph_types_key() -> String:
	return "%s/graph_types" % SETTINGS_SECTION


static func get_dialogue_types_key() -> String:
	return "%s/dialogue_types" % SETTINGS_SECTION


static func get_choice_types_key() -> String:
	return "%s/choice_types" % SETTINGS_SECTION


static func get_property_definitions_key() -> String:
	return "%s/property_definitions" % SETTINGS_SECTION


static func get_variables_key() -> String:
	return "%s/variables" % SETTINGS_SECTION


static func create_default_project_settings() -> void:
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

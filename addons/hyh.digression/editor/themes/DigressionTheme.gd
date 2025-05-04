@tool
extends RefCounted


const DigressionSettings = preload("../settings/DigressionSettings.gd")

static var _loaded_theme: Theme
static var _last_custom_theme_path: Variant
static var _last_builtin_theme: DigressionSettings.BuiltinTheme


## Return the current node theme.
static func get_theme() -> Theme:
	if has_theme_changed():
		load_theme()
	return _loaded_theme


static func load_theme() -> void:
	var custom_theme_path := DigressionSettings.get_custom_theme()
	_last_custom_theme_path = custom_theme_path
	if not custom_theme_path.is_empty():
		_loaded_theme = load(custom_theme_path)
		return
	var builtin := DigressionSettings.get_built_in_theme()
	_last_builtin_theme = builtin
	match builtin:
		DigressionSettings.BuiltinTheme.NONE:
			_loaded_theme = null
		DigressionSettings.BuiltinTheme.DEFAULT:
			_loaded_theme = load("res://addons/hyh.digression/editor/themes/default/node_theme.tres")
		DigressionSettings.BuiltinTheme.HIGH_CONTRAST:
			_loaded_theme = load("res://addons/hyh.digression/editor/themes/high_contrast/high_contrast_node_theme.tres")


static func has_theme_changed() -> bool:
	var custom_theme_path := DigressionSettings.get_custom_theme()
	if _last_custom_theme_path != custom_theme_path:
		return true
	var builtin := DigressionSettings.get_built_in_theme()
	return builtin != _last_builtin_theme

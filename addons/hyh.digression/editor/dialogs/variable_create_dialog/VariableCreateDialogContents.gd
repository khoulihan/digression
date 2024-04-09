@tool
extends MarginContainer
## Variable creation dialog contents.


signal tag_added()
signal cancelled()
signal created(variable)

const SettingsHelper = preload("../../helpers/SettingsHelper.gd")
const Logging = preload("../../../utility/Logging.gd")
const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const TagControlScene = preload("../../controls/TagControl.tscn")
const WARNING_ICON = preload("../../../icons/icon_node_warning.svg")

var _logger = Logging.new(Logging.DGE_EDITOR_LOG_NAME, Logging.DGE_EDITOR_LOG_LEVEL)
var _type_restriction : Variant
var _variables: Array[Dictionary]
var _all_tags: Array[String]
var _all_names: Array[String]

@onready var _scope_option: OptionButton = $VB/GC/ScopeOption
@onready var _scope_validation_warning: TextureRect = $VB/GC/ScopeValidationWarning
@onready var _type_option: OptionButton = $VB/GC/TypeOption
@onready var _type_validation_warning: TextureRect = $VB/GC/TypeValidationWarning
@onready var _name_edit: LineEdit = $VB/GC/NameEdit
@onready var _name_validation_warning: TextureRect = $VB/GC/NameValidationWarning
@onready var _description_edit: TextEdit = $VB/DescriptionEdit
@onready var _tag_container: HFlowContainer = $VB/TagContainer
@onready var _tag_edit: LineEdit = $VB/TagContainer/TagEdit
@onready var _tag_suggestions_container: HFlowContainer = $VB/TagContainer/SuggestionsContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	_type_restriction = get_parent().type_restriction
	if _type_restriction != null:
		_type_option.select(
			_type_option.get_item_index(_type_restriction)
		)
		_type_option.disabled = true
	_clear_tag_container()
	_validate()
	var default: Array[Dictionary] = []
	_variables = SettingsHelper.get_variables()
	_all_tags = _get_all_tags(_variables)
	_all_names = _get_all_names(_variables)


func _get_all_tags(variables) -> Array[String]:
	var tags: Array[String] = []
	for v in variables:
		for t in v['tags']:
			if not t in tags:
				tags.append(t)
	tags.sort_custom(
		func(a, b): return a.naturalnocasecmp_to(b) < 0
	)
	return tags


func _get_all_names(variables) -> Array[String]:
	var names: Array[String] = []
	for v in variables:
		names.append(v['name'])
	names.sort_custom(
		func(a, b): return a.naturalnocasecmp_to(b) < 0
	)
	return names


func _validate():
	var valid = true
	
	_scope_validation_warning.texture = null
	_scope_validation_warning.tooltip_text = ""
	if _scope_option.selected == -1:
		_scope_validation_warning.tooltip_text = "Scope is required."
		_scope_validation_warning.texture = WARNING_ICON
		valid = false
	
	_type_validation_warning.texture = null
	_type_validation_warning.tooltip_text = ""
	if _type_option.selected == -1:
		_type_validation_warning.tooltip_text = "Type is required."
		_type_validation_warning.texture = WARNING_ICON
		valid = false
	
	_name_validation_warning.texture = null
	_name_validation_warning.tooltip_text = ""
	var name_entered = _name_edit.text.strip_edges()
	if name_entered == "":
		_name_validation_warning.tooltip_text = "Name is required, and must not\nconsist of whitespace."
		_name_validation_warning.texture = WARNING_ICON
		valid = false
	if _is_name_in_use(name_entered):
		_name_validation_warning.tooltip_text = "This name is already in use."
		_name_validation_warning.texture = WARNING_ICON
		valid = false
	
	return valid


func _is_name_in_use(n):
	for existing in _all_names:
		if existing.nocasecmp_to(n) == 0:
			return true
	return false


func _clear_tag_container():
	if _tag_container.get_child_count() <= 1:
		return
	for index in range(_tag_container.get_child_count() - 3, -1, -1):
		_tag_container.remove_child(_tag_container.get_child(index))


func _tag_exists(new_tag):
	for index in range(_tag_container.get_child_count() - 3, -1, -1):
		var tag = _tag_container.get_child(index)
		if tag.tag == new_tag:
			return true
	return false


func _get_tags():
	var tags = []
	for index in range(_tag_container.get_child_count() - 3, -1, -1):
		var tag = _tag_container.get_child(index)
		tags.append(tag.tag)
	return tags


func _perform_save():
	var new_variable = {
		'name': _name_edit.text.strip_edges(),
		"scope": _scope_option.get_selected_id(),
		"type": _type_option.get_selected_id(),
		"description": _description_edit.text.strip_edges(),
		"tags": _get_tags()
	}
	_variables.append(new_variable)
	SettingsHelper.save_variables(_variables)
	
	return new_variable


func _clear_tag_suggestions():
	for child in _tag_suggestions_container.get_children():
		_tag_suggestions_container.remove_child(child)


func _generate_tag_suggestions(text):
	_clear_tag_suggestions()
	var suggestions = _get_tag_suggestions(text, 3)
	for s in suggestions:
		var b = Button.new()
		b.text = s
		b.pressed.connect(_on_tag_suggestion_pressed.bind(b))
		_tag_suggestions_container.add_child(b)


func _get_tag_suggestions(starting_with, max_count):
	var similarities = []
	var results = []
	
	for t in _all_tags:
		# Exclude tags that have already been selected
		if _tag_exists(t):
			continue
		var s = TagSimilarity.new()
		s.tag = t
		# This algorithm is mostly based on the similarity
		# index, but tags that start with or contain the
		# text as a substring are given priority.
		s.similarity = t.similarity(starting_with)
		if t.to_upper().begins_with(starting_with.to_upper()):
			s.similarity += 1.2
		elif t.to_upper().contains(starting_with.to_upper()):
			s.similarity += 1.1
		similarities.append(s)
	similarities.sort_custom(
		func(a, b): return a.similarity > b.similarity
	)
	
	var count = 0
	for s in similarities:
		if count >= max_count:
			break
		# An arbitrary threshold for similarity below which
		# tags are rejected, otherwise completely unrelated
		# tags sometimes show up in the results.
		if s.similarity < 0.2:
			continue
		results.append(s.tag)
		count += 1
	
	return results


func _on_tag_edit_text_submitted(new_text):
	var real_text = new_text.strip_edges()
	_clear_tag_suggestions()
	if real_text == "":
		_tag_edit.clear()
		return
	if _tag_exists(real_text):
		_tag_edit.clear()
		return
	var t = TagControlScene.instantiate()
	t.remove_requested.connect(
		_on_tag_remove_requested.bind(t)
	)
	_tag_container.add_child(t)
	t.tag = real_text
	_tag_container.move_child(t, _tag_container.get_child_count() - 3)
	_tag_edit.clear()
	tag_added.emit()


func _on_tag_remove_requested(tag):
	_tag_container.remove_child(tag)
	tag.queue_free()


func _on_name_edit_text_changed(new_text):
	_validate()


func _on_scope_option_item_selected(index):
	_validate()


func _on_type_option_item_selected(index):
	_validate()


func _on_create_button_pressed():
	if not _validate():
		var dialog = AcceptDialog.new()
		dialog.title = "Validation Failed"
		dialog.dialog_text = """There are graph items with duplicate names.\n
			Please correct the values and try again."""
		self.add_child(dialog)
		dialog.popup_on_parent(
			Rect2i(
				self.position + Vector2(60, 60),
				Vector2i(200, 150)
			)
		)
		dialog.confirmed.connect(
			_on_validation_failed_dialog_closed.bind(dialog)
		)
		dialog.close_requested.connect(
			_on_validation_failed_dialog_closed.bind(dialog)
		)
	else:
		created.emit(_perform_save())


func _on_validation_failed_dialog_closed(dialog):
	_logger.debug("Validation failed dialog closed.")
	dialog.confirmed.disconnect(_on_validation_failed_dialog_closed)
	dialog.close_requested.disconnect(_on_validation_failed_dialog_closed)
	dialog.queue_free()


func _on_cancel_button_pressed():
	cancelled.emit()


func _on_tag_suggestion_pressed(button):
	var tag = button.text
	_on_tag_edit_text_submitted(tag)
	_tag_edit.grab_focus()


func _on_tag_edit_text_changed(new_text):
	if len(new_text) <= 1:
		_clear_tag_suggestions()
		return
	_generate_tag_suggestions(new_text)


class TagSimilarity:
	var tag: String
	var similarity: float

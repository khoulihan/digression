@tool
extends MarginContainer


const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


@onready var ScopeOption: OptionButton = get_node("VBoxContainer/GridContainer/ScopeOption")
@onready var ScopeValidationWarning: TextureRect = get_node("VBoxContainer/GridContainer/ScopeValidationWarning")
@onready var TypeOption: OptionButton = get_node("VBoxContainer/GridContainer/TypeOption")
@onready var TypeValidationWarning: TextureRect = get_node("VBoxContainer/GridContainer/TypeValidationWarning")
@onready var NameEdit: LineEdit = get_node("VBoxContainer/GridContainer/NameEdit")
@onready var NameValidationWarning: TextureRect = get_node("VBoxContainer/GridContainer/NameValidationWarning")
@onready var DescriptionEdit: TextEdit = get_node("VBoxContainer/DescriptionEdit")

@onready var TagContainer: HFlowContainer = get_node("VBoxContainer/TagContainer")
@onready var TagEdit: LineEdit = get_node("VBoxContainer/TagContainer/TagEdit")
@onready var TagSuggestionsContainer: HFlowContainer = get_node("VBoxContainer/TagContainer/SuggestionsContainer")


const TagControlScene = preload("res://addons/hyh.cutscene_graph/editor/controls/TagControl.tscn")
const WarningIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_node_warning.svg")

signal tag_added()
signal cancelled()
signal created(variable)


var _variables: Array[Dictionary]
var _all_tags: Array[String]
var _all_names: Array[String]


# Called when the node enters the scene tree for the first time.
func _ready():
	_clear_tag_container()
	_validate()
	var default: Array[Dictionary] = []
	_variables = ProjectSettings.get_setting(
		"cutscene_graph_editor/variables",
		default
	)
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
	
	ScopeValidationWarning.texture = null
	ScopeValidationWarning.tooltip_text = ""
	if ScopeOption.selected == -1:
		ScopeValidationWarning.tooltip_text = "Scope is required."
		ScopeValidationWarning.texture = WarningIcon
		valid = false
	
	TypeValidationWarning.texture = null
	TypeValidationWarning.tooltip_text = ""
	if TypeOption.selected == -1:
		TypeValidationWarning.tooltip_text = "Type is required."
		TypeValidationWarning.texture = WarningIcon
		valid = false
	
	NameValidationWarning.texture = null
	NameValidationWarning.tooltip_text = ""
	var name_entered = NameEdit.text.strip_edges()
	if name_entered == "":
		NameValidationWarning.tooltip_text = "Name is required, and must not\nconsist of whitespace."
		NameValidationWarning.texture = WarningIcon
		valid = false
	if _is_name_in_use(name_entered):
		NameValidationWarning.tooltip_text = "This name is already in use."
		NameValidationWarning.texture = WarningIcon
		valid = false
	
	return valid


func _is_name_in_use(n):
	for existing in _all_names:
		if existing.nocasecmp_to(n) == 0:
			return true
	return false


func _clear_tag_container():
	if TagContainer.get_child_count() <= 1:
		return
	for index in range(TagContainer.get_child_count() - 3, -1, -1):
		TagContainer.remove_child(TagContainer.get_child(index))


func _tag_exists(new_tag):
	for index in range(TagContainer.get_child_count() - 3, -1, -1):
		var tag = TagContainer.get_child(index)
		if tag.tag == new_tag:
			return true
	return false


func _on_tag_edit_text_submitted(new_text):
	var real_text = new_text.strip_edges()
	_clear_tag_suggestions()
	if real_text == "":
		TagEdit.clear()
		return
	if _tag_exists(real_text):
		TagEdit.clear()
		return
	var t = TagControlScene.instantiate()
	t.remove_requested.connect(
		_on_tag_remove_requested.bind(t)
	)
	t.tag = real_text
	TagContainer.add_child(t)
	TagContainer.move_child(t, TagContainer.get_child_count() - 3)
	TagEdit.clear()
	tag_added.emit()


func _on_tag_remove_requested(tag):
	TagContainer.remove_child(tag)
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
			_validation_failed_dialog_closed.bind(dialog)
		)
		dialog.close_requested.connect(
			_validation_failed_dialog_closed.bind(dialog)
		)
	else:
		created.emit(_perform_save())


func _validation_failed_dialog_closed(dialog):
	Logger.debug("Validation failed dialog closed.")
	dialog.confirmed.disconnect(_validation_failed_dialog_closed)
	dialog.close_requested.disconnect(_validation_failed_dialog_closed)
	dialog.queue_free()


func _get_tags():
	var tags = []
	for index in range(TagContainer.get_child_count() - 3, -1, -1):
		var tag = TagContainer.get_child(index)
		tags.append(tag.tag)
	return tags


func _perform_save():
	var new_variable = {
		'name': NameEdit.text.strip_edges(),
		"scope": ScopeOption.get_selected_id(),
		"type": TypeOption.get_selected_id(),
		"description": DescriptionEdit.text.strip_edges(),
		"tags": _get_tags()
	}
	_variables.append(new_variable)
	
	ProjectSettings.set_setting(
		"cutscene_graph_editor/variables",
		_variables
	)
	ProjectSettings.save()
	
	return new_variable


func _on_cancel_button_pressed():
	cancelled.emit()


func _clear_tag_suggestions():
	for child in TagSuggestionsContainer.get_children():
		TagSuggestionsContainer.remove_child(child)


func _generate_tag_suggestions(text):
	_clear_tag_suggestions()
	var suggestions = _get_tag_suggestions(text, 3)
	for s in suggestions:
		var b = Button.new()
		b.text = s
		b.pressed.connect(_tag_suggestion_pressed.bind(b))
		TagSuggestionsContainer.add_child(b)


func _tag_suggestion_pressed(button):
	var tag = button.text
	_on_tag_edit_text_submitted(tag)
	TagEdit.grab_focus()


class TagSimilarity:
	var tag: String
	var similarity: float


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


func _on_tag_edit_text_changed(new_text):
	if len(new_text) <= 1:
		_clear_tag_suggestions()
		return
	_generate_tag_suggestions(new_text)

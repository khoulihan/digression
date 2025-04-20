@tool
extends "GraphNodeBase.gd"
## A node for grouping related dialogue texts.


const DialogueSection = preload("DialogueSection.gd")

## The user-defined type of the dialogue.
@export var dialogue_type: String

## A character associated with this dialogue group, if any.
@export var character: Character

## The child text resources.
@export var sections: Array[DialogueSection]

# This is used only for recreating the node state in the editor
@export var size: Vector2


func _init():
	self.sections = [DialogueSection.new()]


func add_section() -> DialogueSection:
	var section := DialogueSection.new()
	section.text_translation_key = _derive_translation_key()
	self.sections.append(section)
	return section


func remove_section(section: DialogueSection) -> void:
	self.sections.remove_at(
		self.sections.find(section)
	)


func set_initial_translation_key(key: String) -> void:
	if self.sections == null:
		return
	if len(self.sections) < 1:
		return
	self.sections[0].text_translation_key = key


func _derive_translation_key() -> String:
	if len(self.sections) == 0:
		return ""
	# Ideally we will just be incrementing or appending to the value of the last
	# section, but there is a chance that the sections could be out of order, so
	# instead I think we need to find all sections with numeric endings (*_1 format)
	# then determine the largest one. I think also we will only match sections
	# with the same root key as the last section.
	var last_section := self.sections[-1]
	var last_key := last_section.text_translation_key
	if len(last_key) == 0:
		return ""
	var key_root := last_key
	var last_key_split := last_key.rsplit("_", true, 1)
	if len(last_key_split) > 1:
		if last_key_split[-1].is_valid_int():
			key_root = last_key_split[0]
	var max_inc: int = 0
	for section in self.sections:
		var inc := _incrementable_for_root(section, key_root)
		if inc > max_inc:
			max_inc = inc
	return "{0}_{1}".format([key_root, max_inc + 1])


func _incrementable_for_root(section: DialogueSection, root: String) -> int:
	var key := section.text_translation_key
	if not key.begins_with(root):
		return -1
	var key_split := key.rsplit("_", true, 1)
	if len(key_split) > 1:
		if key_split[-1].is_valid_int():
			return key_split[-1].to_int()
	return -1

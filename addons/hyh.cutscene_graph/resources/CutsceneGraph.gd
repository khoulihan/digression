@tool
@icon("res://addons/hyh.cutscene_graph/icon_graph_node.svg")
extends Resource

class_name CutsceneGraph

## An identifier for this cutscene to represent it in code.
@export var name: String

## An optional display name to represent the cutscene to the player.
@export var display_name: String

## An arbitrary identifier for the type of cutscene.
@export var graph_type: String

## If true, dialogue nodes with multiple lines will be split and each line
## treated separately. Otherwise the entire dialogue is returned at once.
@export var split_dialogue = true

## The characters that are involved in this cutscene.
@export var characters: Array[Character]

## Optional notes.
@export_multiline var notes = ""


var nodes: Dictionary
var root_node: Resource


# This is necessary to ensure that "nodes" and "root_node"
# are saved to the resource. They are not exported because
# I don't want them to be shown in the inspector.
func _get_property_list():
	var properties = []
	properties.append({
		"name": "nodes",
		"type": TYPE_DICTIONARY,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	properties.append({
		"name": "root_node",
		"type": Resource,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties


func get_next_id():
	var id = 1
	var existing = nodes.keys()
	while true:
		if !(id in existing):
			return id
		id += 1
		


func _init():
	self.nodes = {}
	self.characters = []

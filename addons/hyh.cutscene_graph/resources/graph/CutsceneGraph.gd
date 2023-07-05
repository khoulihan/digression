@tool
@icon("res://addons/hyh.cutscene_graph/icons/icon_graph_node.svg")
extends Resource

class_name CutsceneGraph

## An identifier for this cutscene to represent it in code.
@export var name: String

## An optional display name to represent the cutscene to the player.
@export var display_name: String

## An arbitrary identifier for the type of cutscene.
var graph_type: String

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
	
	var graph_types = ProjectSettings.get_setting(
		"cutscene_graph_editor/graph_types",
		[]
	)
	var graph_type_names = []
	for gt in graph_types:
		graph_type_names.append(gt["name"])
	var graph_types_hint: String = ",".join(graph_type_names)
	
	properties.append({
		"name": "graph_type",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": graph_types_hint,
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
	var graph_types = ProjectSettings.get_setting(
		"cutscene_graph_editor/graph_types",
		""
	)
	var default_graph_type = ""
	for gt in graph_types:
		if gt["default"]:
			default_graph_type = gt["name"]
			break
	self.graph_type = default_graph_type

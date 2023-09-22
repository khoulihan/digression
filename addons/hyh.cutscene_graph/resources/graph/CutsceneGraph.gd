@tool
@icon("res://addons/hyh.cutscene_graph/icons/icon_chat.svg")
extends Resource

class_name CutsceneGraph


# Utility classes.
const ResourceHelper = preload("../../utility/ResourceHelper.gd")


const AnchorNode = preload("AnchorNode.gd")
const SubGraph = preload("SubGraph.gd")
const DialogueChoiceNode = preload("DialogueChoiceNode.gd")
const BranchNode = preload("BranchNode.gd")
const RandomNode = preload("RandomNode.gd")

const NEW_ANCHOR_PREFIX = "destination_"


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


## Get a count + 1 of the teleport destination nodes in the graph
## for automatic naming purposes.
func get_next_anchor_number():
	var number = 1
	for n in nodes.values():
		if n is AnchorNode:
			if n.name.begins_with(NEW_ANCHOR_PREFIX):
				var node_number = n.name.substr(12)
				if node_number.is_valid_int():
					var converted = node_number.to_int()
					if converted >= number:
						number = converted
			number += 1
	return number


## Build maps of the anchor nodes
## name -> id and id -> name
func get_anchor_maps():
	var by_name = {}
	var by_id = {}
	
	for n in nodes.values():
		if n is AnchorNode:
			by_name[n.name] = n.id
			by_id[n.id] = n.name
	
	return [by_name, by_id]


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


func duplicate_with_nodes():
	# Need this to replace built-in `duplicate` method, which is not
	# copying the nodes collection.
	var duplicate = CutsceneGraph.new()
	duplicate.name = self.name
	duplicate.display_name = self.display_name
	duplicate.graph_type = self.graph_type
	duplicate.notes = self.notes
	
	# Copy the characters, creating a map to allow the new nodes to be
	# pointed at the copies. Only embedded characters are duplicated.
	var character_map = {}
	var variant_map = {}
	for character in self.characters:
		if not ResourceHelper.is_embedded(character):
			character_map[character] = character
			for variant in character.character_variants:
				variant_map[variant] = variant
			duplicate.characters.append(character)
		else:
			var character_dup = character.duplicate()
			character_dup.character_variants.clear()
			character_map[character] = character_dup
			for variant in character.character_variants:
				if not ResourceHelper.is_embedded(variant):
					variant_map[variant] = variant
					character_dup.character_variants.append(variant)
				else:
					var variant_dup = variant.duplicate()
					variant_map[variant] = variant_dup
					character_dup.character_variants.append(variant_dup)
			duplicate.characters.append(character_dup)
	
	# Copy the nodes
	#duplicate.nodes.clear()
	for node_id in self.nodes.keys():
		var node = self.nodes[node_id]
		var node_dup = _duplicate_node(
			node,
			character_map,
			variant_map,
		)
		duplicate.nodes[node_id] = node_dup
		if self.root_node == node:
			duplicate.root_node = node_dup

	# Since we are using the same IDs, connections should
	# work fine in the duplicate...
	
	return duplicate


func _duplicate_node(node, character_map, variant_map):
	var node_dup = node.duplicate()
	
	if node is SubGraph:
		if ResourceHelper.is_embedded(node.sub_graph):
			node_dup.sub_graph = node.sub_graph.duplicate_with_nodes()
	if "character" in node:
		if node.character != null:
			node_dup.character = character_map[node.character]
	if "character_variant" in node:
		if node.character_variant != null:
			node_dup.character_variant = variant_map[node.character_variant]
	# "dialogue" property of DialogueChoiceNode
	if "dialogue" in node:
		node_dup.dialogue = _duplicate_node(
			node.dialogue,
			character_map,
			variant_map,
		)
	# Duplicate any branch resources
	# Branch node currently does not require this because its branches
	# are just IDs
	if node is DialogueChoiceNode:
		node_dup.choices.clear()
		for choice in node.choices:
			node_dup.choices.append(choice.duplicate(true))
	if node is RandomNode:
		node_dup.branches.clear()
		for branch in node.branches:
			node_dup.branches.append(branch.duplicate(true))
	# TODO: Do we need to deal with Conditions explicitly?
	return node_dup

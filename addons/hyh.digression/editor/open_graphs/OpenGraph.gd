@tool
extends RefCounted
## A graph resource that is currently open, and related metadata.


const DigressionSettings = preload("../../settings/DigressionSettings.gd")


var graph : DigressionDialogueGraph
var path: String
var dirty: bool
var zoom: float
var scroll_offset: Vector2


var dialogue_types: Array
var choice_types: Array


func _init(graph: DigressionDialogueGraph, path: String) -> void:
	self.graph = graph
	self.path = path
	dirty = false
	zoom = 1.0
	scroll_offset = Vector2.ZERO
	refresh_types()


## Reload the dialogue and choice types from the settings.
func refresh_types() -> void:
	dialogue_types = DigressionSettings.get_dialogue_types_for_graph_type(
		self.graph.graph_type
	)
	choice_types = DigressionSettings.get_choice_types_for_graph_type(
		self.graph.graph_type
	)


## Get the default dialogue type for the type of this graph.
func get_default_dialogue_type() -> Variant:
	for t in dialogue_types:
		if graph.graph_type in t['default_in_graph_types']:
			return t
	return null


## Get the default choice type for the type of this graph.
func get_default_choice_type() -> Variant:
	for t in choice_types:
		if graph.graph_type in t['default_in_graph_types']:
			return t
	return null

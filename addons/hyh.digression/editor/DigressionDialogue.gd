@tool
extends Node
## Stores a DigressionDialogueGraph resource and allows it to be triggered.


signal dialogue_graph_triggered(graph)

const Logging = preload("../utility/Logging.gd")
const DigressionDialogueController = preload("DigressionDialogueController.gd")
const EditorEntryPointAnchorNode = preload("nodes/EditorEntryPointAnchorNode.gd")

@export var dialogue_graph: DigressionDialogueGraph

## Indicates whether this DigressionDialogue has ever been triggered.
## There is no need to update this property manually when a DigressionDialogue
## is triggered normally, but it can be used to reset the triggered state,
## or mark the DigressionDialogue as triggered without actually triggering it,
## if that is a state implied by other events in the game. This will also reset
## the `triggered_count`.
var triggered: bool:
	get:
		return _state['triggered_count'] > 0
	set(value):
		if not value:
			_state['triggered_count'] = 0
		else:
			_state['triggered_count'] += 1

## The number of times this DigressionDialogue has been triggered.
## There is no need to update this property manually when a DigressionDialogue is
## triggered normally, but it can be used to manipulate the count if necessary.
var triggered_count: int:
	get:
		return _state['triggered_count']
	set(value):
		_state['triggered_count'] = value

var _dialogue_controller
var _state: Dictionary
var _logger = Logging.new("Digression Dialogue", Logging.DGE_NODES_LOG_LEVEL)


func _ready():
	# Need to find the DigressionDialogueController - there should only be one
	# Do this by walking the tree from the root. This should find it whether
	# it is an autoload or part of the scene.
	# TODO: Plugins can create their own set_choice autoloads now, so maybe we should do that?
	var root = get_tree().root
	if not Engine.is_editor_hint():
		_dialogue_controller = _find_controller(root)
	_state = {
		'triggered_count': 0,
	}


func set_controller(controller):
	_dialogue_controller = controller


## Returns the state Dictionary.
func get_state() -> Dictionary:
	return _state


## Overwrites the current state entirely with the provided Dictionary.
func set_state(saved_state: Dictionary):
	_state = saved_state.duplicate()


## Updates the state with the values from the provided Dictionary.
func update_state(changes: Dictionary):
	_state.merge(changes, true)


## Trigger the node's DigressionDialogueGraph
func trigger(entry_point=null):
	if dialogue_graph == null:
		_logger.error("Dialogue graph node \"%s\" triggered, but no graph is set." % self)
		return
	
	_logger.log("Dialogue graph \"%s\" triggered" % dialogue_graph.name)
	
	if _dialogue_controller == null:
		_logger.error(
			"Dialogue graph node \"%s\" triggered, but no DigressionDialogueController is available." % self
		)
		return
	if _state.has("triggered_count"):
		_state['triggered_count'] += 1
	else:
		_state['triggered_count'] = 1
	dialogue_graph_triggered.emit(self.dialogue_graph)
	_dialogue_controller.process_dialogue_graph(
		dialogue_graph,
		_state,
		entry_point
	)


## Get a list of the available entry points for the node's DigressionDialogueGraph.
func get_entry_points() -> Array[String]:
	var entry_points: Array[String] = []
	if dialogue_graph == null:
		return entry_points
	var anchor_maps = dialogue_graph.get_anchor_maps()
	var by_name = anchor_maps[0]
	var ep = by_name.keys()
	ep.sort()
	entry_points.append(EditorEntryPointAnchorNode.ENTRY_POINT_ANCHOR_NAME)
	for name in ep:
		if name == EditorEntryPointAnchorNode.ENTRY_POINT_ANCHOR_NAME:
			continue
		entry_points.append(name)
	return entry_points


func _find_controller(root):
	if root is DigressionDialogueController:
		return root
	# Breadth-first search on the assumption that the controller
	# will be close to the root rather than deeply nested.
	for child in root.get_children():
		if child is DigressionDialogueController:
			return child
	for child in root.get_children():
		var result = _find_controller(child)
		if result != null:
			return result
	_logger.warn("Dialogue controller not found in scene.")
	return null

extends Node

## Stores a CutsceneGraph resource and allows it to be triggered.

const Logging = preload("../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph", Logging.CGE_NODES_LOG_LEVEL)

const CutsceneController = preload("CutsceneController.gd")

signal cutscene_triggered(cutscene)

@export var cutscene: CutsceneGraph

var _cutscene_controller

var _state: Dictionary


## Indicates whether this Cutscene has ever been triggered.
## There is no need to update this property manually when a Cutscene is
## triggered normally, but it can be used to reset the triggered state,
## or mark the Cutscene as triggered without actually triggering it, if
## that is a state implied by other events in the game. This will also reset
## the `triggered_count`.
var triggered: bool:
	get:
		return _state['triggered_count'] > 0
	set(value):
		if not value:
			_state['triggered_count'] = 0
		else:
			_state['triggered_count'] += 1


## The number of times this Cutscene has been triggered.
## There is no need to update this property manually when a Cutscene is
## triggered normally, but it can be used to manipulate the count if necessary.
var triggered_count: int:
	get:
		return _state['triggered_count']
	set(value):
		_state['triggered_count'] = value


func _ready():
	# Need to find the CutsceneController - there should only be one
	# Do this by walking the tree from the root. This should find it whether
	# it is an autoload or part of the scene.
	# TODO: Plugins can create their own set_choice autoloads now, so maybe we should do that?
	var root = get_tree().root
	_cutscene_controller = _find_controller(root)
	_state = {
		'triggered_count': 0,
	}


func _find_controller(root):
	if root is CutsceneController:
		return root
	# Breadth-first search on the assumption that the controller
	# will be close to the root rather than deeply nested.
	for child in root.get_children():
		if child is CutsceneController:
			return child
	for child in root.get_children():
		var result = _find_controller(child)
		if result != null:
			return result
	Logger.warn("Cutscene controller not found in scene.")
	return null


## Returns the state Dictionary.
func get_state() -> Dictionary:
	return _state


## Overwrites the current state entirely with the provided Dictionary.
func set_state(saved_state: Dictionary):
	_state = saved_state.duplicate()


## Updates the state with the values from the provided Dictionary.
func update_state(changes: Dictionary):
	_state.merge(changes, true)


## Trigger the node's CutsceneGraph
func trigger():
	if cutscene == null:
		Logger.error("Cutscene node \"%s\" triggered, but no graph is set." % self)
		return
	
	Logger.log("Cutscene \"%s\" triggered" % cutscene.name)
	
	if _cutscene_controller == null:
		Logger.error(
			"Cutscene node \"%s\" triggered, but no CutsceneController is available." % self
		)
		return
	_state['triggered_count'] += 1
	emit_signal("cutscene_triggered", self.cutscene)
	_cutscene_controller.process_cutscene(cutscene, _state)

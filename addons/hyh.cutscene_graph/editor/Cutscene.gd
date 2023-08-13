extends Node

## Stores a CutsceneGraph resource and allows it to be triggered.

const Logging = preload("../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph", Logging.CGE_NODES_LOG_LEVEL)

const CutsceneController = preload("CutsceneController.gd")

signal cutscene_triggered(cutscene)

@export var cutscene: CutsceneGraph

var _cutscene_controller


func _ready():
	# Need to find the CutsceneController - there should only be one
	# Do this by walking the tree from the root. This should find it whether
	# it is an autoload or part of the scene.
	# TODO: Plugins can create their own set_choice autoloads now, so maybe we should do that?
	var root = get_tree().root
	_cutscene_controller = _find_controller(root)


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


## Trigger the node's CutsceneGraph
func trigger():
	if cutscene == null:
		Logger.error("Cutscene node \"%s\" triggered, but no graph is set." % self)
		return
	
	Logger.log("Cutscene \"%s\" triggered" % cutscene.name)
	emit_signal("cutscene_triggered", self.cutscene)
	if _cutscene_controller != null:
		_cutscene_controller.process_cutscene(cutscene)
	else:
		Logger.error("Cutscene node \"%s\" triggered, but no CutsceneController is available." % self)

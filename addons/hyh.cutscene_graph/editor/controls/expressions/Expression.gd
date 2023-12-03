@tool
extends VBoxContainer

const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType


@export
var type : VariableType


# Called when the node enters the scene tree for the first time.
func _ready():
	#_configure()
	pass


# I believe it is necessary to avoid confguring these controls in the _ready
# because it is likely to require loading cyclical dependencies. Therefore,
# this method must be called after the node is ready.
func configure():
	pass

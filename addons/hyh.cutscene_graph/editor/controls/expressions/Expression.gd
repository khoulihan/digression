@tool
extends VBoxContainer

const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const ExpressionComponentType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionComponentType


signal modified()
signal size_changed(amount)


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


func validate():
	return null


func serialise():
	return {
		"component_type": ExpressionComponentType.EXPRESSION,
		"variable_type": type,
	}


func deserialise(serialised):
	type = serialised["variable_type"]


# TODO: Might only need this for testing?
# Have ended up using it in the Set node, but maybe should incorporate
# it into deserialise?
func clear():
	pass


func _emit_size_changed(size_before, deferrals_required=2, deferral_count=0):
	# Some changes to the UI aren't reflected in the controls
	# size on the next idle frame, so have to defer until they are.
	if deferral_count == deferrals_required:
		size_changed.emit(self.size.y - size_before)
		return
	call_deferred("_emit_size_changed", size_before, deferrals_required, deferral_count + 1)

@tool
extends Resource


const VariableType = preload("../VariableSetNode.gd").VariableType


@export var next: int = -1
@export var condition: Dictionary = {
	'variable_type': VariableType.TYPE_BOOL,
	'children': [],
}

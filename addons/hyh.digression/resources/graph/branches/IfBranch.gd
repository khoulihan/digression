@tool
extends Resource
## Branch resource for "if" node branches.


const VariableType = preload("../VariableSetNode.gd").VariableType

## The node to proceed to if the condition for this branch evaluates to "true".
@export var next: int = -1

## The expression to evaluate.
@export var condition: Dictionary = {
	'variable_type': VariableType.TYPE_BOOL,
	'children': [],
}

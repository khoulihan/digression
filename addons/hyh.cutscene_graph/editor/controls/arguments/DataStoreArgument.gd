@tool
extends "Argument.gd"


const VariableScope = preload("../../../resources/graph/VariableSetNode.gd").VariableScope
const TransientIcon = preload("../../../icons/icon_scope_transient.svg")
const LOCAL_ICON = preload("../../../icons/icon_scope_local.svg")
const DIALOGUE_GRAPH_ICON = preload("../../../icons/icon_scope_dialogue_graph.svg")
const GLOBAL_ICON = preload("../../../icons/icon_scope_global.svg")

@onready var DataStoreLabel : Label = get_node("ExpressionContainer/PC/ArgumentValueContainer/HB/DataStoreLabel")
@onready var ScopeIcon : TextureRect = get_node("ExpressionContainer/PC/ArgumentValueContainer/HB/ScopeIcon")


@export var scope : VariableScope


func configure():
	super()
	_configure_for_scope()
	validate()


func _configure_for_scope():
	match scope:
		VariableScope.SCOPE_TRANSIENT:
			_set_controls(TransientIcon, "Transient")
		VariableScope.SCOPE_LOCAL:
			_set_controls(LOCAL_ICON, "Local")
		VariableScope.SCOPE_DIALOGUE_GRAPH:
			_set_controls(DIALOGUE_GRAPH_ICON, "Dialogue Graph")
		VariableScope.SCOPE_GLOBAL:
			_set_controls(GLOBAL_ICON, "Global")


func _set_controls(icon, label):
	ScopeIcon.texture = icon
	DataStoreLabel.text = "%s Data Store" % label


func _get_type_name():
	return "Data Store"


func validate():
	ValidationWarning.visible = false

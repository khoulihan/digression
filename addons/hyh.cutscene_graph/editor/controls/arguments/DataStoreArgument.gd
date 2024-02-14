@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/arguments/Argument.gd"


const VariableScope = preload("../../../resources/graph/VariableSetNode.gd").VariableScope
const TransientIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_scope_transient.svg")
const LocalIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_scope_local.svg")
const CutsceneIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_scope_cutscene.svg")
const GlobalIcon = preload("res://addons/hyh.cutscene_graph/icons/icon_scope_global.svg")


@onready var DataStoreLabel : Label = get_node("ExpressionContainer/PC/ArgumentValueContainer/HB/DataStoreLabel")
@onready var ScopeIcon : TextureRect = get_node("ExpressionContainer/PC/ArgumentValueContainer/HB/ScopeIcon")


@export var scope : VariableScope


func configure():
	super()
	_configure_for_scope()


func _configure_for_scope():
	match scope:
		VariableScope.SCOPE_TRANSIENT:
			_set_controls(TransientIcon, "Transient")
		VariableScope.SCOPE_LOCAL:
			_set_controls(LocalIcon, "Local")
		VariableScope.SCOPE_CUTSCENE:
			_set_controls(CutsceneIcon, "Cutscene")
		VariableScope.SCOPE_GLOBAL:
			_set_controls(GlobalIcon, "Global")


func _set_controls(icon, label):
	ScopeIcon.texture = icon
	DataStoreLabel.text = "%s Data Store" % label


func _get_type_name():
	return "Data Store"

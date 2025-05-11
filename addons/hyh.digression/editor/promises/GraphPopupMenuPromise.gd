@tool
extends "Promise.gd"


const GraphPopupMenu = preload("../controls/GraphPopupMenu.gd")


func _init(popup: GraphPopupMenu) -> void:
		super()
		popup.create_node_requested.connect(_resolved)
		popup.popup_hide.connect(_deferred_rejection)


func _resolved(value: Variant = null) -> void:
	super(value)


func _rejected(error: Variant = null) -> void:
	if state == PromiseState.PENDING:
		super(error)


func _deferred_rejection(error: Variant = null) -> void:
	# The rejection condition arises before the resolve condition in this
	# case, so we have to defer it.
	call_deferred("_rejected", error)

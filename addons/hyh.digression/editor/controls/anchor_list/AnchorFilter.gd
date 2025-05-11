@tool
extends VBoxContainer


signal anchor_selected(name: String)


const AnchorList = preload("./AnchorList.gd")
const AnchorManager = preload("../../open_graphs/AnchorManager.gd")


@onready var _filter: LineEdit = $AnchorFilter
@onready var _list: AnchorList = $MC/AnchorList


## Configure the interface for the provided AnchorManager.
func configure(manager: AnchorManager) -> void:
	_list.configure(manager)


## Select the anchor with the provided name.
func select_anchor(name: String) -> void:
	_list.select_anchor(name)


## Clear the list of anchors, and the filter.
func clear_list() -> void:
	_filter.clear()
	_list.clear()


func _on_anchor_filter_text_changed(new_text: String) -> void:
	_list.filter(new_text)


func _on_anchor_filter_text_submitted(new_text: String) -> void:
	if _list.item_count > 0:
		_list.grab_focus()
		_list.select_first_anchor()


func _on_anchor_list_anchor_selected(name: String) -> void:
	anchor_selected.emit(name)

@tool
extends "EditorGraphNodeBase.gd"
## A non-functional, non-connectable node for displaying comments in the editor.


const TITLE_FONT = preload("res://addons/hyh.digression/editor/themes/default/TitleOptionFont.tres")
const FONT_SIZES = [
	16,
	24,
	32,
	64,
]


var _text_size_option: OptionButton


@onready var _comment_edit = $MC/CommentEdit


func _init():
	_text_size_option = OptionButton.new()
	_text_size_option.item_selected.connect(_on_text_size_option_item_selected)
	_text_size_option.focus_entered.connect(_on_text_size_option_focus_entered)
	_text_size_option.focus_exited.connect(_on_text_size_option_focus_exited)
	_text_size_option.flat = true
	_text_size_option.fit_to_longest_item = true
	_text_size_option.add_theme_font_override("font", TITLE_FONT)
	_text_size_option.add_item("Small", 0)
	_text_size_option.add_item("Normal", 1)
	_text_size_option.add_item("Large", 2)
	_text_size_option.add_item("Huge", 3)


func _ready():
	var titlebar = get_titlebar_hbox()
	var title_label : Label = titlebar.get_child(0)
	titlebar.add_child(_text_size_option)
	# By moving to index 0, the empty title label serves as a spacer.
	titlebar.move_child(_text_size_option, 0)
	_text_size_option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# This prevents the node size from changing as the size option
	# is shown and hidden with changes in the nodes focus.
	title_label.custom_minimum_size.y = _text_size_option.size.y
	super()


var show_close: bool:
	set(value):
		_close_button.visible = value
	get:
		return _close_button.visible


var show_text_size_option: bool:
	set(value):
		_text_size_option.visible = value
	get:
		return _text_size_option.visible


## Configure the editor node for the provided resource node.
func configure_for_node(g, n):
	super.configure_for_node(g, n)
	if n.size != Vector2.ZERO:
		size = n.size
	self.set_comment(n.comment)
	_text_size_option.select(n.text_size)
	_set_font_size(n.text_size)
	self.show_close = false
	self.show_text_size_option = false


## Save the state of the editor node to the resource.
func persist_changes_to_node():
	super.persist_changes_to_node()
	node_resource.size = self.size
	node_resource.comment = self.get_comment()
	node_resource.text_size = _text_size_option.selected


## Get the comment displayed in the UI.
func get_comment():
	return _comment_edit.text


## Set the comment text.
func set_comment(comment):
	_comment_edit.text = comment


func _set_font_size(s):
	_comment_edit.add_theme_font_size_override("font_size", FONT_SIZES[s])
	set_deferred("size", Vector2(size.x, 0.0))


func _control_focus_changed(focused):
	self.selected = focused
	self.show_close = focused
	self.show_text_size_option = focused
	self.resizable = focused


func _on_comment_edit_text_changed():
	set_deferred("size", Vector2(size.x, 0.0))
	emit_signal("modified")


func _on_resize_request(new_minsize):
	set_deferred("size", Vector2(new_minsize.x, 0.0))
	#self.set_size(new_minsize)


func _on_node_selected():
	self.show_close = true
	self.show_text_size_option = true
	self.resizable = true


func _on_node_deselected():
	self.show_close = false
	self.show_text_size_option = false
	self.resizable = false


func _on_comment_edit_focus_entered() -> void:
	_control_focus_changed(true)


func _on_comment_edit_focus_exited() -> void:
	_control_focus_changed(false)


func _on_text_size_option_focus_entered() -> void:
	_control_focus_changed(true)


func _on_text_size_option_focus_exited() -> void:
	_control_focus_changed(false)


func _on_text_size_option_item_selected(index):
	_set_font_size(index)


func _on_focus_entered() -> void:
	_control_focus_changed(true)


func _on_focus_exited() -> void:
	_control_focus_changed(false)

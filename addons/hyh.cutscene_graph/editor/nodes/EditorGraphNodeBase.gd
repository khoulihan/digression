@tool
extends GraphNode
## Base class/scene for all editor nodes.


signal removing_slot(slot)
signal popup_request(p_position)
signal modified()

const Logging = preload("../../utility/Logging.gd")
const CLOSE_ICON = preload("res://addons/hyh.cutscene_graph/icons/icon_close.svg")
const GraphNodeBase = preload("../../resources/graph/GraphNodeBase.gd")
const CONNECTOR_COLOUR = Color("#f2f2f2e1")

@export var is_root : bool : set = set_root
@export var node_resource: GraphNodeBase

var graph

var _root_indicator: TextureRect
var _logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


func _ready() -> void:
	var titlebar := get_titlebar_hbox()
	var close_button := Button.new()
	close_button.text = ""
	close_button.icon = CLOSE_ICON
	close_button.flat = true
	close_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(_close_button_pressed)
	var root_indicator := TextureRect.new()
	root_indicator.texture = get_theme_icon("PinJoint3D", "EditorIcons")
	root_indicator.visible = false
	root_indicator.modulate = Color("#2e2e2e")
	root_indicator.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	root_indicator.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_root_indicator = root_indicator
	titlebar.add_child(close_button)
	titlebar.add_child(root_indicator)
	titlebar.move_child(root_indicator, 0)


## Configure the editor node for a given graph node.
func configure_for_node(g, n):
	graph = g
	node_resource = n
	position_offset = n.offset


## Persist changes from the editor node's controls into the graph node's properties
func persist_changes_to_node():
	_logger.debug("Persisting changes to node")
	node_resource.offset = position_offset


## Clear the relationships of the underlying graph node.
func clear_node_relationships():
	node_resource.next = -1


## Set the node to be the "root" or entry point of the graph.
func set_root(value: bool):
	is_root = value
	_root_indicator.visible = is_root


func _on_gui_input(ev):
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			accept_event()
			popup_request.emit(
				(get_screen_transform() * ev.position)
			)


func _close_button_pressed():
	delete_request.emit()

@tool
extends GraphNode

const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

const CLOSE_ICON = preload("res://addons/hyh.cutscene_graph/icons/icon_close.svg")

const GraphNodeBase = preload("../../resources/graph/GraphNodeBase.gd")

const CONNECTOR_COLOUR = Color("#f2f2f2e1")

signal removing_slot(slot)
signal popup_request(p_position)
signal modified()

@export var is_root : bool : set = set_root
@export var node_resource: GraphNodeBase

var graph


func _ready():
	var titlebar = get_titlebar_hbox()
	var close_button = Button.new()
	close_button.text = ""
	close_button.icon = CLOSE_ICON
	close_button.flat = true
	close_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(_close_button_pressed)
	titlebar.add_child(close_button)


func configure_for_node(g, n):
	"""
	Configure the editor node for a given graph node.
	"""
	graph = g
	node_resource = n
	position_offset = n.offset


func persist_changes_to_node():
	"""
	Persist changes from the editor node's controls into the graph node's properties
	"""
	Logger.debug("Persisting changes to node")
	node_resource.offset = position_offset


func clear_node_relationships():
	"""
	Clear the relationships of the underlying graph node.
	"""
	node_resource.next = -1


func set_root(value: bool):
	#if value:
		#self.overlay = GraphNode.OVERLAY_POSITION
	#else:
		#self.overlay = GraphNode.OVERLAY_DISABLED
	is_root = value


func _on_gui_input(ev):
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			accept_event()
			emit_signal("popup_request", (get_screen_transform() * ev.position))


func _close_button_pressed():
	delete_request.emit()

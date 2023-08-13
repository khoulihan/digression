@tool
extends MarginContainer

#const BooleanNodeEditControl = preload("BooleanNodeEdit.gd")
const BooleanType = preload("../../resources/graph/branches/conditions/BooleanCondition.gd").BooleanType
const VariableType = preload("../../resources/graph/VariableSetNode.gd").VariableType
const VariableScope = preload("../../resources/graph/VariableSetNode.gd").VariableScope
const ComparisonType = preload("../../resources/graph/branches/conditions/comparisons/ComparisonBase.gd").ComparisonType
const Highlighting = preload("../../utility/Highlighting.gd")

const SINGLE_VALUE_COMPARISON_TYPES = [
	ComparisonType.EQUALS,
	ComparisonType.GREATER_THAN,
	ComparisonType.GREATER_THAN_OR_EQUALS,
	ComparisonType.LESS_THAN,
	ComparisonType.LESS_THAN_OR_EQUALS
]

# Condition resource types
const BooleanCondition = preload("../../resources/graph/branches/conditions/BooleanCondition.gd")
const ValueCondition = preload("../../resources/graph/branches/conditions/ValueCondition.gd")
const RangeComparison = preload("../../resources/graph/branches/conditions/comparisons/RangeComparison.gd")
const SetComparison = preload("../../resources/graph/branches/conditions/comparisons/SetComparison.gd")
const SingleValueComparison = preload("../../resources/graph/branches/conditions/comparisons/SingleValueComparison.gd")

const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

@onready var ConditionTree = get_node("VBoxContainer/EditBodySplit/TreePane/Tree")
@onready var AddNodeButton = get_node("VBoxContainer/EditBodySplit/TreePane/TreeButtons/AddNodeButton")
@onready var RemoveNodeButton = get_node("VBoxContainer/EditBodySplit/TreePane/TreeButtons/RemoveNodeButton")
@onready var SaveButton = get_node("VBoxContainer/ButtonsContainer/SaveButton")
@onready var SummaryLabel = get_node("VBoxContainer/SummaryContainer/SummaryLabel")

# Boolean edit controls
@onready var BooleanNodeEdit = get_node("VBoxContainer/EditBodySplit/EditPane/BooleanNodeEdit")
#@onready var BooleanTypeOption = get_node("VBoxContainer/EditBodySplit/EditPane/BooleanNodeEdit/OptionButton")

# Value edit controls
@onready var ValueNodeEdit = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit")
#@onready var VariableScopeOption = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/ValueNodeHeader/VariableScopeOption")
#@onready var VariableNameEdit = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/ValueNodeHeader/VariableNameContainer/VariableNameEdit")
#@onready var VariableNameValidationWarning = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/ValueNodeHeader/VariableNameContainer/VariableNameValidationWarning")
#@onready var VariableTypeOption = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/ValueNodeHeader/VariableTypeContainer/VariableTypeOption")
#@onready var VariableTypeValidationWarning = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/ValueNodeHeader/VariableTypeContainer/VariableTypeValidationWarning")
#@onready var ComparisonTypeOption = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/ValueNodeHeader/ComparisonTypeOption")

#@onready var SingleValueEdit = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/MarginContainer/SingleValueEdit")
#@onready var RangeEdit = get_node("VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/MarginContainer/RangeEdit")
#@onready var SetEdit = get_node("$VBoxContainer/EditBodySplit/EditPane/ValueNodeEdit/MarginContainer/SetEdit")


signal saved(condition)
signal cancelled()


var _dirty := false
# I think it would be best if this wasn't modified until save time
# But that means we need a different data structure to manipulate
var _condition_resource

var _edited_node

var _last_id = 0


func _get_next_id():
	_last_id += 1
	return _last_id


enum ConditionNodeType {
	BOOLEAN,
	VALUE
}


class ConditionNodeMetaBase:
	func get_display_text():
		return ""


class BooleanConditionMetaNode:
	extends ConditionNodeMetaBase
	
	var boolean_type: BooleanType
	
	func get_display_text():
		match boolean_type:
			BooleanType.BOOLEAN_AND:
				return "And"
			BooleanType.BOOLEAN_OR:
				return "Or"


class ValueConditionMetaNode:
	extends ConditionNodeMetaBase
	
	var variable_name: String
	var scope: VariableScope
	var variable_type: VariableType
	var comparison_type: ComparisonType
	# Could make make these a single child object, like the resources
	var value
	var min_value
	var max_value
	var value_set
	
	func _variable_display_name():
		if variable_name == "":
			return "<unset>"
		return variable_name
	
	func _comparison_symbol():
		match comparison_type:
			ComparisonType.EQUALS:
				return "=="
			ComparisonType.GREATER_THAN:
				return ">"
			ComparisonType.GREATER_THAN_OR_EQUALS:
				return ">="
			ComparisonType.LESS_THAN:
				return "<"
			ComparisonType.LESS_THAN_OR_EQUALS:
				return "<="
	
	func _value_display(val):
		if val == null:
			return "<unset>"
		if variable_type == VariableType.TYPE_STRING:
			return "\"%s\"" % val
		return "%s" % val
	
	func get_display_text():
		if variable_type == -1:
			return "%s" % _variable_display_name()
		if comparison_type == ComparisonType.SET:
			# TODO: Display at least some of the values I guess
			return "%s in [...]" % _variable_display_name()
		if comparison_type == ComparisonType.RANGE:
			return "%s >= %s <= %s" % [
				_variable_display_name(),
				_value_display(min_value),
				_value_display(max_value)
			]
		if variable_type == VariableType.TYPE_BOOL:
			if value:
				return "%s" % _variable_display_name()
			else:
				return "not %s" % _variable_display_name()
		return "%s %s %s" % [
			_variable_display_name(),
			_comparison_symbol(),
			_value_display(value)
		]
	
	func get_highlighted_display_text():
		if variable_type == -1 or variable_name == null or variable_name.is_empty():
			return "[color=red]%s[/color]" % _variable_display_name()
		if comparison_type == ComparisonType.SET:
			# TODO: Display at least some of the values I guess
			return "[color=%s]%s[/color] [color=%s]in[/color] [color=%s][...][/color]" % [
				Highlighting.TEXT_COLOUR,
				_variable_display_name(),
				Highlighting.KEYWORD_COLOUR,
				Highlighting.SYMBOL_COLOUR
			]
		if comparison_type == ComparisonType.RANGE:
			return "%s%s [color=%s]>=[/color] %s %s %s [color=%s]<=[/color] %s%s" % [
				Highlighting.highlight("(", Highlighting.SYMBOL_COLOUR),
				Highlighting.highlight(_variable_display_name(), Highlighting.TEXT_COLOUR),
				Highlighting.SYMBOL_COLOUR,
				Highlighting.highlight(
					_value_display(min_value),
					Highlighting.get_colour_for_variable_type(variable_type)
				),
				Highlighting.highlight(
					"and",
					Highlighting.KEYWORD_COLOUR
				),
				Highlighting.highlight(_variable_display_name(), Highlighting.TEXT_COLOUR),
				Highlighting.SYMBOL_COLOUR,
				Highlighting.highlight(
					_value_display(max_value),
					Highlighting.get_colour_for_variable_type(variable_type)
				),
				Highlighting.highlight(")", Highlighting.SYMBOL_COLOUR)
			]
		if variable_type == VariableType.TYPE_BOOL:
			if value:
				return "[color=%s]%s[/color]" % [
					Highlighting.TEXT_COLOUR,
					_variable_display_name()
				]
			else:
				return "[color=%s]not[/color] [color=%s]%s[/color]" % [
					Highlighting.KEYWORD_COLOUR,
					Highlighting.TEXT_COLOUR,
					_variable_display_name()
				]
		return "[color=%s]%s[/color] [color=%s]%s[/color] [color=%s]%s[/color]" % [
			Highlighting.TEXT_COLOUR,
			_variable_display_name(),
			Highlighting.SYMBOL_COLOUR,
			_comparison_symbol(),
			Highlighting.get_colour_for_variable_type(variable_type),
			_value_display(value)
		]


func _ready():
	var add_node_menu = AddNodeButton.get_popup()
	add_node_menu.id_pressed.connect(_on_add_node_menu_item_pressed)


# TODO: Actually make use of this!
func _set_dirty(d = true):
	_dirty = d
	# TODO: Set save button state
	#SaveButton.


## Configure the window to edit an existing condition
## or create a new one.
func configure(condition = null):
	_condition_resource = condition
	if _condition_resource == null:
		_prepare_for_new()
	else:
		_prepare_for_existing(_condition_resource)
	_refresh_summary_label()


func _prepare_for_new():
	Logger.debug("Preparing conditions dialog for new")
	var root = (ConditionTree as Tree).create_item()
	root.set_meta("node_type", ConditionNodeType.BOOLEAN)
	root.set_meta("resource_id", null)
	#root.set_meta("boolean_type", BooleanType.BOOLEAN_AND)
	var root_meta = BooleanConditionMetaNode.new()
	root_meta.boolean_type = BooleanType.BOOLEAN_AND
	root.set_text(0, "%s" % root_meta.get_display_text())
	root.set_meta("condition", root_meta)
	(ConditionTree as Tree).set_selected(root, 0)
	_edit_node(root)


func _prepare_for_existing(condition):
	Logger.debug("Preparing conditions dialog for existing")
	var root = _create_nodes_from_resources(ConditionTree, condition)
	#var root_condition = condition as BooleanCondition
	#var root = _create_item_for_condition(ConditionTree, root_condition)
	#for child in root_condition.children:
	ConditionTree.set_selected(root, 0)
	_edit_node(root)


func _create_nodes_from_resources(parent_item, condition):
	var node = _create_item_for_condition(parent_item, condition)
	if condition is BooleanCondition:
		for child in condition.children:
			_create_nodes_from_resources(node, child)
	return node


func _create_item_for_condition(parent_item, condition):
	var item
	if "create_child" in parent_item:
		item = parent_item.create_child()
	else:
		item = parent_item.create_item()
	
	var id = _get_next_id()
	item.set_meta("resource_id", id)
	condition.set_meta("resource_id", id)
	
	var item_meta
	if condition is BooleanCondition:
		Logger.debug("Creating boolean condition item")
		item.set_meta("node_type", ConditionNodeType.BOOLEAN)
		item_meta = BooleanConditionMetaNode.new()
		item_meta.boolean_type = condition.operator
	elif condition is ValueCondition:
		Logger.debug("Creating value condition item")
		item.set_meta("node_type", ConditionNodeType.VALUE)
		item_meta = ValueConditionMetaNode.new()
		item_meta.variable_name = condition.variable
		item_meta.variable_type = condition.variable_type
		item_meta.scope = condition.scope
		_set_meta_comparison(item_meta, condition.comparison)
	else:
		Logger.error("Unrecognised condition type!")
		
	item.set_text(0, "%s" % item_meta.get_display_text())
	item.set_meta("condition", item_meta)
		
	return item


func _set_meta_comparison(item_meta, comparison):
	item_meta.comparison_type = comparison.comparison_type
	match comparison.comparison_type:
		ComparisonType.RANGE:
			item_meta.min_value = comparison.min_value
			item_meta.max_value = comparison.max_value
		ComparisonType.SET:
			pass
		_:
			item_meta.value = comparison.value


func _edit_node(node):
	_edited_node = node
	
	if node == null:
		Logger.debug("Editing null node")
		_set_edit_panel_visibility(null)
		_set_tree_button_states()
		return
	
	var node_type = node.get_meta("node_type")
	var condition = node.get_meta("condition")
	
	match node.get_meta("node_type"):
		ConditionNodeType.BOOLEAN:
			Logger.debug("Editing boolean node")
			BooleanNodeEdit.boolean_type = condition.boolean_type
		ConditionNodeType.VALUE:
			Logger.debug("Editing value node")
			Logger.debug("Condition value: %s" % condition.value)
			ValueNodeEdit.edit_value(
				condition.variable_name,
				condition.variable_type,
				condition.scope,
				condition.comparison_type,
				condition.value,
				condition.min_value,
				condition.max_value,
				condition.value_set
			)
	
	_set_edit_panel_visibility(node_type)
	_set_tree_button_states()


func _set_edit_panel_visibility(node_type):
	if node_type == null:
		BooleanNodeEdit.visible = false
		ValueNodeEdit.visible = false
	match node_type:
		ConditionNodeType.BOOLEAN:
			BooleanNodeEdit.visible = true
			ValueNodeEdit.visible = false
		ConditionNodeType.VALUE:
			BooleanNodeEdit.visible = false
			ValueNodeEdit.visible = true


func _set_tree_button_states():
	if _edited_node == null:
		RemoveNodeButton.disabled = true
		AddNodeButton.disabled = true
		return
	var node_type = _edited_node.get_meta("node_type")
	var is_root = _edited_node.get_parent() == null
	RemoveNodeButton.disabled = is_root
	AddNodeButton.disabled = node_type != ConditionNodeType.BOOLEAN


# TODO: Add a section to the window where the condition tree is displayed
# as syntax-highlighted code, like it will be in the nodes.
func _refresh_summary_label():
	var root = ConditionTree.get_root()
	var summary = "[color=%s]if[/color] %s" % [
		Highlighting.CONTROL_FLOW_COLOUR,
		_get_summary_for_node(root)
	]
	SummaryLabel.text = summary


func _get_summary_for_node(node: TreeItem) -> String:
	var node_type = node.get_meta("node_type")
	match node_type:
		ConditionNodeType.BOOLEAN:
			return _get_summary_for_boolean_node(node)
		ConditionNodeType.VALUE:
			var condition = node.get_meta("condition")
			return _get_summary_for_value_condition(condition)
	return ""
	

func _get_summary_for_boolean_node(node: TreeItem) -> String:
	var components = []
	var condition = node.get_meta("condition")
	var child_items = node.get_children()
	for child in child_items:
		var child_node_type = child.get_meta("node_type")
		if child_node_type == ConditionNodeType.BOOLEAN:
			components.append(
				"%s%s%s" % [
					Highlighting.highlight("(", Highlighting.SYMBOL_COLOUR),
					_get_summary_for_node(child),
					Highlighting.highlight(")", Highlighting.SYMBOL_COLOUR)
				]
			)
		else:
			components.append(_get_summary_for_node(child))
	if condition.boolean_type == BooleanType.BOOLEAN_AND:
		return Highlighting.highlight(
			" and ",
			Highlighting.KEYWORD_COLOUR
		).join(components)
	return Highlighting.highlight(
			" or ",
			Highlighting.KEYWORD_COLOUR
		).join(components)


func _get_summary_for_value_condition(condition) -> String:
	return condition.get_highlighted_display_text()


func _validate():
	# TODO: This function needs to validate aspects of the nodes that cannot
	# be determined by the ValueNodeEdit and BooleanNodeEdit controls
	# Are there empty boolean nodes? That's a paddlin'
	# Are there mutually exclusive children of an And?
	# Are there duplicate or redundant children of a boolean?
	pass


func get_condition():
	return _condition_resource


func _on_cancel_button_pressed():
	Logger.debug("Cancel button pressed")
	# TODO: Confirm
	cancelled.emit()


func _on_save_button_pressed():
	Logger.debug("Save button pressed")
	# TODO: Validate, create/return a resource
	saved.emit(
		_create_or_update_resource()
	)


func _create_or_update_resource():
	var root_resource = _condition_resource
	if root_resource == null:
		# Root is always a boolean
		root_resource = BooleanCondition.new()
	var root_node = ConditionTree.get_root()
	var res = _configure_resource_for_node(root_resource, root_node)
	_clear_resource_metadata(res)
	return res
	

func _clear_resource_metadata(res):
	res.set_meta("resource_id", null)
	if "children" in res:
		for child in res.children:
			_clear_resource_metadata(child)


func _create_resource_for_node(node):
	var node_type = node.get_meta("node_type")
	var resource
	match node_type:
		ConditionNodeType.BOOLEAN:
			resource = BooleanCondition.new()
		ConditionNodeType.VALUE:
			resource = ValueCondition.new()
	return _configure_resource_for_node(resource, node)
	

# TODO: This function could be split into several
func _configure_resource_for_node(res, node):
	Logger.debug("Configuring resource for node")
	var node_type = node.get_meta("node_type")
	var condition = node.get_meta("condition")
	if node_type == ConditionNodeType.VALUE:
		Logger.debug("Value node %s" % condition.variable_name)
		res.scope = condition.scope
		res.variable_type = condition.variable_type
		res.variable = condition.variable_name
		var comparison_type_matches = res.comparison != null and (
			res.comparison.comparison_type == condition.comparison_type or (
				res.comparison.comparison_type in SINGLE_VALUE_COMPARISON_TYPES and (
					condition.comparison_type in SINGLE_VALUE_COMPARISON_TYPES
				)
			)
		)
		match condition.comparison_type:
			ComparisonType.RANGE:
				if not comparison_type_matches:
					res.comparison = RangeComparison.new()
				res.comparison.comparison_type = condition.comparison_type
				res.comparison.min_value = condition.min_value
				res.comparison.max_value = condition.max_value
			ComparisonType.SET:
				pass
			_:
				if not comparison_type_matches:
					res.comparison = SingleValueComparison.new()
				res.comparison.comparison_type = condition.comparison_type
				res.comparison.value = condition.value
					
	elif node_type == ConditionNodeType.BOOLEAN:
		Logger.debug("Boolean node %s" % condition.boolean_type)
		res.operator = condition.boolean_type
		if res.children == null:
			res.children = []
		
		# Find any existing resources that have been removed
		var removed = []
		for child in res.children:
			var existing_rid = _get_meta_or_null(child, "resource_id")
			if existing_rid == null:
				continue
			#Logger.debug(str(child.get("id")))
			#Logger.debug(str(child.get("_id")))
			#Logger.debug(str(child.get_meta("_id")))
			Logger.debug("Checking for existing RID %s" % str(existing_rid))
			var found = false
			for node_child in node.get_children():
				Logger.debug("Checking RID %s" % str(_get_meta_or_null(node_child, "resource_id")))
				if _get_meta_or_null(node_child, "resource_id") == existing_rid:
					Logger.debug("Existing resource node found")
					found = true
					break
			if not found:
				Logger.debug("Not found, removing")
				removed.append(child)
		for child in removed:
			res.children.remove_at(
				res.children.find(child)
			)
		
		# Update existing children or create as necessary
		for child in node.get_children():
			var existing_resource
			for res_child in res.children:
				var existing_rid = _get_meta_or_null(res_child, "resource_id")
				if existing_rid == null:
					continue
				if _get_meta_or_null(child, "resource_id") == existing_rid:
					existing_resource = res_child
					break
			if existing_resource == null:
				res.children.append(
					_create_resource_for_node(child)
				)
			else:
				_configure_resource_for_node(existing_resource, child)
	
	return res


func _get_meta_or_null(obj, key):
	if obj.has_meta(key):
		return obj.get_meta(key)
	return null


func _on_tree_item_selected():
	Logger.debug("Tree item selected")
	_edit_node((ConditionTree as Tree).get_selected())


func _on_tree_nothing_selected():
	Logger.debug("Nothing selected")
	_edit_node(null)
	# Required because actually the last selected node
	# still appears to be selected. This is still the case
	# with the root node.
	(ConditionTree as Tree).deselect_all()
	#var still_selected = ConditionTree.get_selected()
	#if still_selected != null:
	#	Logger.debug("Something still selected!")
	#	ConditionTree.set_selected(still_selected, 0)


func _on_boolean_node_edit_boolean_type_selected(boolean_type):
	var condition = _edited_node.get_meta("condition")
	condition.boolean_type = boolean_type
	_edited_node.set_text(0, condition.get_display_text())
	_refresh_summary_label()


func _on_value_node_edit_value_modified(
	variable_name,
	variable_type,
	scope,
	comparison_type,
	value,
	min_value,
	max_value,
	value_set,
	is_valid,
	validation_text
):
	var condition = _edited_node.get_meta("condition")
	if variable_name != null:
		condition.variable_name = variable_name
		condition.variable_type = variable_type
		condition.scope = scope
		condition.comparison_type = comparison_type
		condition.value = value
		condition.min_value = min_value
		condition.max_value = max_value
		condition.value_set = value_set
	else:
		condition.variable_name = ""
		condition.variable_type = VariableType.TYPE_BOOL
		condition.scope = VariableScope.SCOPE_DIALOGUE
		condition.value = null
		condition.min_value = null
		condition.max_value = null
		condition.value_set = null
	_edited_node.set_text(0, condition.get_display_text())
	_refresh_summary_label()


func _on_add_node_menu_item_pressed(id):
	var child = _edited_node.create_child()
	if id == ConditionNodeType.BOOLEAN:
		child.set_meta("node_type", ConditionNodeType.BOOLEAN)
		child.set_meta("resource_id", null)
		var child_meta = BooleanConditionMetaNode.new()
		child_meta.boolean_type = BooleanType.BOOLEAN_AND
		child.set_text(0, "%s" % child_meta.get_display_text())
		child.set_meta("condition", child_meta)
	else:
		child.set_meta("node_type", ConditionNodeType.VALUE)
		child.set_meta("resource_id", null)
		var child_meta = ValueConditionMetaNode.new()
		child_meta.scope = VariableScope.SCOPE_DIALOGUE
		child_meta.variable_type = -1
		child.set_text(0, "%s" % child_meta.get_display_text())
		child.set_meta("condition", child_meta)
	(ConditionTree as Tree).set_selected(child, 0)
	_edit_node(child)
	# TODO: Summary will have to be re-evaluated as a result of this.
	# Also, validation.
	_refresh_summary_label()


func _on_remove_node_button_pressed():
	# TODO: This should be confirmed, especially if the node has children.
	_edited_node.free()
	_refresh_summary_label()
	_edit_node(null)

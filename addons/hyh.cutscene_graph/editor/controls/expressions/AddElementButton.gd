@tool
extends MenuButton


const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const FunctionType = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/ExpressionEnums.gd").FunctionType
const ExpressionType = preload("res://addons/hyh.cutscene_graph/editor/controls/expressions/ExpressionEnums.gd").ExpressionType


signal add_requested(
	variable_type: VariableType,
	expression_type: ExpressionType,
	function_type: Variant,
	comparison_type: Variant
)


enum ExpressionMenuId {
	VALUE,
	BRACKETS,
	COMPARISON,
	COMPARISON_BOOL,
	COMPARISON_INT,
	COMPARISON_FLOAT,
	COMPARISON_STRING,
	FUNCTION,
	BOOL_NOT,
	BOOL_STRING_CONTAINS,
	INT_MAX,
	INT_MIN,
	FLOAT_MAX,
	FLOAT_MIN,
	STRING_TO_LOWER,
}


var _type : VariableType


func configure(t: VariableType):
	_type = t
	var menu = get_popup()
	menu.clear()
	menu.add_item("Value", ExpressionMenuId.VALUE)
	menu.add_item("Brackets", ExpressionMenuId.BRACKETS)
	if (t == VariableType.TYPE_BOOL):
		_add_comparisons_sub_menu(menu)
	_add_functions_sub_menu(menu, t)
	menu.id_pressed.connect(_menu_item_selected)


func _menu_item_selected(id: int):
	var expression_type = _expression_type_for_id(id)
	add_requested.emit(_type, expression_type, null, null)


func _function_menu_item_selected(id: int):
	var expression_type = _expression_type_for_id(id)
	var func_type = _function_type_for_id(id)
	add_requested.emit(_type, expression_type, func_type, null)


func _comparison_menu_item_selected(id: int):
	var expression_type = _expression_type_for_id(id)
	var comparison_type = _comparison_type_for_id(id)
	add_requested.emit(_type, expression_type, null, comparison_type)


func _expression_type_for_id(id: ExpressionMenuId) -> ExpressionType:
	match id:
		ExpressionMenuId.VALUE:
			return ExpressionType.VALUE
		ExpressionMenuId.BRACKETS:
			return ExpressionType.BRACKETS
		ExpressionMenuId.COMPARISON_BOOL, ExpressionMenuId.COMPARISON_FLOAT, ExpressionMenuId.COMPARISON_INT, ExpressionMenuId.COMPARISON_STRING:
			return ExpressionType.COMPARISON
	# All other Ids are functions
	return ExpressionType.FUNCTION


func _function_type_for_id(id: ExpressionMenuId) -> Variant:
	match id:
		ExpressionMenuId.BOOL_NOT:
			return FunctionType.NOT
		ExpressionMenuId.INT_MIN, ExpressionMenuId.FLOAT_MIN:
			return FunctionType.MIN
		ExpressionMenuId.INT_MAX, ExpressionMenuId.FLOAT_MAX:
			return FunctionType.MAX
		ExpressionMenuId.BOOL_STRING_CONTAINS:
			return FunctionType.CONTAINS
		ExpressionMenuId.STRING_TO_LOWER:
			return FunctionType.TO_LOWER
	return null


func _comparison_type_for_id(id: ExpressionMenuId) -> Variant:
	match id:
		ExpressionMenuId.COMPARISON_BOOL:
			return VariableType.TYPE_BOOL
		ExpressionMenuId.COMPARISON_INT:
			return VariableType.TYPE_INT
		ExpressionMenuId.COMPARISON_FLOAT:
			return VariableType.TYPE_FLOAT
		ExpressionMenuId.COMPARISON_STRING:
			return VariableType.TYPE_STRING
	return null


func _add_functions_sub_menu(menu: PopupMenu, t: VariableType):
	var submenu = PopupMenu.new()
	submenu.set_name("function")
	submenu.id_pressed.connect(_function_menu_item_selected)
	
	match t:
		VariableType.TYPE_BOOL:
			_add_bool_functions(submenu)
		VariableType.TYPE_INT:
			_add_int_functions(submenu)
		VariableType.TYPE_FLOAT:
			_add_float_functions(submenu)
		VariableType.TYPE_STRING:
			_add_string_functions(submenu)
	
	menu.add_child(submenu)
	menu.add_submenu_item("Function", "function", ExpressionMenuId.FUNCTION)


func _add_function_item(
	menu: PopupMenu,
	item: ExpressionMenuId,
	name: String
):
	menu.add_item(name, item)


# TODO: Just implementing a few example functions for now


func _add_bool_functions(menu: PopupMenu):
	_add_function_item(menu, ExpressionMenuId.BOOL_NOT, "not")
	_add_function_item(menu, ExpressionMenuId.BOOL_STRING_CONTAINS, "contains")


func _add_int_functions(menu: PopupMenu):
	_add_function_item(menu, ExpressionMenuId.INT_MAX, "max")
	_add_function_item(menu, ExpressionMenuId.INT_MIN, "min")


func _add_float_functions(menu: PopupMenu):
	_add_function_item(menu, ExpressionMenuId.FLOAT_MAX, "max")
	_add_function_item(menu, ExpressionMenuId.FLOAT_MIN, "min")


func _add_string_functions(menu: PopupMenu):
	_add_function_item(menu, ExpressionMenuId.STRING_TO_LOWER, "to_lower")


func _add_comparisons_sub_menu(menu):
	var submenu = PopupMenu.new()
	submenu.set_name("comparison")
	submenu.id_pressed.connect(_comparison_menu_item_selected)
	
	submenu.add_item("Integer", ExpressionMenuId.COMPARISON_INT)
	submenu.add_item("Float", ExpressionMenuId.COMPARISON_FLOAT)
	submenu.add_item("String", ExpressionMenuId.COMPARISON_STRING)
	submenu.add_item("Boolean", ExpressionMenuId.COMPARISON_BOOL)
	
	menu.add_child(submenu)
	menu.add_submenu_item("Comparison", "comparison", ExpressionMenuId.COMPARISON)

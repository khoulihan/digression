@tool
extends MenuButton
## Button for adding an element to an expression.


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
	BOOL_IS_EQUAL_APPROX,
	BOOL_IS_FINITE,
	BOOL_IS_INFINITE,
	BOOL_IS_NAN,
	BOOL_IS_ZERO_APPROX,
	BOOL_NOT,
	BOOL_STRING_BEGINS_WITH,
	BOOL_STRING_ENDS_WITH,
	BOOL_STRING_CONTAINS,
	BOOL_STRING_CONTAINSN,
	BOOL_STRING_IS_EMPTY,
	BOOL_STRING_IS_SUBSEQUENCE_OF,
	BOOL_STRING_IS_SUBSEQUENCE_OFN,
	BOOL_STRING_MATCH,
	BOOL_STRING_MATCHN,
	INT_ABS,
	INT_CEIL,
	INT_CLAMP,
	INT_FLOOR,
	INT_MAX,
	INT_MIN,
	INT_MOD,
	INT_NEAREST_PO2,
	INT_RAND,
	INT_RAND_RANGE,
	INT_ROUND,
	INT_POSMOD,
	INT_SIGN,
	INT_SNAPPED,
	INT_WRAP,
	FLOAT_ABS,
	FLOAT_CEIL,
	FLOAT_CLAMP,
	FLOAT_FLOOR,
	FLOAT_MAX,
	FLOAT_MIN,
	FLOAT_MOD,
	FLOAT_PINGPONG,
	FLOAT_POSMOD,
	FLOAT_RAND,
	FLOAT_RAND_FN,
	FLOAT_RAND_RANGE,
	FLOAT_ROUND,
	FLOAT_SIGN,
	FLOAT_SNAPPED,
	FLOAT_WRAP,
	STRING_CAPITALIZE,
	STRING_CHR,
	STRING_FORMAT,
	STRING_JOIN,
	STRING_LEFT,
	STRING_LPAD,
	STRING_LSTRIP,
	STRING_MD5_TEXT,
	STRING_RIGHT,
	STRING_REPEAT,
	STRING_REPLACE,
	STRING_REPLACEN,
	STRING_REVERSE,
	STRING_RPAD,
	STRING_RSTRIP,
	STRING_SHA1_TEXT,
	STRING_SHA256_TEXT,
	STRING_TO_CAMEL_CASE,
	STRING_TO_LOWER,
	STRING_TO_PASCAL_CASE,
	STRING_TO_SNAKE_CASE,
	STRING_TO_UPPER,
	STRING_TRIM_PREFIX,
	STRING_TRIM_SUFFIX,
}

const VariableType = preload("../../../resources/graph/VariableSetNode.gd").VariableType
const FunctionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").FunctionType
const ExpressionType = preload("../../../resources/graph/expressions/ExpressionResource.gd").ExpressionType

var _type : VariableType


## Configure the button.
func configure(t: VariableType):
	_type = t
	var menu = get_popup()
	menu.clear()
	# Children need to be removed or the wrong submenus may show up
	for child in menu.get_children():
		menu.remove_child(child)
	menu.add_item("Value", ExpressionMenuId.VALUE)
	menu.add_item("Brackets", ExpressionMenuId.BRACKETS)
	if (t == VariableType.TYPE_BOOL):
		_add_comparisons_sub_menu(menu)
	_add_functions_sub_menu(menu, t)
	if not menu.id_pressed.is_connected(_on_menu_item_selected):
		menu.id_pressed.connect(_on_menu_item_selected)


func _on_menu_item_selected(id: int):
	var expression_type = _expression_type_for_id(id)
	add_requested.emit(_type, expression_type, null, null)


func _on_function_menu_item_selected(id: int):
	var expression_type = _expression_type_for_id(id)
	var func_type = _function_type_for_id(id)
	add_requested.emit(_type, expression_type, func_type, null)


func _on_comparison_menu_item_selected(id: int):
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
		ExpressionMenuId.BOOL_IS_EQUAL_APPROX:
			return FunctionType.IS_EQUAL_APPROX
		ExpressionMenuId.BOOL_IS_FINITE:
			return FunctionType.IS_FINITE
		ExpressionMenuId.BOOL_IS_INFINITE:
			return FunctionType.IS_INFINITE
		ExpressionMenuId.BOOL_IS_NAN:
			return FunctionType.IS_NAN
		ExpressionMenuId.BOOL_IS_ZERO_APPROX:
			return FunctionType.IS_ZERO_APPROX
		ExpressionMenuId.BOOL_NOT:
			return FunctionType.NOT
		ExpressionMenuId.BOOL_STRING_BEGINS_WITH:
			return FunctionType.BEGINS_WITH
		ExpressionMenuId.BOOL_STRING_ENDS_WITH:
			return FunctionType.ENDS_WITH
		ExpressionMenuId.BOOL_STRING_CONTAINS:
			return FunctionType.CONTAINS
		ExpressionMenuId.BOOL_STRING_CONTAINSN:
			return FunctionType.CONTAINSN
		ExpressionMenuId.BOOL_STRING_IS_EMPTY:
			return FunctionType.IS_EMPTY
		ExpressionMenuId.BOOL_STRING_IS_SUBSEQUENCE_OF:
			return FunctionType.IS_SUBSEQUENCE_OF
		ExpressionMenuId.BOOL_STRING_IS_SUBSEQUENCE_OFN:
			return FunctionType.IS_SUBSEQUENCE_OFN
		ExpressionMenuId.BOOL_STRING_MATCH:
			return FunctionType.MATCH
		ExpressionMenuId.BOOL_STRING_MATCHN:
			return FunctionType.MATCHN
		ExpressionMenuId.INT_ABS, ExpressionMenuId.FLOAT_ABS:
			return FunctionType.ABS
		ExpressionMenuId.INT_CEIL, ExpressionMenuId.FLOAT_CEIL:
			return FunctionType.CEIL
		ExpressionMenuId.INT_CLAMP, ExpressionMenuId.FLOAT_CLAMP:
			return FunctionType.CLAMP
		ExpressionMenuId.INT_FLOOR, ExpressionMenuId.FLOAT_FLOOR:
			return FunctionType.FLOOR
		ExpressionMenuId.INT_MIN, ExpressionMenuId.FLOAT_MIN:
			return FunctionType.MIN
		ExpressionMenuId.INT_MAX, ExpressionMenuId.FLOAT_MAX:
			return FunctionType.MAX
		ExpressionMenuId.INT_MOD, ExpressionMenuId.FLOAT_MOD:
			return FunctionType.MOD
		ExpressionMenuId.INT_NEAREST_PO2:
			return FunctionType.NEAREST_PO2
		ExpressionMenuId.FLOAT_PINGPONG:
			return FunctionType.PINGPONG
		ExpressionMenuId.INT_POSMOD, ExpressionMenuId.FLOAT_POSMOD:
			return FunctionType.POSMOD
		ExpressionMenuId.INT_RAND, ExpressionMenuId.FLOAT_RAND:
			return FunctionType.RAND
		ExpressionMenuId.FLOAT_RAND_FN:
			return FunctionType.RAND_FN
		ExpressionMenuId.INT_RAND_RANGE, ExpressionMenuId.FLOAT_RAND_RANGE:
			return FunctionType.RAND_RANGE
		ExpressionMenuId.INT_ROUND, ExpressionMenuId.FLOAT_ROUND:
			return FunctionType.ROUND
		ExpressionMenuId.INT_SIGN, ExpressionMenuId.FLOAT_SIGN:
			return FunctionType.SIGN
		ExpressionMenuId.INT_SNAPPED, ExpressionMenuId.FLOAT_SNAPPED:
			return FunctionType.SNAPPED
		ExpressionMenuId.INT_WRAP, ExpressionMenuId.FLOAT_WRAP:
			return FunctionType.WRAP
		ExpressionMenuId.STRING_CAPITALIZE:
			return FunctionType.CAPITALIZE
		ExpressionMenuId.STRING_CHR:
			return FunctionType.CHR
		ExpressionMenuId.STRING_FORMAT:
			return FunctionType.FORMAT
		ExpressionMenuId.STRING_JOIN:
			return FunctionType.JOIN
		ExpressionMenuId.STRING_LEFT:
			return FunctionType.LEFT
		ExpressionMenuId.STRING_LPAD:
			return FunctionType.LPAD
		ExpressionMenuId.STRING_LSTRIP:
			return FunctionType.LSTRIP
		ExpressionMenuId.STRING_MD5_TEXT:
			return FunctionType.MD5_TEXT
		ExpressionMenuId.STRING_REPEAT:
			return FunctionType.REPEAT
		ExpressionMenuId.STRING_REPLACE:
			return FunctionType.REPLACE
		ExpressionMenuId.STRING_REPLACEN:
			return FunctionType.REPLACEN
		ExpressionMenuId.STRING_REVERSE:
			return FunctionType.REVERSE
		ExpressionMenuId.STRING_RIGHT:
			return FunctionType.RIGHT
		ExpressionMenuId.STRING_RPAD:
			return FunctionType.RPAD
		ExpressionMenuId.STRING_RSTRIP:
			return FunctionType.RSTRIP
		ExpressionMenuId.STRING_SHA1_TEXT:
			return FunctionType.SHA1_TEXT
		ExpressionMenuId.STRING_SHA256_TEXT:
			return FunctionType.SHA256_TEXT
		ExpressionMenuId.STRING_TO_CAMEL_CASE:
			return FunctionType.TO_CAMEL_CASE
		ExpressionMenuId.STRING_TO_LOWER:
			return FunctionType.TO_LOWER
		ExpressionMenuId.STRING_TO_PASCAL_CASE:
			return FunctionType.TO_PASCAL_CASE
		ExpressionMenuId.STRING_TO_SNAKE_CASE:
			return FunctionType.TO_SNAKE_CASE
		ExpressionMenuId.STRING_TO_UPPER:
			return FunctionType.TO_UPPER
		ExpressionMenuId.STRING_TRIM_PREFIX:
			return FunctionType.TRIM_PREFIX
		ExpressionMenuId.STRING_TRIM_SUFFIX:
			return FunctionType.TRIM_SUFFIX
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


func _add_comparisons_sub_menu(menu):
	var submenu = PopupMenu.new()
	submenu.set_name("comparison")
	submenu.id_pressed.connect(_on_comparison_menu_item_selected)
	
	submenu.add_item("Integer", ExpressionMenuId.COMPARISON_INT)
	submenu.add_item("Float", ExpressionMenuId.COMPARISON_FLOAT)
	submenu.add_item("String", ExpressionMenuId.COMPARISON_STRING)
	submenu.add_item("Boolean", ExpressionMenuId.COMPARISON_BOOL)
	
	menu.add_child(submenu)
	menu.add_submenu_item("Comparison", "comparison", ExpressionMenuId.COMPARISON)


func _add_functions_sub_menu(menu: PopupMenu, t: VariableType):
	var submenu = PopupMenu.new()
	submenu.set_name("function")
	submenu.id_pressed.connect(_on_function_menu_item_selected)
	
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
	_add_function_item(menu, ExpressionMenuId.BOOL_IS_EQUAL_APPROX, "is_equal_approx")
	_add_function_item(menu, ExpressionMenuId.BOOL_IS_FINITE, "is_finite")
	_add_function_item(menu, ExpressionMenuId.BOOL_IS_INFINITE, "is_inf")
	_add_function_item(menu, ExpressionMenuId.BOOL_IS_NAN, "is_nan")
	_add_function_item(menu, ExpressionMenuId.BOOL_IS_ZERO_APPROX, "is_zero_approx")
	_add_function_item(menu, ExpressionMenuId.BOOL_NOT, "not")
	_add_function_item(menu, ExpressionMenuId.BOOL_STRING_BEGINS_WITH, "String.begins_with")
	_add_function_item(menu, ExpressionMenuId.BOOL_STRING_CONTAINS, "String.contains")
	_add_function_item(menu, ExpressionMenuId.BOOL_STRING_CONTAINSN, "String.containsn")
	_add_function_item(menu, ExpressionMenuId.BOOL_STRING_ENDS_WITH, "String.ends_with")
	_add_function_item(menu, ExpressionMenuId.BOOL_STRING_IS_EMPTY, "String.is_empty")
	_add_function_item(
		menu,
		ExpressionMenuId.BOOL_STRING_IS_SUBSEQUENCE_OF,
		"String.is_subsequence_of"
	)
	_add_function_item(
		menu,
		ExpressionMenuId.BOOL_STRING_IS_SUBSEQUENCE_OFN,
		"String.is_subsequence_ofn"
	)
	_add_function_item(menu, ExpressionMenuId.BOOL_STRING_MATCH, "String.match")
	_add_function_item(menu, ExpressionMenuId.BOOL_STRING_MATCHN, "String.matchn")


func _add_int_functions(menu: PopupMenu):
	_add_function_item(menu, ExpressionMenuId.INT_ABS, "abs")
	_add_function_item(menu, ExpressionMenuId.INT_CEIL, "ceil")
	_add_function_item(menu, ExpressionMenuId.INT_CLAMP, "clamp")
	_add_function_item(menu, ExpressionMenuId.INT_FLOOR, "floor")
	_add_function_item(menu, ExpressionMenuId.INT_MAX, "max")
	_add_function_item(menu, ExpressionMenuId.INT_MIN, "min")
	_add_function_item(menu, ExpressionMenuId.INT_MOD, "mod")
	_add_function_item(menu, ExpressionMenuId.INT_NEAREST_PO2, "nearest_po2")
	_add_function_item(menu, ExpressionMenuId.INT_POSMOD, "posmod")
	_add_function_item(menu, ExpressionMenuId.INT_RAND, "rand")
	_add_function_item(menu, ExpressionMenuId.INT_RAND_RANGE, "rand_range")
	_add_function_item(menu, ExpressionMenuId.INT_ROUND, "round")
	_add_function_item(menu, ExpressionMenuId.INT_SIGN, "sign")
	_add_function_item(menu, ExpressionMenuId.INT_SNAPPED, "snapped")
	_add_function_item(menu, ExpressionMenuId.INT_WRAP, "wrap")


func _add_float_functions(menu: PopupMenu):
	_add_function_item(menu, ExpressionMenuId.FLOAT_ABS, "abs")
	_add_function_item(menu, ExpressionMenuId.FLOAT_CEIL, "ceil")
	_add_function_item(menu, ExpressionMenuId.FLOAT_CLAMP, "clamp")
	_add_function_item(menu, ExpressionMenuId.FLOAT_FLOOR, "floor")
	_add_function_item(menu, ExpressionMenuId.FLOAT_MAX, "max")
	_add_function_item(menu, ExpressionMenuId.FLOAT_MIN, "min")
	_add_function_item(menu, ExpressionMenuId.FLOAT_MOD, "mod")
	_add_function_item(menu, ExpressionMenuId.FLOAT_PINGPONG, "pingpong")
	_add_function_item(menu, ExpressionMenuId.FLOAT_POSMOD, "posmod")
	_add_function_item(menu, ExpressionMenuId.FLOAT_RAND, "rand")
	_add_function_item(menu, ExpressionMenuId.FLOAT_RAND_FN, "randfn")
	_add_function_item(menu, ExpressionMenuId.FLOAT_RAND_RANGE, "rand_range")
	_add_function_item(menu, ExpressionMenuId.FLOAT_ROUND, "round")
	_add_function_item(menu, ExpressionMenuId.FLOAT_SIGN, "sign")
	_add_function_item(menu, ExpressionMenuId.FLOAT_SNAPPED, "snapped")
	_add_function_item(menu, ExpressionMenuId.FLOAT_WRAP, "wrap")


func _add_string_functions(menu: PopupMenu):
	_add_function_item(menu, ExpressionMenuId.STRING_CAPITALIZE, "String.capitalize")
	_add_function_item(menu, ExpressionMenuId.STRING_CHR, "String.chr")
	_add_function_item(menu, ExpressionMenuId.STRING_FORMAT, "String.format")
	_add_function_item(menu, ExpressionMenuId.STRING_JOIN, "String.join")
	_add_function_item(menu, ExpressionMenuId.STRING_LEFT, "String.left")
	_add_function_item(menu, ExpressionMenuId.STRING_LPAD, "String.lpad")
	_add_function_item(menu, ExpressionMenuId.STRING_LSTRIP, "String.lstrip")
	_add_function_item(menu, ExpressionMenuId.STRING_MD5_TEXT, "String.md5_text")
	_add_function_item(menu, ExpressionMenuId.STRING_REPEAT, "String.repeat")
	_add_function_item(menu, ExpressionMenuId.STRING_REPLACE, "String.replace")
	_add_function_item(menu, ExpressionMenuId.STRING_REPLACEN, "String.replacen")
	_add_function_item(menu, ExpressionMenuId.STRING_REVERSE, "String.reverse")
	_add_function_item(menu, ExpressionMenuId.STRING_RIGHT, "String.right")
	_add_function_item(menu, ExpressionMenuId.STRING_RPAD, "String.rpad")
	_add_function_item(menu, ExpressionMenuId.STRING_RSTRIP, "String.rstrip")
	_add_function_item(menu, ExpressionMenuId.STRING_SHA1_TEXT, "String.sha1_text")
	_add_function_item(menu, ExpressionMenuId.STRING_SHA256_TEXT, "String.sha256_text")
	_add_function_item(menu, ExpressionMenuId.STRING_TO_CAMEL_CASE, "String.to_camel_case")
	_add_function_item(menu, ExpressionMenuId.STRING_TO_LOWER, "String.to_lower")
	_add_function_item(menu, ExpressionMenuId.STRING_TO_PASCAL_CASE, "String.to_pascal_case")
	_add_function_item(menu, ExpressionMenuId.STRING_TO_SNAKE_CASE, "String.to_snake_case")
	_add_function_item(menu, ExpressionMenuId.STRING_TO_UPPER, "String.to_upper")
	_add_function_item(menu, ExpressionMenuId.STRING_TRIM_PREFIX, "String.trim_prefix")
	_add_function_item(menu, ExpressionMenuId.STRING_TRIM_SUFFIX, "String.trim_suffix")
